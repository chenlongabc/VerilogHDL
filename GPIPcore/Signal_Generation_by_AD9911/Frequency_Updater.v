

module Frequency_Updater #(parameter starting_freqw_LO = 370440929, starting_freqw_RF = 0)(
    input     wire              CLOCK_10M,
    input     wire              RESET_N,

    // input     wire              TR,
    // input     wire   [ 7:0]     ADDR,
    // input     wire   [31:0]     DATA,

    input     wire              INITI,
    output    reg               INITIED,

    input     wire   [31:0]     FREQW,
    input     wire              UPDATE,
    output    reg               UPDATED,

    output    wire              LO_TR,
    output    wire   [ 7:0]     LO_ADDR,
    output    wire   [31:0]     LO_DATA,
    output    reg               LO_MRSET,
    input     wire              LO_BUSY,
    
    
    output    wire              RF_TR,
    output    wire   [ 7:0]     RF_ADDR,
    output    wire   [31:0]     RF_DATA,
    output    reg               RF_MRSET,
    input     wire              RF_BUSY
    );

    reg  [31:0]   REGS_LO[24:0];
    reg  [31:0]   REGS_RF[24:0];
    reg  [ 4:0]   i;
    reg  [ 7:0]   state1;
    reg  [ 7:0]   state2;


    reg           I_LO_TR;
    reg  [ 7:0]   I_LO_ADDR;
    reg  [31:0]   I_LO_DATA;
    reg           I_RF_TR;
    reg  [ 7:0]   I_RF_ADDR;
    reg  [31:0]   I_RF_DATA;

    reg           U_LO_TR;
    reg  [ 7:0]   U_LO_ADDR;
    reg  [31:0]   U_LO_DATA;
    reg           U_RF_TR;
    reg  [ 7:0]   U_RF_ADDR;
    reg  [31:0]   U_RF_DATA;


    assign LO_TR   = INITIED ? U_LO_TR   : I_LO_TR;
    assign LO_ADDR = INITIED ? U_LO_ADDR : I_LO_ADDR;
    assign LO_DATA = INITIED ? U_LO_DATA : I_LO_DATA;

    assign RF_TR   = INITIED ? U_RF_TR   : I_RF_TR;
    assign RF_ADDR = INITIED ? U_RF_ADDR : I_RF_ADDR;
    assign RF_DATA = INITIED ? U_RF_DATA : I_RF_DATA;

    initial begin
        REGS_LO[0] <= 32'b00000000_00000000_00000000_00100000; //CSR
        REGS_LO[1] <= 32'b00000000_10110011_00000100_00000000; //FR1
        REGS_LO[2] <= 0;                                       //FR2
        REGS_LO[3] <= 32'b00000000_11000000_00000011_00000000; //CFR
        REGS_LO[4] <= 8947849*2;                 //CTW0   536880000  8948   FREQW * 480M / 2^32 = Fout
        REGS_LO[5] <= 0;                                       //CPOW0
        REGS_LO[6] <= 32'b00000000_00000001_11011111_11111111; //ACR
        REGS_LO[7] <= 32'b00000000_00000000_00000000_00000000; //LSR
        REGS_LO[8] <= 32'b00000000_00000000_00000000_00000000; //RDW
        REGS_LO[9] <= 32'b00000000_00000000_00000000_00000000; //FDW
        REGS_LO[10]<= 32'b10000000_00000000_00000000_00000000; //CTW1

        REGS_RF[0] <= 32'b00000000_00000000_00000000_00100000; //CSR
        REGS_RF[1] <= 32'b00000000_10110011_00000100_00000000; //FR1
        REGS_RF[2] <= 0;                                       //FR2
        REGS_RF[3] <= 32'b00000000_11000000_00000011_00000000; //CFR
        REGS_RF[4] <= 8947849*2;                 //CTW0   536880000  8948   FREQW * 480M / 2^32 = Fout
        REGS_RF[5] <= 0;                                       //CPOW0
        REGS_RF[6] <= 32'b00000000_00000001_11011111_11111111; //ACR
        REGS_RF[7] <= 32'b00000000_00000000_00000000_00000000; //LSR
        REGS_RF[8] <= 32'b00000000_00000000_00000000_00000000; //RDW
        REGS_RF[9] <= 32'b00000000_00000000_00000000_00000000; //FDW
        REGS_RF[10]<= 32'b10000000_00000000_00000000_00000000; //CTW1
    end

    reg   [15:0]    delay;

    always @(posedge CLOCK_10M or negedge RESET_N) begin
        if (!RESET_N) begin
            i <= 0;
            I_LO_TR <= 0;
            I_RF_TR <= 0;
            LO_MRSET <= 1;
            RF_MRSET <= 1;
            INITIED <= 0;
            delay <= 0;
            state1 <= 255;
        end else begin
            if (!INITI) begin
                i <= 0;
                I_LO_TR <= 0;
                I_RF_TR <= 0;
                LO_MRSET <= 1;
                RF_MRSET <= 1;
                INITIED <= 0;
                delay <= 0;
                state1 <= 255;
            end else begin
                case (state1)
                    255:begin
                        LO_MRSET <= 0;
                        RF_MRSET <= 0;
                        delay <= delay+1;
                        if (delay>2048) begin // delay 204.8us for AD9911 being stable
                            state1 <= 0;
                        end
                    end
                    0  :begin
                            I_LO_TR <= 0;
                            I_RF_TR <= 0;
                            state1 <= 1;
                        end
                    1  :begin
                            if (i>=11) begin
                                state1 <= 5;
                            end else begin
                                state1 <= 2;
                            end
                        end
                    2  :begin
                            I_LO_ADDR <= i;
                            I_RF_ADDR <= i;
                            I_LO_DATA <= REGS_LO[i];
                            I_RF_DATA <= REGS_RF[i];
                            state1 <= 3;
                        end
                    3  :begin
                            if (!LO_BUSY && !RF_BUSY) begin
                                I_LO_TR <= 1;
                                I_RF_TR <= 1;
                                state1 <= 4;
                            end
                        end
                    4  :begin
                            i <= i+1;
                            state1 <= 0;
                        end
                    5  :begin
                            INITIED <= 1;
                        end
                    default: state1 <= 0;
                endcase
            end
        end
    end



    always @(posedge CLOCK_10M or negedge RESET_N) begin
        if (!RESET_N) begin
            U_LO_TR <= 0;
            U_RF_TR <= 0;
            UPDATED <= 0;
            state2 <= 0;
        end else begin
            if (!INITIED) begin
                U_LO_TR <= 0;
                U_RF_TR <= 0;  
                UPDATED <= 0;
                state2 <= 0;
            end else begin
                case (state2)
                    0  :begin
                            U_LO_TR <= 0;
                            U_RF_TR <= 0;
                            state2 <= 1;
                        end
                    1  :begin
                            if (UPDATE) begin
                                U_LO_ADDR <= 4; // address of ad9911 reg CTW0 
                                U_LO_DATA <= starting_freqw_LO + FREQW; // 41.4MHz : 370440929
                                U_RF_ADDR <= 4; // address of ad9911 reg CTW0 
                                U_RF_DATA <= starting_freqw_RF + FREQW; // 41.4MHz : 370440929
                                UPDATED <= 0;
                                state2 <= 2;
                            end
                        end
                    2  :begin
                            if (!LO_BUSY && !RF_BUSY) begin
                                U_LO_TR <= 1;
                                U_RF_TR <= 1;
                                state2 <= 3;
                            end
                        end
                    3  :begin
                            UPDATED <= 1;
                            state2 <= 0;
                        end
                    default: state2 <= 0;
                endcase
            end
        end
    end


endmodule