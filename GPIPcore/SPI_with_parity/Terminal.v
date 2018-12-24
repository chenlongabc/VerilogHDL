/*

AD

*/

module Terminal(
    input    wire            CLK,
    input    wire            RESET_N,


    input    wire            TR_IN,
    input    wire   [ 7:0]   ADDR_IN,
    input    wire   [31:0]   DATA_IN,
    output   reg             BUSY,

    
    output   reg             TR_OUT,
    output   reg    [ 7:0]   ADDR_OUT,
    output   reg    [31:0]   DATA_OUT,

    output   reg             RELEASE,

    input    wire            SPI_RD_SS  ,//   : AD <- DE1 
    input    wire            SPI_RD_SCK ,//   : AD <- DE1
    input    wire            SPI_RD_SD  ,//   : AD <- DE1
    output   wire            SPI_RD_SACK,//   : AD -> DE1    

    output   wire            SPI_WR_SS  ,//   : AD -> DE1
    output   wire            SPI_WR_SCK ,//   : AD -> DE1
    output   wire            SPI_WR_SD  ,//   : AD -> DE1
    input    wire            SPI_WR_SACK //   : AD <- DE1
    );

	reg            SPI_WR = 0;
	reg            SPI_RD = 0;
	wire           SPI_VALID_RD;
	wire           SPI_BUSY_WR;
	reg   [63:0]   SPI_DATA_WR = 0;
	wire  [63:0]   SPI_DATA_RD;
    reg   [63:0]   intruction = 0;
    
	reg   [ 7:0]   state1 = 0;
    reg   [ 7:0]   state2 = 0;

	always @(posedge CLK or negedge RESET_N) begin
        if (!RESET_N) begin
            SPI_WR <= 0;
            BUSY <= 0;
            state1 <= 0;
        end else begin
            case(state1)
                0:begin
                    SPI_WR <= 0;
                    BUSY <= 0;
                    state1 <= 1;
                end
                1:begin
                    if (TR_IN) begin // send it to DE1
                        SPI_DATA_WR = {8'b0, DATA_IN, ADDR_IN, 16'b0};
                        BUSY <= 1;
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
            TR_OUT <= 0
            state2 <= 0;
            RELEASE <= 0;
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
                    if (intruction[7:0] == 1) begin
                        state2 <= 5;
                    end else begin
                        state2 <= 0;
                    end
                end
                5:begin
                    if (intruction[15:8] == 102) begin
                        RELEASE <= 0;
                        state2 <= 0;
                    end else if (intruction[15:8] == 103) begin
                        RELEASE <= 1;
                        state2 <= 0;
                    end else if (intruction[15:8] == 111) begin//save
                        ADDR_OUT <= intruction[23:16];
                        DATA_OUT <= intruction[55:24];
                        state2 <= 6;
                    end else if (intruction[15:8] == 222) begin//read
                        state2 <= 0;
                    end else begin
                        state2 <= 0;
                    end
                end
                6:begin
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
