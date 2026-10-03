`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ananda Thirtha
// 
// Create Date: 28.09.2026 16:53:20
// Design Name: APB Master Testbench
// Module Name: tb_apb_master
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


module tb_apb_master(

    );
    
    logic hclk;
    logic hrst_n;
    
    logic [31 : 0] reg_haddr;
    logic reg_hwrite;
    logic [31 : 0] reg_hwdata;
    logic [3 : 0] reg_hwstrb;
    
    logic [3 : 0] selected_slave;
    logic apb_start;
    logic apb_penable_en;
    
    logic [31 : 0] paddr;
    logic pwrite;
    logic penable;
    logic [31 : 0] pwdata;
    logic [3 : 0] pstrb;
    
    logic [3 : 0] psel;
    logic [3 : 0][31 : 0] prdata;
    logic [3 : 0] pready;
    logic [3 : 0] pslverr;
    
    logic [31 : 0] apb_rdata;
    logic apb_ready;
    logic apb_error;
    
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

    apb_master UUT (
        .*
    ); 
   
//=================================================================================//    
//=================================================================================//    
     
//=================================== Drive Helpers ===============================//    
//=================================================================================// 

    task automatic drive_idle();
        apb_start <= 'b0;
        apb_penable_en <= 'b0;
        reg_haddr <= 'd0;
        reg_hwrite <= 'b0;
        reg_hwdata <= 'd0;
        reg_hwstrb <= 'd0;
        selected_slave <= 'd0;
    endtask
    
    task automatic reset_uut();
        hrst_n = 'b0;
        drive_idle();
        prdata[0] = 32'h1111_1111;
        prdata[1] = 32'h2222_2222;
        prdata[2] = 32'h3333_3333;
        prdata[3] = 32'h4444_4444;
        pready = 4'b1111;
        pslverr = 4'b0000;
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
   
    task automatic check4(input string name,
                         input logic [3 : 0] actual,
                         input logic [3 : 0] expected);
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
    
//=================================== Reset UUT ===================================//    
//=================================================================================// 

    task automatic test_reset_uut();
        $display("--- test_reset_uut ---");
        check4("PSEL is zero after reset", psel, 4'b0000);
        check32("PADDR is zero after reset", paddr, 32'h0);
        check("PWRITE is zero after reset", pwrite, 1'b0);
    endtask
   
//=================================================================================//    
//=================================================================================//    
    
//=================================== APB Latch ===================================//    
//=================================================================================// 

    task automatic test_apb_latch();
        $display("--- test_apb_latch ---");
        @(negedge hclk);
        reg_haddr      = 32'h1000_0040;
        reg_hwrite     = 1'b1;
        reg_hwdata     = 32'hAAAA_5555;
        reg_hwstrb     = 4'b0011;
        selected_slave = 4'b0010;   
        apb_start      = 1'b1;

        @(negedge hclk);
        apb_start = 1'b0;
        
        check32("PADDR latched", paddr, 32'h1000_0040);
        check("PWRITE latched", pwrite, 1'b1);
        check32("PWDATA latched", pwdata, 32'hAAAA_5555);
        check4("PSTRB latched", pstrb, 4'b0011);
        check4("PSEL latched (slave 1)", psel, 4'b0010);
    endtask
   
//=================================================================================//    
//=================================================================================//    
    
//=================================== Hold steady =================================//    
//=================================================================================// 

    task automatic test_hold_state();
        $display("--- test_hold_state ---");
        @(negedge hclk);
        reg_haddr      = 32'hdead_0000;
        reg_hwdata     = 32'hFFFF_FFFF;
        
        @(posedge hclk);
        @(negedge hclk); 
        check32("PADDR holds previous value.", paddr, 32'h1000_0040);
        check32("PWDATA holds previous value.", pwdata, 32'hAAAA_5555);
    endtask
   
//=================================================================================//    
//=================================================================================//    
    
//===================================== PENABLE ===================================//    
//=================================================================================// 

    task automatic test_penable();
        $display("--- test_penable ---");
        apb_penable_en = 'b1;
        #1;
        check("PENABLE follows apb_penable_en HIGH.", penable, 'b1);
        
        apb_penable_en = 'b0;
        #1;
        check("PENABLE follows apb_penable_en LOW.", penable, 'b0);        
    endtask
   
//=================================================================================//    
//=================================================================================//    
    
//============================== Response from Slave ==============================//    
//=================================================================================// 

    task automatic test_response(input int slave_idx);
        logic [3 : 0] sel_onehot;
        $display("--- test_response (slave %0d) ---", slave_idx);
        sel_onehot = (4'b0001 << slave_idx);

        pready  = 4'b0000; 
        pready[slave_idx]  = 1'b1;
        pslverr = 4'b0000; 
        pslverr[slave_idx] = (slave_idx == 2);

        @(negedge hclk);
        selected_slave = sel_onehot;
        apb_start = 1'b1;
        
        @(negedge hclk);
        apb_start = 1'b0;
        check32($sformatf("apb_rdata mux slave %0d", 
                          slave_idx), apb_rdata, prdata[slave_idx]);
        check($sformatf("apb_ready mux slave %0d", slave_idx), apb_ready, 1'b1);
        check($sformatf("apb_error mux slave %0d", slave_idx),
              apb_error, (slave_idx == 2) ? 1'b1 : 1'b0);        
    endtask
   
//=================================================================================//    
//=================================================================================//    
    
//================================ Decode Error =================================//    
//=================================================================================// 

    task automatic test_decode_error();
        $display("--- test_decode_error ---");

        @(negedge hclk);
        selected_slave = 'd0;
        apb_start = 1'b1;

        @(negedge hclk);
        apb_start = 1'b0;
        check4("PSEL stays zero, no slave falsely selected", psel, 4'b0000);       
    endtask
   
//=================================================================================//    
//=================================================================================//    
    
//=================================== Sequence ====================================//    
//=================================================================================// 

    initial begin
        reset_uut();
        
        test_reset_uut();
        test_apb_latch();
        test_hold_state();
        test_penable();
        
        for (int i = 0; i < 4; i++) begin
            test_response(i);
        end  
        test_decode_error();
        
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
