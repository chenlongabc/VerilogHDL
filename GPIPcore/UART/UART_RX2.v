
/*
 * file    : UART_RX.v
 * author  : zyl
 * date    : 2018-8-22
 * version : 1.1
 * addr    : whu.edu.ionosphereLab
 */

module UART_RX #(parameter BAUDRATE = 9600, parameter CLK_FREQ = 10_000_000)(
    input                 CLK,
    input                 RESET_N,
    input                 RX,
    output reg    [7:0]   RDATA,
    output reg            VALID
    );

    localparam T = CLK_FREQ / BAUDRATE;
    localparam HT = (CLK_FREQ / BAUDRATE) / 2;
    localparam Q1T = (CLK_FREQ / BAUDRATE) / 4;
    localparam Q3T = 3 * (CLK_FREQ / BAUDRATE) /4;



    always @(posedge CLK or negedge RESET_N) begin
        if(!RESET_N)
            count <= 0;
            receiving <= 0;
        end else begin
            if (RX) begin
                if (count > 10*T) begin
                    receiving <= 0;
                end else begin
                    count <= count + 1;
                end
            end else begin
                count <= 0;
                receiving <= 1;
            end

            if (receiving) begin
                if (count > 10*T) begin
                    receiving <= 0;
                end else begin
                    count <= count + 1;
                end
            end
        end
    end


    always @(posedge CLK or negedge RESET_N) begin
        if(!RESET_N)

        end else begin
            if (receiving) begin

            end else begin
              
            end
        end
    end



endmodule