/*
    Receiver R(
        .CLK                    (),
        .RESET_N                (),
        .AD_DATA                (),
        .AD_CLK                 (),
        .PULSE_LEN              (),
        .Reveiver_ADDR          (),
        .Reveiver_DATA          (),
        .Reveiver_TR            (),
        .Reveiver_FIFO_ACLR     (),
        .Reveiver_OVER          ()
    );

*/

module Receiver(
        input    wire                CLK,
        input    wire                RESET_N,
        input    wire     [15:0]     AD_DATA,
        input    wire                AD_CLK,
        input    wire     [15:0]     PULSE_LEN,
        output   reg      [15:0]     Reveiver_ADDR,
        output   reg      [31:0]     Reveiver_DATA,
        output   reg                 Reveiver_TR,
        output   reg                 Reveiver_FIFO_ACLR,
        output   reg                 Reveiver_OVER
    );

    reg   [15:0]   i;
    reg   [15:0]   AD_DATA_reg;
    reg   [15:0]   pulse_length;
    reg   [ 7:0]   state;
    

    always @(posedge AD_CLK) begin
        AD_DATA_reg <= AD_DATA;
    end

    
    always @(posedge CLK or negedge RESET_N) begin
        if (!RESET_N) begin
            Reveiver_FIFO_ACLR <= 1;
            Reveiver_TR <= 0;
            state <= 255;
            i <= 0;
            Reveiver_OVER <= 0;
        end else begin
            case (state)
                255:  begin
                        Reveiver_FIFO_ACLR <= 0;
                        pulse_length <= PULSE_LEN;
                        state <= 0;
                    end
                0:  begin
                        Reveiver_TR <= 0;
                        state <= 1;
                    end 
                1:  begin
                        if (VALID) begin
                            state <= 2;
                        end
                    end 
                2:  begin
                        if (i < pulse_length) begin
                            Reveiver_DATA <= {IDATA, QDATA};
                            Reveiver_ADDR <= 500+i;
                            state <= 3;
                        end else if (i == pulse_length) begin
                            Reveiver_DATA <= 1;
                            Reveiver_ADDR <= 499;
                            state <= 3;
                        end else begin
                            state <= 4;
                        end
                    end 
                3:  begin
                        Reveiver_TR <= 1;
                        i <= i+1;
                        state <= 0;
                    end
                4:  begin
                        Reveiver_OVER <= 1;
                    end  
                default: state <= 0;
            endcase
        end
    end





    /************************** FIFO interface **************************/
    wire  [15:0]   IDATA;
    wire  [15:0]   QDATA;
    wire           VALID;


    DDC ddc(
        .CLK         (CLK),
        .RESET_N     (RESET_N),
        .NCO_PIF     (601295421),
        .AD_DATA     (AD_DATA_reg),
        .DATA0       (IDATA),
        .VALID0      (VALID),
        .DATA1       (QDATA),
        .VALID1      ()
    );

endmodule
