/**
default status
0: ON
1: OFF
*/

/*
* when PROBE_MODE = 1:
*                                  ┌─┐ 
*                                  │ │  
*    GEN        ───────────────────┘ └────────────────────────────────────────────────────────────────────────────────────
*     
*                                    ┌───────────────────────────┐ 
*                                    │                           │  
*    MA         ─────────────────────┘                           └────────────────────────────────────────────────────────
*      
*                                  ┌────────────────────────────────┐ 
*                                  │                                │  
*    SW         ───────────────────┘                                └─────────────────────────────────────────────────────
*
*/





module Receive_Switch #(parameter ON = 1'b0, OFF = 1'b1)(
    input   wire             CLOCK_10M,
    input   wire             TR,
    input   wire    [15:0]   ADDR,
    input   wire    [31:0]   DATA,
    input   wire             SW_EN,
    input   wire    [7:0]    PROBE_MODE,
    input   wire             PRE_GEN,
    input   wire             RF_MA,
    output  wire             LO_MA,
    output  wire             RECEIVE_SW
    );

    localparam RAISE = 2'b01;
    localparam FALL = 2'b10;

    reg [1:0]   GENr = 0;  
    reg [1:0]   MAr = 0;
    reg         SW = OFF;
    reg         cnting = 0;
    reg [15:0]  cnt = 0;  
    reg [15:0]  afterMA = 256;  
    reg         LO_MA_SW_en = 1;
    
    assign LO_MA = LO_MA_SW_en ? !SW : 1;
    assign RECEIVE_SW = SW_EN ? SW : OFF;

    always @(posedge CLOCK_10M) GENr <= {GENr[0], PRE_GEN};
    always @(posedge CLOCK_10M) MAr  <= {MAr[0], RF_MA};


    always @(posedge TR or negedge SW_EN) begin
        if (!SW_EN) begin
            afterMA <= 256;
            LO_MA_SW_en <= 1;
        end else begin
            if (ADDR == 171) begin
                afterMA <= DATA;
            end else if (ADDR == 172) begin
                LO_MA_SW_en <= DATA;
            end
        end
    end

    always @(posedge CLOCK_10M) begin
        if (!SW_EN) begin
            cnt <= 0;
            cnting <= 0;
            SW <= OFF;
        end else begin
            if (PROBE_MODE == 1 || PROBE_MODE == 3) begin  
                if (cnting) begin
                    if (cnt>afterMA) begin
                        cnting <= 0;
                        SW <= ON;
                    end
                    cnt <= cnt+1;  
                end
                if (GENr == RAISE) begin
                    SW <= OFF;
                end else if (MAr == FALL) begin
                    cnt <= 0;
                    cnting <= 1;
                end
            end else if (PROBE_MODE == 2) begin
                SW <= OFF;
            end else if (PROBE_MODE == 4) begin
                SW <= ON;
            end else if (PROBE_MODE == 5) begin
                SW <= ON;
            end else begin
                SW <= OFF;
            end
        end

        
    end


/*
    always @(posedge CLK) begin
        if (!EN) begin
            RECEIVE_SW <= ON;
            state <= 0;
        end else begin
            case (state)
                0:  begin
                        RECEIVE_SW <= ON;
                        state <= 1;
                    end 
                1 : begin
                        if (GEN) begin
                            RECEIVE_SW <= OFF;
                            cnt <= 0;
                            state <= 2;
                        end
                    end
                2 : begin
                        if (MA) begin
                            state <= 3;
                        end
                    end
                3 : begin
                        if (!MA) begin
                            state <= 4;
                        end
                    end
                4 : begin
                        if (cnt > 200) begin//20us
                            state <= 0;
                        end
                        cnt <= cnt+1;
                    end
                default : state <= 0;
            endcase
        end
    end
*/
endmodule
