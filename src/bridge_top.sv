`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ananda Thirtha
// 
// Create Date: 29.09.2026 17:29:06
// Design Name: Bridge Top
// Module Name: bridge_top
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


module bridge_top
    #(parameter ADDR_WIDTH = 32,
      parameter DATA_WIDTH = 32,
      parameter MAX_TIMEOUT = 256)(
    
        input logic hclk,
        input logic hrst_n,
        
        input logic hsel,
        input logic [(ADDR_WIDTH - 1) : 0] haddr,
        input logic hwrite,
        input logic [1 : 0] htrans,
        input logic [2 : 0] hsize,
        input logic [3 : 0] hprot,
        input logic hready,
        input logic [(DATA_WIDTH - 1) : 0] hwdata,
        input logic [(DATA_WIDTH/ 8 - 1) : 0] hwstrb,
        output logic [(DATA_WIDTH - 1) : 0] hrdata,
        output logic hreadyout,
        output logic hresp,
        
        input logic [3 : 0][31 : 0] prdata,
        input logic [3 : 0] pready,
        input logic [3 : 0] pslverr,              
        output logic [31 : 0] paddr,
        output logic pwrite,
        output logic penable,
        output logic [31 : 0] pwdata,
        output logic [3 : 0] pstrb,
        output logic [3 : 0] psel
    );
    
    logic fsm_ready, fsm_error;
    logic [31 : 0] apb_rdata;
    logic addr_valid, size_err;
    logic [(ADDR_WIDTH - 1) : 0] reg_haddr;
    logic [(DATA_WIDTH - 1) : 0] reg_hwdata;
    logic reg_hwrite;
    logic [2 : 0] reg_hsize;
    logic [(DATA_WIDTH/ 8 - 1) : 0] reg_hwstrb;
    
    logic [3 : 0] selected_slave;
    logic apb_start, apb_penable_en;
    logic apb_ready, apb_error;
    
    logic addr_err;
    
    logic start, stop;
    logic timeout_expired;
    
//================================== AHB Slave Instance ===============================//    
//=====================================================================================//    
    
    ahb_slave
        #(.ADDR_WIDTH (ADDR_WIDTH),
          .DATA_WIDTH (DATA_WIDTH)) AHB_SLAVE (
        .hclk (hclk),
        .hrst_n (hrst_n),
        
        .haddr (haddr),
        .hprot (hprot),
        .hsize (hsize),
        .htrans (htrans),
        .hwdata (hwdata),
        .hwstrb (hwstrb),
        .hwrite (hwrite),
        .hsel (hsel),
        .hready (hready),    
        .hrdata (hrdata),
        .hreadyout(hreadyout),
        .hresp (hresp),
        
        .fsm_tx_ready (fsm_ready),
        .fsm_tx_error (fsm_error),
        .apb_rdata (apb_rdata),
        
        .ahb_addr_valid (addr_valid),
        .size_err (size_err),
        .reg_haddr (reg_haddr),
        .reg_hwrite (reg_hwrite),
        .reg_hsize (reg_hsize),
        .reg_hwstrb (reg_hwstrb),
        .reg_hwdata (reg_hwdata)
    );  
 
//=====================================================================================//   
//=====================================================================================//   
    
//================================== APB Master Instance ==============================//    
//=====================================================================================//    
    
    apb_master APB_MASTER (
        .hclk (hclk),
        .hrst_n (hrst_n),
        
        .reg_haddr (reg_haddr),
        .reg_hwrite (reg_hwrite),
        .reg_hwdata (reg_hwdata),
        .reg_hwstrb (reg_hwstrb),
        .selected_slave (selected_slave),
        .apb_start (apb_start),
        .apb_penable_en (apb_penable_en),
        
        .paddr (paddr),
        .pwrite (pwrite),    
        .penable (penable),
        .pwdata (pwdata),
        .pstrb (pstrb),    
        .psel (psel),
        .prdata (prdata),
        .pready (pready),
        .pslverr (pslverr),
        
        .apb_rdata (apb_rdata),
        .apb_ready (apb_ready),
        .apb_error (apb_error)
    );  
 
//=====================================================================================//   
//=====================================================================================//   
    
//=============================== Address Decoder Instance ============================//    
//=====================================================================================//    
    
    address_decoder ADDR_DEC (
        .addr (reg_haddr[31 : 28]),
        .selected_slave (selected_slave),
        .addr_err (addr_err)
    );
 
//=====================================================================================//   
//=====================================================================================//   
    
//=============================== Watch-Dog Timer Instance ============================//    
//=====================================================================================//    
    
    timeout_counter
    #(.MAX_TIMEOUT (MAX_TIMEOUT)) WD_TIMER (
        .clk (hclk),
        .rst_n (hrst_n),
        .start (start),
        .stop (stop),
        .timeout_expired (timeout_expired)
    );
 
//=====================================================================================//   
//=====================================================================================//   
    
//================================= Control FSM Instance ==============================//    
//=====================================================================================//    
    
    control_fsm CTRL_FSM (
        .hclk (hclk),
        .hrst_n (hrst_n),
        
        .ahb_addr_valid (addr_valid),
        .size_err (size_err),
        
        .timeout_expired (timeout_expired),
        
        //.selected_slave (),
        .addr_err (addr_err),
            
        .apb_ready (apb_ready),
        .apb_error (apb_error),
        
        .fsm_tx_ready (fsm_ready),
        .fsm_tx_error (fsm_error),
        
        .apb_start (apb_start),
        .apb_penable_en (apb_penable_en),      
        
        .start (start),
        .stop (stop)
    );
 
//=====================================================================================//   
//=====================================================================================//   
    
endmodule
