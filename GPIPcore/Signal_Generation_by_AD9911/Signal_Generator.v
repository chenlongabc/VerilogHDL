/*

requset: 
    FREQW
    FREQW_UPDATE
    CODE
    CODE_LEN
    PULSE_LEN
    
ouput:
    FREQW_UPDATE_OVER
    GEN_OVER


*/

/*
*                                               ┌──┐                                                                                ┌──┐  
*    input                                      │  │                                                                                │  │  
*    FREQW_UPDATE          ─────────────────────┘  └────────────────────────────────────────────────────────────────────────────────┘  └──
*
*
*                          ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
*    input                 │                  FREQW                                                                                      │
*    FREQW                 └─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
*
*                          ────────────────────────┐                          ┌────────────────────────────────────────────────────────┐ 
*    output                                        │     updating             │ keep high level until FREQW_UPDATE pulse arrives again │  
*    FREQW_UPDATE_OVER                             └──────────────────────────┘                                                        └──
*
*
*******************************************************************************************************************************************
*
*                                  ┌─┐                                                                                       ┌─┐   
*    input                         │ │                                                                                       │ │   
*    GEN        ───────────────────┘ └───────────────────────────────────────────────────────────────────────────────────────┘ └──────────
*
*                                    ┌───────┐                                                                                 ┌───────┐               
*    output                          │       │                                                                                 │       │               
*    MA         ─────────────────────┘       └─────────────────────────────────────────────────────────────────────────────────┘       └──
*
*                                    ┌─┬─┬───┐                                                                                 ┌─┬─┬───┐               
*    output                          │0│1│...│                                                                                 │0│1│...│               
*    MP         ─────────────────────┴─┴─┴───┴─────────────────────────────────────────────────────────────────────────────────┴─┴─┴───┴──
*
*               ─────────────────────┐                                        ┌────────────────────────────────────────────────┐                                    
*    output                          │        keep low until gen over         │ keep high level until GEN pulse arrives again  │                                   
*    GEN_OVER                        └────────────────────────────────────────┘                                                └──────────
*/

module Signal_Generator(
    input     wire              CLOCK_10M,
    input     wire              RESET_N,

    input     wire              RF_OUTPUT_EN,
    input     wire              GEN,
    input     wire   [31:0]     CODE,
    input     wire   [15:0]     CODE_LEN,
    input     wire   [15:0]     CODE_DURATION,
    input     wire   [15:0]     PULSE_LEN,

    input     wire              INITI, 
    output    wire              INITIED, 
    input     wire   [31:0]     FREQW,
    input     wire              UPDATE, 
    output    wire              UPDATED, 

    output    reg               SIGNAL_GEN_OVER,

    output    wire              LO_CS,  
    output    wire              LO_PD,  
    output    wire              LO_UPDATE,
    output    wire              LO_MRSET,
    output    wire              LO_SCLK,
    output    wire   [ 3:0]     LO_SDIO,
    output    wire   [ 3:0]     LO_P,

    output    wire              RF_CS,  
    output    wire              RF_PD,  
    output    wire              RF_UPDATE,
    output    wire              RF_MRSET,
    output    wire              RF_SCLK,
    output    wire   [ 3:0]     RF_SDIO,
    output    wire   [ 3:0]     RF_P
    );
    
    reg    MA = 0;
    reg    MP = 0;


    assign LO_PD = 0;
    assign RF_PD = 0;
    
    assign RF_P[1] = MP;
    assign RF_P[3] = RF_OUTPUT_EN & MA;

    assign LO_P[1] = 0;
    assign LO_P[3] = 1;


/*
*
*
*       <------------------------------------ PULSE_LEN --------------------------------------->
*       <-------- CODE_LEN ---------><---------------------- BLANK_LEN ------------------------>
*       ┌─────┬─────┬─────┬─────────┐                                                           ┌─────┬─────┬─────┬─────────┐
*       │  0  │  1  │ ... │ CODE[n] │                                                           │  0  │  1  │ ... │ CODE[n] │
*   ────┴─────┴─────┴─────┴─────────┴───────────────────────────────────────────────────────────┴─────┴─────┴─────┴─────────┴─
*       <-- -->
*          | CODE_DURATION = 25.6us = 256T (10MHZ) = 1/FSR
*
*
*       PULSE_LEN  = CODE_LEN(16) + BLANK_LEN(320-16) = 320
*       PULSE_WIDE = PULSE_LEN(320) * CODE_DURATION(25.6us) = 8.192ms
*
*
*/
    reg   [15:0]    code_length;
    reg   [15:0]    code_duration;
    reg   [15:0]    pulse_lenght;
    reg   [31:0]    code;
    reg   [15:0]    i;
    reg   [15:0]    duration;
    
    reg   [ 7:0]    state;


    always @(posedge CLOCK_10M or negedge RESET_N) begin
        if (!RESET_N) begin
            SIGNAL_GEN_OVER <= 0;
            MA <= 0;
            MP <= 0;
            state <= 0;
        end else begin
            if (!GEN) begin
                SIGNAL_GEN_OVER <= 0;
                MA <= 0;
                MP <= 0;
                i <= 0;
                state <= 0;
            end else begin
                case (state)
                    0  :begin
                            code_length <= CODE_LEN;
                            code_duration <= CODE_DURATION;
                            pulse_lenght <= PULSE_LEN;
                            code <= CODE;
                            state <= 1;
                        end
                    1  :begin
                            if (i < code_length) begin
                                MP <= code[i];
                                MA <= 1;
                                state <= 2;
                            end else if (i < pulse_lenght) begin
                                MA <= 0;
                                state <= 2;
                            end else begin
                                MA <= 0;
                                state <= 3;
                            end
                            duration <= 2;
                        end
                    2  :begin
                            if (duration < code_duration) begin  //256 : duration 25.6us
                                duration <= duration+1;
                            end else begin
                                i <= i+1;
                                state <= 1;
                            end
                        end
                    3  :begin
                            SIGNAL_GEN_OVER <= 1;
                        end
                endcase
            end
        end
    end

    wire        LO_TR;
    wire [ 7:0] LO_ADDR;
    wire [31:0] LO_DATA;
    wire        LO_BUSY;

    wire        RF_TR;  
    wire [ 7:0] RF_ADDR;
    wire [31:0] RF_DATA;
    wire        RF_BUSY;


    Frequency_Updater #(.starting_freqw_LO(370440929), .starting_freqw_RF (0)) Updater
    (
        .CLOCK_10M     (CLOCK_10M),
        .RESET_N       (RESET_N),
        // .TR            (),
        // .ADDR          (),
        // .DATA          (),
        .INITI         (INITI),
        .INITIED       (INITIED),

        .FREQW         (FREQW),
        .UPDATE        (UPDATE),
        .UPDATED       (UPDATED),

        .LO_TR         (LO_TR),
        .LO_ADDR       (LO_ADDR),
        .LO_DATA       (LO_DATA),
        .LO_MRSET      (LO_MRSET),
        .LO_BUSY       (LO_BUSY),

        .RF_TR         (RF_TR),
        .RF_ADDR       (RF_ADDR),
        .RF_DATA       (RF_DATA),
        .RF_MRSET      (RF_MRSET),
        .RF_BUSY       (RF_BUSY)
    );
    
    SPI_AD9911 SPI_LO
    (
        .CLK         (CLOCK_10M),
        .RESET_N     (RESET_N),

        .TR          (LO_TR),
        .REG_ADDR    (LO_ADDR),
        .DATA_IN     (LO_DATA),
        .BUSY        (LO_BUSY),

        .AD_CS       (LO_CS),
        .AD_SCLK     (LO_SCLK),
        .AD_SDIO0    (LO_SDIO[0]),
        .AD_UPADTE   (LO_UPDATE)
    );

    SPI_AD9911 SPI_RF 
    (
        .CLK         (CLOCK_10M),
        .RESET_N     (RESET_N),

        .TR          (RF_TR),
        .REG_ADDR    (RF_ADDR),
        .DATA_IN     (RF_DATA),
        .BUSY        (RF_BUSY),

        .AD_CS       (RF_CS),
        .AD_SCLK     (RF_SCLK),
        .AD_SDIO0    (RF_SDIO[0]),
        .AD_UPADTE   (RF_UPDATE)
    );
	

endmodule










