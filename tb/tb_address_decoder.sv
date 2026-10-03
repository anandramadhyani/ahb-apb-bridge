`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ananda Thirtha
// 
// Create Date: 23.08.2026 16:44:29
// Design Name: Address Decoder Testbench
// Module Name: tb_address_decoder
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


module tb_address_decoder
    #(parameter NUMBER_OF_SLAVES = 4)(

    );
    
    logic [3 : 0] addr;
    logic [(NUMBER_OF_SLAVES - 1) : 0] selected_slave;
    logic addr_err;
    
    address_decoder #(        
        .NUMBER_OF_SLAVES (NUMBER_OF_SLAVES)) UUT (
        .addr (addr),
        .selected_slave (selected_slave),
        .addr_err (addr_err)
    );
    
    initial begin
        addr = 4'h0;
        for (int i = 0; i < 10; i ++) begin
            #5 addr = $random;
        end
        #5 $finish;
    end
    
endmodule
