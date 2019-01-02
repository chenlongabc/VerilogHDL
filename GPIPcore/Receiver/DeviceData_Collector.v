/*

    DeviceData_Collector DC(
        .CLK                         (),
        .RESET_N                     (),
        .Reveiver_ADDR               (),
        .Reveiver_DATA               (),
        .Reveiver_TR                 (),
        .Reveiver_FIFO_ACLR          (),
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

        input    wire     [15:0]     Reveiver_ADDR,
        input    wire     [31:0]     Reveiver_DATA,
        input    wire                Reveiver_TR,
        input    wire                Reveiver_FIFO_ACLR,

        input    wire                GPS_1PPS,
        input    wire                GPS_lockded,
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


    reg     [31:0]     REG[20:0];// 320 - 300
    reg     [ 7:0]     state;
    reg     [ 7:0]     i;
    reg                sneding;
    reg                GPS_1PPS_reg;
   

    always @(posedge TR_CLK) begin
        GPS_1PPS_reg <= GPS_1PPS;
    end

    always @(posedge GPS_1PPS_reg) begin
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
            TR_IN <= 0;
            FIFO_RDREQ <= 0;
            state <= 0;
            sneding <= 0;
        end else begin
            case (state)
                0:  begin
                        TR_IN <= 0;
                        state <= 1;
                    end 
                1:  begin
                        if (!FIFO_RDEMPTY) begin
                            FIFO_RDREQ <= 1;
                            state <= 2;
                        end else begin
                            state <= 4;
                        end
                    end 
                2:  begin
                        FIFO_RDREQ <= 0;
                        state <= 3;
                    end
                3:  begin
                        DATA_IN <= FIFO_Q[63:32];
                        ADDR_IN <= FIFO_Q[15: 0];
                        state <= 8;
                    end
                4:  begin // ------------------------------------------------
                        if (sneding) begin
                            state <= 6;
                        end else begin
                            state <= 5;
                        end
                    end
                5:  begin 
                        if (GPS_1PPS_reg) begin
                            sneding <= 1;
                            i <= 0;
                        end
                        state <= 0;
                    end
                6:  begin
                        if (i<=20) begin
                            state <= 7;
                        end else begin
                            if (!GPS_1PPS_reg) begin
                                sneding <= 0;
                            end
                            state <= 0;
                        end
                    end
                7:  begin
                        ADDR_IN <= REG[i];
                        DATA_IN <= i+300;
                        i <= i+1;
                        state <= 8;
                    end
                8:  begin // ------------------------------------------------
                        if (!TR_IN_BUSY) begin
                            TR_IN <= 1;
                            state <= 9;
                        end
                    end
                9:  begin
                        state <= 0;
                    end
                default: state <= 0;
            endcase
        end
    end


    wire           FIFO_ACLR;
    wire  [63:0]   FIFO_DATA;
    wire           FIFO_RDCLK;
    reg            FIFO_RDREQ;
    wire           FIFO_WRCLK;
    wire           FIFO_WRREQ;
    wire  [63:0]   FIFO_Q;
    wire           FIFO_RDEMPTY;
    wire           FIFO_WRFULL;

    assign FIFO_RDCLK = TR_CLK;
    assign FIFO_WRCLK = CLK;
    assign FIFO_ACLR  = Reveiver_FIFO_ACLR;
    assign FIFO_DATA  = {Reveiver_DATA, 16'd0, Reveiver_ADDR};
    assign FIFO_WRREQ = Reveiver_TR;

    FIFO  BUFFER(
        .aclr    ( FIFO_ACLR    ),    // input	        aclr;
        .data    ( FIFO_DATA    ),    // input	[63:0]  data;
        .rdclk   ( FIFO_RDCLK   ),    // input	        rdclk;
        .rdreq   ( FIFO_RDREQ   ),    // input	        rdreq;
        .wrclk   ( FIFO_WRCLK   ),    // input	        wrclk;
        .wrreq   ( FIFO_WRREQ   ),    // input	        wrreq;
        .q       ( FIFO_Q       ),    // output	[63:0]  q;
        .rdempty ( FIFO_RDEMPTY ),    // output	        rdempty;
        .wrfull  ( FIFO_WRFULL  )     // output	        wrfull;
    );

endmodule // DeviceData_Collector
