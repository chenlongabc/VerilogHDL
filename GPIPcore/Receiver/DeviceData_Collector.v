/*

    DeviceData_Collector DC(
        .CLK                         (),
        .RESET_N                     (),
        .Reveiver_priority           (),
        .Reveiver_ADDR               (),
        .Reveiver_DATA               (),
        .Reveiver_TR                 (),
        .Reveiver_TR_IN_BUSY         (),
        .GPS_1PPS                    (),
        .GPS_lockded                 (),
        .GPS_year                    (),
        .GPS_mouth                   (),
        .GPS_day                     (),
        .GPS_hour                    (),
        .GPS_minutes                 (),
        .GPS_second                  (),
        .GPS_latitude                (),
        .GPS_longitude               (),
        .GPS_height                  (),
        .GPS_altitude                (),
        .GPS_visible_satellites      (),
        .GPS_tracking_satellites     (),
        .Frequency_Accuracy          (),
        .TR_CLK                      (),
        .TR_IN                       (),
        .ADDR_IN                     (),
        .DATA_IN                     (),
        .TR_IN_BUSY                  ()
    );


*/


module DeviceData_Collector(
        input    wire                CLK,
        
        input    wire                RESET_N,
        input    wire                Reveiver_priority,
        input    wire     [15:0]     Reveiver_ADDR,
        input    wire     [31:0]     Reveiver_DATA,
        input    wire                Reveiver_TR,
        output   wire                Reveiver_TR_IN_BUSY,

        input    wire                GPS_1PPS,
        input    wire                GPS_lockded
        input    wire     [15:0]     GPS_year,
        input    wire     [ 7:0]     GPS_mouth,
        input    wire     [ 7:0]     GPS_day,
        input    wire     [ 7:0]     GPS_hour,
        input    wire     [ 7:0]     GPS_minutes,
        input    wire     [ 7:0]     GPS_second,
        input    wire     [31:0]     GPS_latitude,
        input    wire     [31:0]     GPS_longitude,
        input    wire     [31:0]     GPS_height,
        input    wire     [31:0]     GPS_altitude,
        input    wire     [ 7:0]     GPS_visible_satellites,
        input    wire     [ 7:0]     GPS_tracking_satellites,
        input    wire     [31:0]     Frequency_Accuracy,
        
        input    wire                TR_CLK,
        output   reg                 TR_IN,
        output   reg      [15:0]     ADDR_IN,
        output   reg      [31:0]     DATA_IN,
        input    wire                TR_IN_BUSY
    );


    reg     [31:0]     REGS[20:0];// 320 - 300
    reg     [ 7:0]     state;
    reg     [ 7:0]     i;

    always @(posedge GPS_1PPS) begin
        REG[ 0] <= GPS_lockded;
        REG[ 1] <= GPS_year;
        REG[ 2] <= GPS_mouth;
        REG[ 3] <= GPS_day;
        REG[ 4] <= GPS_hour;
        REG[ 5] <= GPS_minutes;
        REG[ 6] <= GPS_second;
        REG[ 8] <= GPS_latitude;
        REG[ 9] <= GPS_longitude;
        REG[10] <= GPS_height;
        REG[11] <= GPS_altitude;
        REG[12] <= GPS_visible_satellites;
        REG[13] <= GPS_tracking_satellites;
        REG[20] <= Frequency_Accuracy;
    end


    always @(posedge TR_CLK or negedge RESET_N) begin
        if (!RESET_N) begin
            state <= 0;
        end else begin
            case (state)
                0:  begin
                        TR_IN <= 0;
                        state <= 1;
                    end 
                1:  begin
                        if (Reveiver_priority) begin
                            state <= 0;
                        end else begin
                            state <= 0;
                        end
                    end 
                default: state <= 0;
            endcase
        end
    end


endmodule // DeviceData_Collector
