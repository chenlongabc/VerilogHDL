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
*    TR         ───────────────────┘                                └─────────────────────────────────────────────────────
*
*/





module Receive_Switch #(parameter ON = 1'b0, parameter OFF = 1'b1)(
    input   wire             CLOCK_10M,
    input   wire             SW_EN,
    input   wire    [7:0]    PROBE_MODE,//1: send & receive  2: send-only    3: receive-only   4:close test 
    input   wire             GEN,
    input   wire             MA,
    output  wire             RECEIVE_SW
    );

    localparam RAISE = 2'b01;
    localparam FALL = 2'b10;

    reg [1:0]   GENr = 0;  
    reg [1:0]   MAr = 0;
    reg         TR = OFF;
    reg         cnting = 0;
    reg [15:0]  cnt = 0;  
    
    assign RECEIVE_SW = SW_EN ? TR : OFF;

    always @(posedge CLOCK_10M) GENr <= {GENr[0], GEN};
    always @(posedge CLOCK_10M) MAr  <= {MAr[0], MA};


    always @(posedge CLOCK_10M) begin
        if (!SW_EN) begin
            cnt <= 0;
            cnting <= 0;
            TR <= OFF;
        end else begin
            if (PROBE_MODE == 1) begin  
                if (cnting) begin
                    if (cnt>255) begin
                        cnting <= 0;
                        TR <= ON;
                    end
                    cnt <= cnt+1;  
                end
                if (GENr == RAISE) begin
                    TR <= OFF;
                end else if (MAr == FALL) begin
                    cnt <= 0;
                    cnting <= 1;
                end
            end else if (PROBE_MODE == 2) begin
                TR <= OFF;
            end else if (PROBE_MODE == 3) begin
                TR <= ON;
            end else if (PROBE_MODE == 4) begin
                TR <= ON;
            end else begin
                TR <= OFF;
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
