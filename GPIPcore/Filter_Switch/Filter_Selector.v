/*
*    ID     fliters
*  -------------------
*    0    ~ 2.45MHz
*    1    ~ 3.55MHz
*    2    ~ 5.15MHz
*    3    ~ 7.55MHz
*    4    ~ 11.15MHz
*    5    ~ 16.55MHz
*    6    ~ 24.65MHz
*    7    ~ 30.00MHz
*/
module Filter_Selector(    
    input   wire     [31:0]    FREQW,
    output  wire     [ 2:0]    FILTER_SELECT
);
    reg [2:0] FILTER_ID = 0;
    assign FILTER_SELECT = 7-FILTER_ID;
	
    localparam   RFfre0 = 32'd26843545;
    localparam   RFfre1 = 32'd41160103;
    localparam   RFfre2 = 32'd64424509;
    localparam   RFfre3 = 32'd102005473;
    localparam   RFfre4 = 32'd171798691;
    localparam   RFfre5 = 32'd289910292;
    localparam   RFfre6 = 32'd519869999;


    always @(*) begin // 1MHZ : 8947848.53(FREQW)
        if(FREQW < RFfre0)     // [0 - 3]
            FILTER_ID <= 0;
        else if(FREQW < RFfre1)// [2.9 - 4.6]
            FILTER_ID <= 1;
        else if(FREQW < RFfre2)// [4.5 - 7.2]
            FILTER_ID <= 2;
        else if(FREQW < RFfre3)// [7.1 - 11.4]
            FILTER_ID <= 3;
        else if(FREQW < RFfre4)// [11.3 - 19.2]
            FILTER_ID <= 4;
        else if(FREQW < RFfre5)// [19.1 - 32.4]
            FILTER_ID <= 5;
        else if(FREQW < RFfre6)// [32.3 - 58.1]
            FILTER_ID <= 6;
        else                   // [58 - 100]
            FILTER_ID <= 7;
    end
 
endmodule
