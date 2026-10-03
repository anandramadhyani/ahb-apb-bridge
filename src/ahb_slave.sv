`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ananda Thirtha 
// 
// Create Date: 24.08.2026 18:47:48
// Design Name: AHB Slave Design
// Module Name: ahb_slave
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


module ahb_slave
    #(parameter int ADDR_WIDTH = 32,
      parameter int DATA_WIDTH = 32)(
    input logic hclk,
    input logic hrst_n,
    
    input logic [(ADDR_WIDTH - 1) : 0] haddr,
    input logic [3 : 0] hprot,
    input logic [2 : 0] hsize,
    input logic [1 : 0] htrans,
    input logic [(DATA_WIDTH - 1) : 0] hwdata,
    input logic [(DATA_WIDTH/ 8 - 1) : 0] hwstrb,
    input logic hwrite,
    input logic hsel,
    input logic hready,
    
    output logic [31 : 0] hrdata,
    output logic hreadyout,
    output logic hresp,
    
    input logic fsm_tx_ready,
    input logic fsm_tx_error,
    input logic [(DATA_WIDTH - 1) : 0] apb_rdata,
    
    output logic ahb_addr_valid,
    output logic size_err,
    output logic [(ADDR_WIDTH - 1) : 0] reg_haddr,
    output logic reg_hwrite,
    output logic [2 : 0] reg_hsize,
    output logic [(DATA_WIDTH/ 8 - 1) : 0] reg_hwstrb,
    output logic [(DATA_WIDTH - 1) : 0] reg_hwdata
    );      
    
    typedef enum logic [1 : 0] {
        IDLE,
        BUSY,
        NONSEQ,
        SEQ
    } trans_t;
    
    localparam logic [2 : 0] MAX_HWORD_SIZE = 3'b010;

    assign ahb_addr_valid = hsel && hready &&
                        (htrans == NONSEQ || htrans == SEQ);
                        
    assign size_err = ahb_addr_valid && (hsize > MAX_HWORD_SIZE); 
    
    assign hresp = fsm_tx_error;
    
    assign hrdata = apb_rdata;   
    
//=================================== Address Phase Latch =============================//    
//=====================================================================================//    
    
    always_ff @(posedge hclk or negedge hrst_n) begin
        if (!hrst_n) begin
            reg_haddr <= 'd0;
            reg_hwrite <= 'd0;
            reg_hsize <= 'd0;
        end
        else if (ahb_addr_valid) begin
            reg_haddr <= haddr;
            reg_hwrite <= hwrite;
            reg_hsize <= hsize;
        end
    end
    
//=====================================================================================//    
//=====================================================================================//

//===================================== Data Phase Latch ==============================//    
//=====================================================================================//    
    logic addr_valid_d1;
    
    always_ff @(posedge hclk or negedge hrst_n) begin
        if (!hrst_n) begin
            addr_valid_d1 <= 'd0;
        end
        else begin
            addr_valid_d1 <= ahb_addr_valid;
        end
    end
    
    always_ff @(posedge hclk or negedge hrst_n) begin
        if (!hrst_n) begin
            reg_hwstrb <= 'd0;
            reg_hwdata <= 'd0;
        end
        else if (addr_valid_d1 && reg_hwrite) begin
            reg_hwstrb <= hwstrb;
            reg_hwdata <= hwdata;
        end
    end
    
//=====================================================================================//    
//=====================================================================================//

//===================================== HREADYOUT output ==============================//    
//=====================================================================================//    
    always_comb begin
        if (!hsel || (htrans == IDLE || htrans == BUSY)) begin
            hreadyout = 'b1;
        end
        else begin
            hreadyout = fsm_tx_ready;
        end
    end
    
//=====================================================================================//    
//=====================================================================================//
        
endmodule
