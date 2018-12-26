module HPS_Terminal(
    input    wire                   s_clk,
    input    wire                   s_reset_n,
    input    wire                   s_write,
    input    wire                   s_read,
    input    wire        [ 9:0]     s_address,
    input    wire        [63:0]     s_writedata,
    input    wire        [63:0]     s_readdata,

    output   reg                    rd,  
    input    wire                   rd_valid,
    input    wire        [63:0]     rd_instruction, 

    output   reg                    wr,
    input    wire                   wr_busy,
    output   reg         [63:0]     wr_instruction 

    );

    reg  [31:0]  RAM[1023:0];
    reg  [ 9:0]  addr;
    reg  [31:0]  data;

endmodule
