/*
/*
*
*                    ┌───────────────────────────────────────────────────────────────────────────────────────────────────┐                      
*                    │                                                                                                   │                      
*    PRE_GEN    ─────┘                                                                                                   └──────────────────────
*                    │                                              
*                    │               ┌─────────────┐                                          
*                    │               │   16*256    │                                  
*    OUT        ─────────────────────┘             └─────────────────────────────────────────────────────────────────────────────────────────────
*                    │               │             │
*                    │               │             │                                                   
*                    │-- PRE_DELAY --│             │                                                   
*                    │                             │                                                   
*                    │                             │                                                   
*                    │-------- POST_DELAY ---------│                                                   
*                                                                       
*/


module Switch(
    input     wire             CLK,
    input     wire             RESET_N,
    input     wire    [15:0]   PRE_DELAY,
    input     wire    [15:0]   POST_DELAY,
    output    reg              OUT             
    );


    reg    [15:0]   delay;

    always @(posedge CLK or negedge RESET_N) begin
        if (!RESET_N) begin
            delay <= 0;
            OUT <= 0;
        end else begin
            if (delay < PRE_DELAY) begin
                OUT <= 0;
                delay <= delay + 1;
            end else if (delay < POST_DELAY) begin
                OUT <= 1;
                delay <= delay + 1;
            end else begin
                OUT <= 0;
            end
        end
    end



endmodule // Switch