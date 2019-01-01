module Launcher(
    input    wire                 CLK,
    input    wire                 RESET_N,
    input    wire                 TR,
    input    wire       [15:0]    ADDR,
    input    wire       [31:0]    DATA,

    input    wire                 GPS_1PPS,
    input    wire                 GPS_locked,
    input    wire       [15:0]    GPS_year,
    input    wire       [ 7:0]    GPS_mouth,
    input    wire       [ 7:0]    GPS_day,
    input    wire       [ 7:0]    GPS_hour,
    input    wire       [ 7:0]    GPS_minutes,
    input    wire       [ 7:0]    GPS_second,

    output   wire                 START,
    output   reg                  RESET_N_PROBE,
    output   reg                  INIT_DDS

    );
    reg             start;
    reg             start_probe;
    reg             reset_n_probe;
    reg             init_dds;
    reg   [ 7:0]    trigger_mode; //  1：立即触发   2：GPS同步触发
    reg   [15:0]    timing_year;
    reg   [ 7:0]    timing_mouth;
    reg   [ 7:0]    timing_day;
    reg   [ 7:0]    timing_hour;
    reg   [ 7:0]    timing_minutes;
    reg   [ 7:0]    timing_second;

    wire   timing;
    assign timing =((timing_year == GPS_year) &&
                    (timing_mouth == GPS_mouth) &&
                    (timing_day == GPS_day) &&
                    (timing_hour == GPS_hour) &&
                    (timing_minutes == GPS_minutes) &&
                    (timing_second == GPS_second));





    always @(posedge TR or negedge RESET_N) begin
        if (!RESET_N) begin
            start_probe <= 0;
            reset_n_probe <= 0;
            init_dds <= 0;
            trigger_mode <= 0;
            timing_year <= 0;
            timing_mouth <= 0;
            timing_day <= 0;
            timing_hour <= 0;
            timing_minutes <= 0;
            timing_second <= 0;
        end else begin
            if (ADDR == 101) begin
                start_probe <= DATA;
            end else if (ADDR == 102) begin
                reset_n_probe <= DATA;
            end else if (ADDR == 103) begin
                init_dds <= DATA;
            end else if (ADDR == 110) begin
                trigger_mode <= DATA;
            end else if (ADDR == 112) begin
                timing_year <= DATA;
            end else if (ADDR == 113) begin
                timing_mouth <= DATA;
            end else if (ADDR == 114) begin
                timing_day <= DATA;
            end else if (ADDR == 115) begin
                timing_hour <= DATA;
            end else if (ADDR == 116) begin
                timing_minutes <= DATA;
            end else if (ADDR == 117) begin 
                timing_second <= DATA;
            end
        end
    end

    always @(posedge CLK or negedge RESET_N) begin
        if (!RESET_N) begin
            INIT_DDS <= 0;
            RESET_N_PROBE <= 0;
        end else begin
            INIT_DDS <= init_dds;
            RESET_N_PROBE <= reset_n_probe;
        end
    end

    always @(posedge GPS_1PPS or negedge RESET_N_PROBE) begin
        if (!RESET_N_PROBE) begin
            start <= 0;
        end else begin
            if (trigger_mode==1 && start_probe) begin
                start <= 1;
            end else if (trigger_mode==2 && GPS_locked && start_probe) begin
                if (timing) begin
                    start <= 1;
                end
            end
        end
    end

    assign START = start && start_probe;

endmodule // Launcher