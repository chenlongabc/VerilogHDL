/*

AD

*/

module Terminal(
    input    wire            CLK,
    input    wire            RESET_N,
    input    wire            TR_IN,
    input    wire   [15:0]   ADDR_IN,
    input    wire   [31:0]   DATA_IN,
    output   reg             TR_IN_BUSY,
    output   reg             TR_OUT,
    output   reg    [15:0]   ADDR_OUT,
    output   reg    [31:0]   DATA_OUT,
    input    wire            SPI_RD_SS  ,//   : AD <- DE1 
    input    wire            SPI_RD_SCK ,//   : AD <- DE1
    input    wire            SPI_RD_SD  ,//   : AD <- DE1
    output   wire            SPI_RD_SACK,//   : AD -> DE1    
    output   wire            SPI_WR_SS  ,//   : AD -> DE1
    output   wire            SPI_WR_SCK ,//   : AD -> DE1
    output   wire            SPI_WR_SD  ,//   : AD -> DE1
    input    wire            SPI_WR_SACK //   : AD <- DE1
    );

	reg   [ 7:0]   state1;
    reg   [ 7:0]   state2;

	reg            SPI_WR;
	reg            SPI_RD;
	wire           SPI_VALID_RD;
	wire           SPI_BUSY_WR;
	reg   [63:0]   SPI_DATA_WR;
	wire  [63:0]   SPI_DATA_RD;
    reg   [63:0]   intruction;
    wire  [31:0]   instruction_data;
    wire  [15:0]   instruction_addr;

    assign instruction_data = intruction[63:32];
    assign instruction_addr = intruction[15: 0];

	always @(posedge CLK or negedge RESET_N) begin
        if (!RESET_N) begin
            SPI_WR <= 0;
            TR_IN_BUSY <= 0;
            state1 <= 0;
        end else begin
            case(state1)
                0:begin
                    SPI_WR <= 0;
                    TR_IN_BUSY <= 0;
                    state1 <= 1;
                end
                1:begin
                    if (TR_IN) begin // send it to DE1
                        SPI_DATA_WR = {DATA_IN, 16'b0, ADDR_IN};
                        TR_IN_BUSY <= 1;
                        state1 <= 2;
                    end
                end
                2:begin
                    if (!SPI_BUSY_WR) begin
                        SPI_WR <= 1;
                        state1 <= 3;
                    end
                end
                3:begin
                    state1 <= 0;
                end
            endcase
        end
	end


    always @(posedge CLK or negedge RESET_N) begin
        if (!RESET_N) begin
            SPI_RD <= 0;
            TR_OUT <= 0;
            state2 <= 0;
            intruction <= 0;
        end else begin
            case(state2)
                0:begin
                    SPI_RD <= 0;
                    TR_OUT <= 0;
                    state2 <= 1;
                end
                1:begin
                    if (SPI_VALID_RD) begin
                        intruction <= SPI_DATA_RD;
                        SPI_RD <= 1;
                        state2 <= 2;
                    end
                end
                2:begin
                    state2 <= 3;
                end
                3:begin
                    SPI_RD <= 0;
                    state2 <= 4;
                end
                4:begin
                    ADDR_OUT <= instruction_addr;
                    DATA_OUT <= instruction_data;
                    state2 <= 5;
                end
                5:begin
                    TR_OUT <= 1;
                    state2 <= 0;
                end
            endcase
        end
	end



    SPI_MASTER MASTER(
		.CLK         (CLK),
		.RESET_N     (RESET_N),

		.WR          (SPI_WR),
		.DATA        (SPI_DATA_WR),
		.BUSY        (SPI_BUSY_WR),

		.SS          (SPI_WR_SS  ),
		.SCLK        (SPI_WR_SCK ),
		.SD          (SPI_WR_SD  ),
		.SACK        (SPI_WR_SACK)
    );
	 
    SPI_SLAVE SLAVE(
		.CLK         (CLK),
		.RESET_N     (RESET_N),

		.RD          (SPI_RD),
		.DATA        (SPI_DATA_RD),
		.VALID       (SPI_VALID_RD),

		.SS          (SPI_RD_SS  ),
		.SCLK        (SPI_RD_SCK ),
		.SD          (SPI_RD_SD  ),
		.SACK        (SPI_RD_SACK)
    );

endmodule
