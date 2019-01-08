
module Filter_Selector(    
    input   wire     [31:0]    FREQW,
    output  wire     [ 2:0]    FILTER_SELECT
);
    reg [2:0] FILTER_ID = 0;
    assign FILTER_SELECT = 7-FILTER_ID;
	
    localparam   RFfre0 = 32'd26396153;
    localparam   RFfre1 = 32'd40712710;
    localparam   RFfre2 = 32'd63977116;
    localparam   RFfre3 = 32'd101558080;
    localparam   RFfre4 = 32'd171351299;
    localparam   RFfre5 = 32'd289462899;
    localparam   RFfre6 = 32'd523449139;


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
