/*
*
*                    ┌───────────────────────────────────────────────────────────────────────────────────────────────────┐                      
*                    │                                                                                                   │                      
*    PRE_GEN    ─────┘                                                                                                   └──────────────────────
*
*                                   ┌────────────────────────────────────────────────────────────────────────────────────┐                     
*                    │   6*256      │                                                                                    │                     
*    GEN        ────────────────────┘                                                                                    └──────────────────────
*     
*                                   ┌─────────────┐                                      
*                    │   6*256      │   16*256    │                                       
*    RF_MA      ────────────────────┘             └─────────────────────────────────────────────────────────────────────────────────────────────
*      
*                                ┌───────────────────┐                                      
*                    │  5*256    │                   │                                       
*    SW         ─────────────────┘                   └──────────────────────────────────────────────────────────────────────────────────────────
*
*                                ┌┐                  ┌┐                                     
*                    │           ││                  ││                                      
*    NIS        ─────────────────┘└──────────────────┘└─────────────────────────────────────────────────────────────────────────────────────────
*
*               ─────────────────┐                      ┌───────────────────────────────────────────────────────────────────────────────────────
*                    │  5*256    │                      │                                                                                       
*    LO_MA                       └──────────────────────┘                                                                                       
*/




module Switch_Group(
    input     wire             CLOCK_10M,
    input     wire             RESET_N,
    input     wire             TR,
    input     wire    [15:0]   ADDR,
    input     wire    [31:0]   DATA,
    input     wire    [ 7:0]   PROBE_MODE,
    input     wire             PRE_GEN,
    output    wire             LO_MA,
    output    wire             RECEIVE_SW
    );

    reg  [15:0] pre_delay_LO_MA;  // 5*256
    reg  [15:0] post_delay_LO_MA; // 5*256 + 16*256 + 1*256

    reg  [15:0] pre_delay_Filter_Switch;  // 5*256
    reg  [15:0] post_delay_Filter_Switch; // 5*256 + 16*256 + 5*256

    reg  default_LO_MA = 0;
    reg  default_RECEIVE_SW = 0;


    wire  RECEIVE_SW_OUT;
    wire  LO_MA_OUT;
    wire  RECEIVE_SW_EN;
    wire  LO_MA_EN;

    // (1)send/recv (2)send (3)near-recv (4)far-recv (5)close test
    assign LO_MA_EN      = (PROBE_MODE != 2) ? 1 : 0;
    assign RECEIVE_SW_EN = LO_MA_EN;

    // when close test, open SW ans LO_MA all the time ( set LO_MA 1,  set RECEIVE_SW 0 )
    assign LO_MA         = default_LO_MA ? 1 : !(LO_MA_EN && LO_MA_OUT);
    assign RECEIVE_SW    = default_RECEIVE_SW ? 0 : (RECEIVE_SW_EN && RECEIVE_SW_OUT);




    always @(posedge TR or negedge RESET_N) begin
        if (!RESET_N) begin
            pre_delay_LO_MA <=  1;
            post_delay_LO_MA <= 1 + 16*256 + 6*256;
            pre_delay_Filter_Switch <= 1;
            post_delay_Filter_Switch <= 1 + 16*256 + 1*256;
            default_LO_MA <= 0;
            default_RECEIVE_SW <= 0;
        end else begin
            if (ADDR == 172) begin
                pre_delay_LO_MA <= DATA;
            end else if (ADDR == 173) begin
                post_delay_LO_MA <= DATA;
            end else if (ADDR == 174) begin
                pre_delay_Filter_Switch <= DATA;
            end else if (ADDR == 175) begin
                post_delay_Filter_Switch <= DATA;
            end else if (ADDR == 176) begin
                default_LO_MA <= DATA;
            end else if (ADDR == 177) begin
                default_RECEIVE_SW <= DATA;
            end
        end
    end


    Switch SW_LO_MA(
        .CLK              (CLOCK_10M),
        .RESET_N          (PRE_GEN),
        .PRE_DELAY        (pre_delay_LO_MA),
        .POST_DELAY       (post_delay_LO_MA),
        .OUT              (LO_MA_OUT)
    );

    Switch SW_Filter_Switch(
        .CLK              (CLOCK_10M),
        .RESET_N          (PRE_GEN),
        .PRE_DELAY        (pre_delay_Filter_Switch),
        .POST_DELAY       (post_delay_Filter_Switch),
        .OUT              (RECEIVE_SW_OUT)
    );

endmodule // Switch_Grou    