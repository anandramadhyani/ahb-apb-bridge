`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ananda Thirtha
// 
// Create Date: 25.09.2026 18:42:52
// Design Name: AHB Slave Testbench
// Module Name: tb_ahb_slave
// Project Name: AHB APB Bridge
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


module tb_ahb_slave
    #(parameter ADDR_WIDTH = 32,
      parameter DATA_WIDTH = 32)(

    );
    
    logic hclk;
    logic hrst_n;
    
    ahb_interface tb_if();
    logic fsm_tx_ready;
    logic fsm_tx_error;
    logic [(DATA_WIDTH - 1) : 0] apb_rdata;
    
    logic ahb_addr_valid;
    logic size_err;
    logic [(ADDR_WIDTH - 1) : 0] reg_haddr;
    logic reg_hwrite;
    logic [2 : 0] reg_hsize;
    logic [(DATA_WIDTH/ 8 - 1) : 0] reg_hwstrb;
    logic [(DATA_WIDTH - 1) : 0] reg_hwdata;
    
    assign tb_if.hclk = hclk;
    assign tb_if.hrst_n = hrst_n;
    
//================================== Clock Generation =============================//    
//=================================================================================// 

    initial begin
        hclk = 'b0;
        forever begin
            #2.5 hclk = ~ hclk;
        end
    end
   
//=================================================================================//    
//=================================================================================//    
   
//================================= UUT Instantiation =============================//    
//=================================================================================// 

    ahb_slave
    #(.ADDR_WIDTH (ADDR_WIDTH),
      .DATA_WIDTH (DATA_WIDTH)) UUT (
        .h_if (tb_if),
        .fsm_tx_ready (fsm_tx_ready),
        .fsm_tx_error (fsm_tx_error),
        .apb_rdata (apb_rdata),
        
        .ahb_addr_valid (ahb_addr_valid),
        .size_err (size_err),
        .reg_haddr (reg_haddr),
        .reg_hwrite (reg_hwrite),
        .reg_hsize (reg_hsize),
        .reg_hwstrb (reg_hwstrb),
        .reg_hwdata (reg_hwdata)
    ); 
   
//=================================================================================//    
//=================================================================================//    
  
//=================================== Drive Helpers ===============================//    
//=================================================================================// 

    task automatic drive_idle();
        tb_if.haddr <= 'd0;
        tb_if.hprot <= 'd0;
        tb_if.hsize <= 'd0;
        tb_if.htrans <= IDLE;
        tb_if.hwdata <= 'd0;
        tb_if.hwstrb <= 'd0;
        tb_if.hwrite <= 'd0;
        tb_if.hsel <= 'd0;
        tb_if.hready <= 'd0;
    endtask
    
    task automatic reset_uut();
        hrst_n = 'b0;
        drive_idle();
        fsm_tx_ready = 'b1;
        fsm_tx_error = 'b0;
        apb_rdata = 'd0;
        repeat (3)
            @(posedge hclk);
        hrst_n = 'b1;
        @(posedge hclk);    
    endtask
   
//=================================================================================//    
//=================================================================================// 

//=================================== Scoreboarding ===============================//    
//=================================================================================// 
    int errors = 0;
    int checks = 0;
    
    task automatic check32(input string name, 
                           input logic [31 : 0] actual, 
                           input logic [31 : 0] expected);
        checks ++;
        if (actual != expected) begin
            $error("[FAIL] %s : expected = %0h | actual = %0h", name, expected, actual);
            errors ++;
        end
        else begin
            $display("[PASS] %s", name);
        end
    endtask
    
    task automatic check(input string name,
                         input logic actual,
                         input logic expected);
        checks ++;
        if (expected != actual) begin
            $error("[FAIL] %s : expected = %0b | actual = %0b", name, expected, actual);
            errors ++;
        end
        else begin
            $display("[PASS] %s", name);
        end
    endtask
   
//=================================================================================//    
//=================================================================================// 

//=================================== NONSEQ Write ================================//    
//=================================================================================// 

    task automatic test_single_nonseq_write();
        fsm_tx_ready = 'b1;
        @(negedge hclk);
        tb_if.hsel = 'b1;
        tb_if.haddr = 'h1000_0004;
        tb_if.htrans = NONSEQ;
        tb_if.hwrite = 'b1;
        tb_if.hsize = 'b010;
        tb_if.hready = 'b1;
        
        @(posedge hclk);
        check("addr_valid asserted on NONSEQ", ahb_addr_valid, 'b1);
        check("HREADYOUT is HIGH", tb_if.hreadyout, 'b1);
        
        @(negedge hclk);
        tb_if.htrans = IDLE;
        tb_if.hwdata = 'hdead_beef;
        tb_if.hwstrb = 'hf;
        
        @(posedge hclk);
        check32("reg_haddr captured.", reg_haddr, 'h1000_0004);
        check("reg_haddr captured.", reg_hwrite, 'b1);
        
        @(posedge hclk);
        check32("reg_hwdata captured during data phase.", reg_hwdata, 'hdead_beef);
        check("reg_hwstrb captured during data phase.", reg_hwstrb, 'hf);
        
        drive_idle();
        @(posedge hclk);
    endtask
   
//=================================================================================//    
//=================================================================================//    
    
//=================================== NONSEQ Read =================================//    
//=================================================================================// 

    task automatic test_single_nonseq_read();
        fsm_tx_ready = 'b1;
        @(negedge hclk);
        tb_if.hsel = 'b1;
        tb_if.haddr = 'h1000_0004;
        tb_if.htrans = NONSEQ;
        tb_if.hwrite = 'b0;
        tb_if.hsize = 'b010;
        tb_if.hready = 'b1;
        
        @(posedge hclk);
        check("addr_valid asserted on NONSEQ.", ahb_addr_valid, 'b1);
        check("HREADYOUT is HIGH.", tb_if.hreadyout, 'b1);
                
        drive_idle();
        @(posedge hclk);
    endtask
   
//=================================================================================//    
//=================================================================================//    
  
//=================================== Wait States =================================//    
//=================================================================================// 

    task automatic test_wait_states();
        fsm_tx_ready = 1'b0;

        @(negedge hclk);
        tb_if.hsel   = 1'b1;
        tb_if.haddr  = 32'h3000_0000;
        tb_if.htrans = NONSEQ;
        tb_if.hwrite = 1'b0;
        tb_if.hsize  = 3'b010;
        tb_if.hready = 1'b1;

        @(posedge hclk);
        check("addr_valid asserted.", ahb_addr_valid, 1'b1);

        repeat (3) begin
            @(posedge hclk);
            check("HREADYOUT held low while fsm busy.", tb_if.hreadyout, 1'b0);
        end

        fsm_tx_ready = 1'b1;
        @(posedge hclk);
        check("HREADYOUT released once fsm_tx_ready.", tb_if.hreadyout, 1'b1);
    endtask
   
//=================================================================================//    
//=================================================================================//    
    
//=============================== BUSY and IDLE states ============================//    
//=================================================================================// 

    task automatic test_busy_idle_txs();
        fsm_tx_ready = 1'b0;

        @(negedge hclk);
        tb_if.hsel   = 1'b1;
        tb_if.htrans = BUSY;
        tb_if.hready = 1'b1;

        @(posedge hclk);
        check("HREADYOUT HIGH regardless of fsm_tx_ready.", tb_if.hreadyout, 1'b1);
        check("addr_valid is LOW when BUSY.", ahb_addr_valid, 1'b0);

        @(negedge hclk);
        tb_if.htrans = IDLE;

        @(posedge hclk);
        check("HREADYOUT HIGH regardless of fsm_tx_ready.", tb_if.hreadyout, 1'b1);
        check("addr_valid is LOW when IDLE.", ahb_addr_valid, 1'b0);

        drive_idle();        
        @(posedge hclk);        
    endtask
   
//=================================================================================//    
//=================================================================================//    
    
//=================================== HSEL = 0 ====================================//    
//=================================================================================// 

    task automatic test_hsel_low();
        fsm_tx_ready = 1'b0;

        @(negedge hclk);
        tb_if.hsel   = 1'b0;
        tb_if.htrans = NONSEQ;
        tb_if.haddr = 'h3000_0400;
        tb_if.hready = 1'b1;

        @(posedge hclk);
        check("HREADYOUT HIGH regardless of HSEL being LOW.", tb_if.hreadyout, 1'b1);
        check("addr_valid is LOW when HSEL is LOW.", ahb_addr_valid, 1'b0);

        drive_idle();        
        @(posedge hclk);        
    endtask
   
//=================================================================================//    
//=================================================================================//    
      
//============================= HRESP mirrors FSM Error ===========================//    
//=================================================================================// 

    task automatic test_hresp_mirror();
        fsm_tx_error = 1'b1;
        
        @(posedge hclk);
        check("HRESP mirrors fsm_tx_error.", tb_if.hreadyout, 1'b1);
        
        fsm_tx_error = 1'b0;
        drive_idle();        
        @(posedge hclk);        
    endtask
   
//=================================================================================//    
//=================================================================================//    
    
//========================== Size Error on Oversized HSIZE ========================//    
//=================================================================================// 

    task automatic test_size_error();
        fsm_tx_ready = 1'b1;
        
        @(negedge hclk);
        tb_if.hsel   = 1'b1;
        tb_if.htrans = NONSEQ;
        tb_if.haddr = 'h3000_0400;
        tb_if.hwrite = 'b1;
        tb_if.hsize = 'b011;
        tb_if.hready = 1'b1;
        
        @(posedge hclk);
        check("size_err asserted for oversize HSIZE.", size_err, 1'b1);
        
        @(negedge hclk);
        tb_if.hsel   = 1'b1;
        tb_if.htrans = NONSEQ;
        tb_if.haddr = 'h3000_0400;
        tb_if.hwrite = 'b1;
        tb_if.hsize = 'b010;
        tb_if.hready = 1'b1;
        
        @(posedge hclk);
        check("size_err LOW for supported HSIZE.", size_err, 1'b0);
        
        drive_idle();        
        @(posedge hclk);        
    endtask
   
//=================================================================================//    
//=================================================================================//    
    
//=========================== SEQ Back-Back Traansaction ==========================//    
//=================================================================================// 

    task automatic test_seq_read();
        fsm_tx_ready = 1'b1;
        
        @(negedge hclk);
        tb_if.hsel   = 1'b1;
        tb_if.htrans = NONSEQ;
        tb_if.haddr = 'h3000_0400;
        tb_if.hwrite = 'b0;
        tb_if.hsize = 'b010;
        tb_if.hready = 1'b1;
        
        @(posedge hclk);
        check("addr_valid asserted for NONSEQ transaction.", ahb_addr_valid, 1'b1);
        
        @(negedge hclk);
        check32("reg_haddr for beat 0.", reg_haddr, 'h3000_0400);
        tb_if.htrans = SEQ;
        tb_if.haddr = 'h3000_0404;
        
        @(posedge hclk);
        check("addr_valid asserted for SEQ transaction.", ahb_addr_valid, 1'b1);
        
        @(negedge hclk);
        check32("reg_haddr for beat 1.", reg_haddr, 'h3000_0404);
        
        drive_idle();        
        @(posedge hclk);        
    endtask
   
//=================================================================================//    
//=================================================================================//    
    
//================================= Sequence ======================================//    
//=================================================================================// 

    initial begin
        reset_uut();
        
        test_single_nonseq_write();
        test_single_nonseq_read();
        test_seq_read();
        test_wait_states();
        test_busy_idle_txs();
        test_hsel_low();
        test_hresp_mirror();
        test_size_error();
        
        $display("Total Checks: %0d | Total Errors: %0d", checks, errors);
        if (errors == 0) begin
            $display("All Tests Passed.");
        end
        else begin
            $display("%0d Tests Failed.", errors);
        end
        
        $finish;
    end
   
//=================================================================================//    
//=================================================================================//    
    
endmodule
s