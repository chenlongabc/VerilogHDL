module Signal_Transceiver(
    input    wire            CLOCK_10M,
    input    wire            RESET_N,

    input    wire            START,

    input    wire            TR,
    input    wire   [15:0]   ADDR,
    input    wire   [31:0]   DATA,

    output   reg             SIGNAL_TRANSC_BUSY,
    input    wire            SIGNAL_GEN_OVER,
    input    wire            Reveiver_OVER,

    output   reg             RF_OUTPUT_EN,
    output   reg             GEN,
    output   reg             PRE_GEN,
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

    reg   [ 7:0]    probe_mode; // 1：收发  2：发送  3：近场接收  4：远场接收  5：闭环测试
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

    reg   [15:0]    pre_delay_GEN = 5*256;


    reg   [31:0]    cur_freqw;     // OUT
    reg   [31:0]    cur_stepping_freqw;
    reg   [15:0]    cur_groups_number;
    reg   [15:0]    cur_repetition_number;
    reg   [15:0]    cur_stepping_number;
    reg   [ 7:0]    cur_code_number;

    assign  FREQW = cur_freqw;

    reg   [ 7:0]    state = 0;
    reg             start = 0;
    reg   [15:0]    delay = 0;
    /***************************************************************************************/

    always @(posedge TR or negedge RESET_N) begin
        if (!RESET_N) begin
            pre_delay_GEN <= 6*256;
        end else begin
            if (ADDR == 120) begin
                probe_mode <= DATA;
            end else if (ADDR == 121) begin
                probe_interval <= DATA;
            end else if (ADDR == 122) begin
                groups_number <= DATA;
            end else if (ADDR == 123) begin
                repetition_number <= DATA;
            end else if (ADDR == 124) begin
                frequency_mode <= DATA;
            end else if (ADDR == 125) begin
                starting_freqw <= DATA;
            end else if (ADDR == 126) begin
                stepping_freqw <= DATA;
            end else if (ADDR == 127) begin
                stepping_number <= DATA;
            end else if (ADDR == 128) begin
                code_type <= DATA;
            end else if (ADDR == 129) begin
                code_number <= DATA;
            end else if (ADDR == 130) begin
                code_length <= DATA;
            end else if (ADDR == 131) begin
                code_duration <= DATA;
            end else if (ADDR == 132) begin
                pulse_lenght <= DATA;
            end else if (133 <= ADDR && ADDR <= 164) begin
                codes[ADDR-133] <= DATA;
            end else if (ADDR == 170) begin
                pre_delay_GEN <= DATA;
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
            RF_OUTPUT_EN <= (probe_mode == 1 || probe_mode == 2 || probe_mode == 5) ? 1 : 0;
        end 
    end

    always @(posedge CLOCK_10M or negedge RESET_N) begin
        if (!RESET_N) begin
            state <= 0;
            GEN   <= 0;
            PRE_GEN <= 0;
            SIGNAL_TRANSC_BUSY <= 0;
        end else begin
            case (state)
                0:  begin
                        GEN <= 0;
                        PRE_GEN <= 0;
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
                            cur_stepping_freqw    <= stepping_freqw;

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
                            state <= 10;
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
                            cur_freqw <= cur_freqw + cur_stepping_freqw;
                            state <= 3;
                        end
                    end
                6:  begin
                        if (cur_code_number < code_number) begin
                            CODE  <= codes[cur_code_number];
                            delay <= 0;
                            state <= 7;// V
                        end else begin
                            cur_repetition_number <= cur_repetition_number + 1;
                            state <= 5;// ^
                        end
                    end
                7:  begin
                        PRE_GEN <= 1; 
                        delay <= delay+1;
                        if (delay > pre_delay_GEN) begin
                            state <= 8;
                        end
                    end
                8:  begin // start generating signal
                        GEN <= 1; 
                        state <= 9;
                    end
                9:  begin // finish generating signal
                        if (SIGNAL_GEN_OVER && Reveiver_OVER) begin//if (SIGNAL_GEN_OVER && SIGNAL_SAMPL_OVER) begin
                            GEN <= 0; 
                            PRE_GEN <= 0; 
                            cur_code_number <= cur_code_number + 1;
                            state <= 6; // ^^
                        end
                    end
                10:  begin // ending
                        state <= 0;
                    end
                default: state <= 0;
            endcase
        end
    end








endmodule // Signal_Transceiver
