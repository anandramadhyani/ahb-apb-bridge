`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ananda Thirtha
// 
// Create Date: 28.09.2026 14:07:07
// Design Name: APB Master
// Module Name: apb_master
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


module apb_master(
    input logic hclk,
    input logic hrst_n,
    
    input logic [31 : 0] reg_haddr,
    input logic reg_hwrite,
    input logic [31 : 0] reg_hwdata,
    input logic [3 : 0] reg_hwstrb,
    
    input logic [3 : 0] selected_slave,
    input logic apb_start,
    input logic apb_penable_en,
    
    output logic [31 : 0] paddr,
    output logic pwrite,
    output logic penable,
    output logic [31 : 0] pwdata,
    output logic [3 : 0] pstrb,
    
    output logic [3 : 0] psel,
    input logic [3 : 0][31 : 0] prdata,
    input logic [3 : 0] pready,
    input logic [3 : 0] pslverr,
    
    output logic [31 : 0] apb_rdata,
    output logic apb_ready,
    output logic apb_error    
    );
    
//    logic [31 : 0] paddr_r;
//    logic [31 : 0] pwdata_r;
//    logic [3 : 0] pstrb_r;
//    logic [3 : 0] psel_r;
//    logic pwrite_r;
    
//    always_ff @(posedge hclk or negedge hrst_n) begin
//        if (!hrst_n) begin
//            paddr_r <= 'd0;
//            pwdata_r <= 'd0;
//            pstrb_r <= 'd0;
//            psel_r <= 'd0;
//            pwrite_r <= 'b0;
//        end
//        else if (apb_start) begin
//            paddr_r <= reg_haddr;
//            pwdata_r <= reg_hwdata;
//            pstrb_r <= reg_hwstrb;
//            psel_r <= selected_slave;
//            pwrite_r <= reg_hwrite;
//        end
//    end
    
    assign paddr = reg_haddr;
    assign pwrite = reg_hwrite;
    assign pwdata = reg_hwdata;
    assign pstrb = reg_hwstrb;
    assign penable = apb_penable_en;
    
    assign psel = selected_slave & {4{apb_start || apb_penable_en}};
    
    logic [1:0] sel_idx;
    always_comb begin
        case (selected_slave)
            4'b0001: sel_idx = 2'd0;
            4'b0010: sel_idx = 2'd1;
            4'b0100: sel_idx = 2'd2;
            4'b1000: sel_idx = 2'd3;
            default: sel_idx = 2'd0;
        endcase
    end

//    assign apb_rdata = prdata[sel_idx];
//    assign apb_ready = pready[sel_idx];
//    assign apb_error = pslverr[sel_idx];
    
    always_ff @(posedge hclk or negedge hrst_n) begin
        if (!hrst_n) begin
            apb_rdata <= 'd0;
            apb_ready <= 'b0;
            apb_error <= 'b0;
        end
        else begin
            apb_rdata <= prdata[sel_idx];
            apb_ready <= pready[sel_idx];
            apb_error <= pslverr[sel_idx];
        end
    end
    
endmodule
