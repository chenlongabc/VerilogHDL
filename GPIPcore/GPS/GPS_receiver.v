module GPS_receiver(
    input    wire                  CLOCK_10M,
    input    wire                  RESET_N,
    input    wire                  GPS_1PPS,
    input    wire                  GPS_TX,
    output   reg                   GPS_RX,


    output   reg      [15:0]       GPS_year,
    output   reg      [ 7:0]       GPS_mouth,
    output   reg      [ 7:0]       GPS_day,
    output   reg      [ 7:0]       GPS_hour,
    output   reg      [ 7:0]       GPS_minutes,
    output   reg      [ 7:0]       GPS_second,
    output   reg      [31:0]       GPS_latitude,
    output   reg      [31:0]       GPS_longitude,
    output   reg      [31:0]       GPS_height,
    output   reg      [31:0]       GPS_altitude,
    output   reg      [ 7:0]       GPS_visible_satellites,
    output   reg      [ 7:0]       GPS_tracking_satellites,
    output   reg                   GPS_lockded
    );



    reg    [ 7:0]   rawdata[153:0];
    reg    [ 7:0]   i;
    reg    [ 7:0]   state;


/*
@@HamdyyhmsffffaaaaoooohhhhmmmmaaaaoooohhhhmmmmVVvvhhddnt
imsidd
imsidd
imsidd
imsidd
imsidd
imsidd
imsidd
imsidd
imsidd
imsidd
imsidd
imsidd
ssrrccooooTTushmvvvvvvC<CR><LF>
*/

    always @(posedge CLOCK_10M or negedge RESET_N) begin
        if (!RESET_N) begin
            state <= 0;
            i <= 0;
        end else begin
            case (state)
                0:  begin

                    end
                1:  begin
                        if (i<=153) begin
                            state <= 2;
                        end else begin
                            i <= 0;
                            GPS_year                 <= {rawdata[6], rawdata[7]};
                            GPS_mouth                <= rawdata[4];
                            GPS_day                  <= rawdata[5];
                            GPS_hour                 <= rawdata[8];
                            GPS_minutes              <= rawdata[9];
                            GPS_second               <= rawdata[10];
                            GPS_latitude             <= {rawdata[15], rawdata[16], rawdata[17], rawdata[18]};
                            GPS_longitude            <= {rawdata[19], rawdata[20], rawdata[21], rawdata[22]};
                            GPS_height               <= {rawdata[23], rawdata[24], rawdata[25], rawdata[26]};
                            GPS_altitude             <= {rawdata[27], rawdata[28], rawdata[29], rawdata[30]};
                            GPS_visible_satellites   <= rawdata[55];
                            GPS_tracking_satellites  <= rawdata[56];
                            GPS_lockded              <= (rawdata[58][3] || rawdata[64][3] || rawdata[70][3] || rawdata[76][3] || rawdata[82][3] || rawdata[88][3] || rawdata[94][3] || rawdata[100][3] || rawdata[106][3] || rawdata[112][3] || rawdata[118][3] || rawdata[124][3]);
                        end
                    end
                2:  begin
                        if (VALID) begin
                            rawdata[i] <= RDATA;
                            state <= 3;
                        end
                    end
                3:  begin
                        if (!VALID) begin
                            i <= i+1;
                            state <= 1;
                        end
                    end
                default:
            endcase
        end


    end



    wire            RX;
    wire   [ 7:0]   RDATA;
    wire            VALID;


    UART_RX #(.BAUDRATE(9600), .CLK_FREQ(10_000_000)) RX
    (
        .CLK             (CLOCK_10M),
        .RESET_N         (RESET_N),
        .RX              (RX),
        .RDATA           (RDATA),
        .VALID           (VALID)
    );

endmodule
