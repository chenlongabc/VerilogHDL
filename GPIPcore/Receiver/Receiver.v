module Receiver(
        input    wire                CLK,
        input    wire                RESET_N,
        input    wire     [15:0]     AD_DATA,
        input    wire                AD_CLK,

        input    wire     [15:0]     PULSE_LEN,
        output   reg                 TR_OUT,
        output   reg      [15:0]     ADDR_OUT,
        output   reg      [31:0]     DATA_OUT,
        output   reg                 RECEIVE_OVER
    );

    reg   [15:0]   i;
    reg   [15:0]   AD_DATA_reg;
    reg            RECEIVE_EN;

    

    always @(posedge AD_CLK) begin
        AD_DATA_reg <= AD_DATA;
    end

    always @(posedge CLK or negedge RESET_N) begin
        if (!RESET_N) begin
            FIFO_ACLR <= 1;
        end else begin
            FIFO_ACLR <= 0;
        end
    end

    always @(posedge VALID or negedge RESET_N) begin
        if (!RESET_N) begin
            i <= 1;
            RECEIVE_EN <= 1;
        end else begin
            if (i<=PULSE_LEN) begin
                i <= i+1;
            end else begin
                RECEIVE_EN <= 0;
            end
        end
    end

    


    /************************** FIFO interface **************************/
    wire  [15:0]   IDATA;
    wire  [15:0]   QDATA;
    wire           VALID;

    reg            FIFO_ACLR;
    wire  [31:0]   FIFO_DATA;
    wire           FIFO_RDCLK;
    reg            FIFO_RDREQ;
    wire           FIFO_WRCLK;
    reg            FIFO_WRREQ;
    wire  [31:0]   FIFO_Q;
    wire           FIFO_RDEMPTY;
    wire           FIFO_WRFULL;



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
/*
    assign FIFO_RDCLK = CLK;
    assign FIFO_WRCLK = CLK;
    assign FIFO_DATA  = {QDATA[15:0],IDATA[15:0]};
    assign FIFO_WRREQ = RECEIVE_EN && VALID;

    FIFO_32bit  BUFFER_32bit (
        .aclr    ( FIFO_ACLR    ),    // input	        aclr;
        .data    ( FIFO_DATA    ),    // input	[31:0]  data;
        .rdclk   ( FIFO_RDCLK   ),    // input	        rdclk;
        .rdreq   ( FIFO_RDREQ   ),    // input	        rdreq;
        .wrclk   ( FIFO_WRCLK   ),    // input	        wrclk;
        .wrreq   ( FIFO_WRREQ   ),    // input	        wrreq;
        .q       ( FIFO_Q       ),    // output	[31:0]  q;
        .rdempty ( FIFO_RDEMPTY ),    // output	        rdempty;
        .wrfull  ( FIFO_WRFULL  )     // output	        wrfull;
    );
*/
endmodule
