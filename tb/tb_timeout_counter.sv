`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ananda Thirtha
// 
// Create Date: 22.08.2026 15:45:14
// Design Name: Timeout Counter Testbench
// Module Name: tb_timeout_counter
// Project Name: AHB-APB Bridge
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_timeout_counter
    #(parameter MAX_TIMEOUT = 8)(

    );
    
    logic clk;
    logic rst_n;
    logic start;
    logic stop;
    logic timeout_expired;
    
    timeout_counter
    #(.MAX_TIMEOUT (MAX_TIMEOUT)) UUT (
        .clk (clk),
        .rst_n (rst_n),
        .start (start),
        .stop (stop),
        .timeout_expired (timeout_expired)
    );
    
    initial begin
        clk = 'b0;
        forever begin
            #2.5 clk = ~ clk;
        end
    end
    
    initial begin
        rst_n = 'b1;
        @(posedge clk)
            #1 rst_n = 'b0;
        @(posedge clk);
        @(posedge clk)
            #1 rst_n = 'b1;
    end
    
    initial begin
        start = 'b0;
        stop = 'b0;
        #200 $finish;
    end
    
    initial begin
        repeat (5)
            @(posedge clk);
        #1 start = 'b1;   
        repeat (9)
            @(posedge clk);
        #1 start = 'b0;       
        repeat (9)
            @(posedge clk);
        #1 start = 'b1;
        @(posedge clk);    
        @(posedge clk)
            #1 stop = 'b1;       
        @(posedge clk)
            #1 start = 'b0;
            stop = 'b0;            
    end
    
//===================================================Reset Assertions==========================================//    
//=============================================================================================================//   
 
    assert property (
        @(posedge clk)
        !rst_n |-> (
            UUT.counter_value == '0 &&
            timeout_expired == 1'b0
        )
    )
    else $error ("State is not cleared while reset is active.");
    
    assert property (
        @(posedge clk)
        !rst_n |=> (
            UUT.counter_value == '0 &&
            timeout_expired == 1'b0
        )
    )
    else $error ("State is not cleared after reset.");
    
    assert property (
        @(negedge rst_n)
        1'b1 |-> @(posedge clk) (
            UUT.counter_value == '0 &&
            timeout_expired == 1'b0
        )
    )
    else $error ("Async Reset did not clear state.");
//================================================================================================================//    
//================================================================================================================//

//======================================= Start and Stop Assertions ==============================================//    
//================================================================================================================//

    assert property (
        @(posedge clk)
        disable iff (!rst_n)
        (start && !stop && UUT.counter_value < MAX_TIMEOUT -1) |=> 
            UUT.counter_value == ($past(UUT.counter_value) + 1'b1)
    )
    else $error ("Counter did not increment correctly.");
    
    assert property (
        @(posedge clk)
        disable iff (!rst_n)
        (start && !stop && UUT.counter_value == MAX_TIMEOUT - 1) |=>
            UUT.counter_value == MAX_TIMEOUT - 1
    )
    else $error ("Counter did not hold the value.");
    
    assert property (
        @(posedge clk)
        disable iff (!rst_n)
        !start |=> UUT.counter_value == '0
    )
    else $error ("Counter did not clear when Start is LOW.");
    
    assert property (
        @(posedge clk)
        disable iff (!rst_n)
        stop |=> UUT.counter_value == '0
    )
    else $error ("Counter did not clear after Stop.");
    
    assert property (
        @(posedge clk)
        disable iff (!rst_n)
        (start && stop) |=> UUT.counter_value == '0
    )
    else $error ("Stop did not have priority over Start.");

//================================================================================================================//    
//================================================================================================================//    
    
//======================================= Timeout Assertions ==============================================//    
//================================================================================================================//

    assert property (
        @(posedge clk)
        disable iff (!rst_n)
        (UUT.counter_value == 'd7) |=> timeout_expired == 'b1
    )
    else $error ("Timeout Expired output does not go HIGH when counter reaches MAX_TIMEOUT value.");
    
    assert property (
        @(posedge clk)
        disable iff (!rst_n)
        $rose (timeout_expired) |-> ($past(UUT.counter_value) == MAX_TIMEOUT - 1)
        )
    else $error ("Timeout Expired output rose without the counter reaching MAX_TIMEOUT value.");    
    
    assert property (
        @(posedge clk)
        disable iff (!rst_n)
        (start && !stop)[*MAX_TIMEOUT] |=> timeout_expired
    )
    else $error ("Timeout Expired output did not go HIGH when counter expired.");
    
    assert property (
        @(posedge clk)
        disable iff (!rst_n)
        !start [*2] |=> !timeout_expired
    )
    else $error ("TImeout Expired output did not go LOW when start is LOW for 2 consecutive cycles.");
    
//================================================================================================================//    
//================================================================================================================//    
    
//============================================= Cover Events =====================================================//    
//================================================================================================================//  

    cover property (
        @(posedge clk)
        start
    );
    
    cover property (
        @(posedge clk)
        start && stop
    ); 
    
    cover property (
        @(posedge clk)
        start [*8] |=> timeout_expired
    );
    
    cover property (
        @(posedge clk)
        $rose (timeout_expired) |-> ##2 !start
    );
  
//================================================================================================================//    
//================================================================================================================//   
 
endmodule
