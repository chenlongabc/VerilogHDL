module Signal_Transceiver(
    input    wire            CLOCK_10M,
    input    wire            RESET_N,

    input    wire            START,

    input    wire            TR,
    input    wire   [15:0]   ADDR,
    input    wire   [31:0]   DATA,

    output   reg             SIGNAL_TRANSC_BUSY,
    input    wire            SIGNAL_GEN_OVER,

    output   reg             RF_OUTPUT_EN,
    output   reg             GEN,
    output   reg    [31:0]   CODE,
    output   reg    [15:0]   CODE_LEN,
    output   reg    [15:0]   CODE_DURATION,
    output   reg    [15:0]   PULSE_LEN,
    output   reg    [ 7:0]   PROBE_MODE,

    input    wire            INITIED,
    output   wire   [31:0]   FREQW,
    output   reg             UPDATE,
    input    wire            UPDATED
    );

    reg   [ 7:0]    probe_mode; // 1：收发  2：只发送  3：只接收  4：闭环测试
    reg   [31:0]    probe_interval;
    reg   [15:0]    groups_number;
    reg   [15:0]    repetition_number;
    reg   [ 7:0]    frequency_mode; // 1：定频  2：跳频  3：扫频
    reg   [31:0]    starting_freqw;
    reg   [31:0]    stepping_freqw;
    reg   [15:0]    stepping_number;
    reg   [ 7:0]    code_type;
    reg   [ 7:0]    code_number;
    reg   [15:0]    code_length;   // OUT
    reg   [15:0]    code_duration; // OUT
    reg   [15:0]    pulse_lenght;  // OUT
    reg   [31:0]    codes[31:0];   // OUT
    reg   [31:0]    checked = 0;


    reg   [31:0]    cur_freqw;     // OUT
    reg   [15:0]    cur_groups_number;
    reg   [15:0]    cur_repetition_number;
    reg   [15:0]    cur_stepping_number;
    reg   [ 7:0]    cur_code_number;

    assign  FREQW = cur_freqw;

    reg   [ 7:0]    state = 0;
    reg             start = 0;
    /***************************************************************************************/

    always @(posedge TR or negedge RESET_N) begin
        if (!RESET_N) begin
            checked <= 0;
        end else begin
            if (ADDR == 120) begin
                probe_mode <= DATA;
                checked[0] <= 1;
            end else if (ADDR == 121) begin
                probe_interval <= DATA;
                checked[1] <= 1;
            end else if (ADDR == 122) begin
                groups_number <= DATA;
                checked[2] <= 1;
            end else if (ADDR == 123) begin
                repetition_number <= DATA;
                checked[3] <= 1;
            end else if (ADDR == 124) begin
                frequency_mode <= DATA;
                checked[4] <= 1;
            end else if (ADDR == 125) begin
                starting_freqw <= DATA;
                checked[5] <= 1;
            end else if (ADDR == 126) begin
                stepping_freqw <= DATA;
                checked[6] <= 1;
            end else if (ADDR == 127) begin
                stepping_number <= DATA;
                checked[7] <= 1;
            end else if (ADDR == 128) begin
                code_type <= DATA;
                checked[8] <= 1;
            end else if (ADDR == 129) begin
                code_number <= DATA;
                checked[9] <= 1;
            end else if (ADDR == 130) begin
                code_length <= DATA;
                checked[10] <= 1;
            end else if (ADDR == 131) begin
                code_duration <= DATA;
                checked[11] <= 1;
            end else if (ADDR == 132) begin
                pulse_lenght <= DATA;
                checked[12] <= 1;
            end else if (133 <= ADDR && ADDR <= 164) begin
                codes[ADDR-133] <= DATA;
                checked[13] <= 1;
            end
        end
    end

    /***************************************************************************************/
    always @(posedge CLOCK_10M or negedge RESET_N) begin
        if (!RESET_N) begin
            start <= 0;
        end else begin
            start <= START;
        end 
    end

    always @(posedge start or negedge RESET_N) begin
        if (!RESET_N) begin
            RF_OUTPUT_EN <= 0;
        end else begin
            RF_OUTPUT_EN <= (probe_mode == 1 || probe_mode == 2 || probe_mode == 4) ? 1 : 0;
        end 
    end

    always @(posedge CLOCK_10M or negedge RESET_N) begin
        if (!RESET_N) begin
            state <= 0;
            GEN   <= 0;
            SIGNAL_TRANSC_BUSY <= 0;
        end else begin
            case (state)
                0:  begin
                        GEN <= 0;
                        SIGNAL_TRANSC_BUSY <= 0;
                        if (!start) begin
                            state <= 1;
                        end
                    end
                1:  begin
                        if (start) begin
                            SIGNAL_TRANSC_BUSY    <= 1;
                            cur_freqw             <= starting_freqw;    
                            //cur_groups_number   <= 0;
                            cur_repetition_number <= 0;
                            cur_stepping_number   <= 0;
                            cur_code_number       <= 0;

                            CODE          <= 0;
                            CODE_LEN      <= code_length;
                            CODE_DURATION <= code_duration;
                            PULSE_LEN     <= pulse_lenght;
                            PROBE_MODE    <= probe_mode;
                            state <= 2;
                        end
                    end
                2:  begin//err
                        if (INITIED) begin
                            state <= 3;
                        end
                    end
                3:  begin
                        if (cur_stepping_number < stepping_number) begin
                            cur_repetition_number <= 0;
                            //cur_freqw <= starting_freqw + stepping_freqw*cur_stepping_number;
                            UPDATE <= 1;
                            state <= 4;
                        end else begin
                            state <= 9;
                        end
                    end
                4:  begin // updata freqw of ad9911(RF and LO)
                        if (UPDATED) begin
                            state <= UPDATE ? 4 : 5;
                        end else begin
                            UPDATE <= 0;
                        end
                    end
                5:  begin
                        if (cur_repetition_number < repetition_number) begin
                            cur_code_number <= 0;
                            state <= 6;
                        end else begin
                            cur_stepping_number <= cur_stepping_number + 1;
                            cur_freqw <= cur_freqw + cur_stepping_number;
                            state <= 3;
                        end
                    end
                6:  begin
                        if (cur_code_number < code_number) begin
                            CODE  <= codes[cur_code_number];
                            state <= 7;// V
                        end else begin
                            cur_repetition_number <= cur_repetition_number + 1;
                            state <= 5;// ^
                        end
                    end
                7:  begin // start generating signal
                        GEN <= 1; 
                        state <= 8; // ^
                    end
                8:  begin // finish generating signal
                        if (SIGNAL_GEN_OVER) begin//if (SIGNAL_GEN_OVER && SIGNAL_SAMPL_OVER) begin
                            GEN <= 0; 
                            cur_code_number <= cur_code_number + 1;
                            state <= 6; // ^^
                        end
                    end
                9:  begin // ending
                        state <= 0;
                    end
                default: state <= 0;
            endcase
        end
    end








endmodule // Signal_Transceiver
