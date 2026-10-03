`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ananda Thirtha
// 
// Create Date: 22.08.2026 13:57:53
// Design Name: Timeout Counter Design
// Module Name: timeout_counter
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


module timeout_counter
    #(parameter int MAX_TIMEOUT = 256)(
        input logic clk,
        input logic rst_n,
        input logic start,
        input logic stop,
        output logic timeout_expired
    );
    
    logic [($clog2(MAX_TIMEOUT) - 1) : 0] counter_value;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_value <= 'd0;
        end
        else if (stop) begin
            counter_value <= 'd0;
        end
        else if (start) begin
            if (counter_value < MAX_TIMEOUT - 1) begin
                counter_value <= counter_value + 1;
            end            
        end
        else begin
            counter_value <= 'd0;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout_expired <= 'b0;
        end
        else begin
            timeout_expired <= (counter_value == (MAX_TIMEOUT - 1) && !stop);
        end
    end
    
endmodule
