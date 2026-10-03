`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ananda Thirtha
// 
// Create Date: 23.08.2026 16:23:53
// Design Name: Address Decoder Design
// Module Name: address_decoder
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


module address_decoder(
        input logic [3 : 0] addr,
        output logic [3 : 0] selected_slave,
        output logic addr_err
    );
    
    always_comb begin
        selected_slave = 'd0;
        addr_err = 'b0;
        case (addr)
            'd0: begin
                selected_slave = 'd1;
            end
            
            'd1: begin
                selected_slave = 'd2;
            end
            
            'd2: begin
                selected_slave = 'd4;
            end
            
            'd3: begin
                selected_slave = 'd8;
            end
            
            default: begin
                addr_err = 'b1;
            end
        endcase
    end
endmodule
