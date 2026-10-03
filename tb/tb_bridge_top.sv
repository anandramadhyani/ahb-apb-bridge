`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ananda Thirha
// 
// Create Date: 29.09.2026 20:46:56
// Design Name: Bridge Top Testbench
// Module Name: tb_bridge_top
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


module tb_bridge_top
    #(parameter ADDR_WIDTH = 32,
      parameter DATA_WIDTH = 32)(

    );
    
    localparam int MAX_TIMEOUT = 16;
    localparam logic [1 : 0] IDLE = 'b00;
    localparam logic [1 : 0] NONSEQ = 'b10;
    
    logic hclk;
    logic hrst_n;
    
    logic hsel;
    logic [(ADDR_WIDTH - 1) : 0] haddr;
    logic hwrite;
    logic [1 : 0] htrans;
    logic [2 : 0] hsize;
    logic [3 : 0] hprot;
    logic hready;
    logic [(DATA_WIDTH - 1) : 0] hwdata;
    logic [(DATA_WIDTH/ 8 - 1) : 0] hwstrb;
    logic [(DATA_WIDTH - 1) : 0] hrdata;
    logic hreadyout;
    logic hresp;
    
    logic [3 : 0][31 : 0] prdata;
    logic [3 : 0] pready;
    logic [3 : 0] pslverr;              
    logic [31 : 0] paddr;
    logic pwrite;
    logic penable;
    logic [31 : 0] pwdata;
    logic [3 : 0] pstrb;
    logic [3 : 0] psel;
       
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

    bridge_top 
        #(.MAX_TIMEOUT (MAX_TIMEOUT)) UUT (
        .*
    ); 
   
//=================================================================================//    
//=================================================================================//            
    
//================================= APB Slave Models ==============================//    
//=================================================================================// 

    logic [3:0] slave_wait_cycles;
    logic [3:0] slave_force_err;
    logic [3:0] slave_never_ready;
    logic [31:0] slave_rdata [4];

    logic [3:0] wait_cnt   [4];
    logic       psel_prev  [4];
    
    genvar gi;
    generate
        for (gi = 0; gi < 4; gi++) begin : gen_slave
            always_ff @(posedge hclk or negedge hrst_n) begin
                if (!hrst_n) begin
                    wait_cnt[gi]  <= '0;
                    psel_prev[gi] <= 1'b0;
                end
                else begin
                    psel_prev[gi] <= psel[gi];
                    if (psel[gi] && !psel_prev[gi])
                        wait_cnt[gi] <= slave_wait_cycles[gi];
                    else if (psel[gi] && penable && wait_cnt[gi] != 0)
                        wait_cnt[gi] <= wait_cnt[gi] - 1;
                end
            end

            assign pready[gi]  = slave_never_ready[gi] ? 1'b0 :
                                  (psel[gi] && penable && (wait_cnt[gi] == 0));
            assign pslverr[gi] = slave_force_err[gi] && pready[gi];
            assign prdata[gi]  = slave_rdata[gi];
        end
    endgenerate

    task automatic reset_slaves();
        slave_wait_cycles = 4'b0000;
        slave_force_err   = 4'b0000;
        slave_never_ready = 4'b0000;
        slave_rdata[0] = 32'hA0A0_A0A0;
        slave_rdata[1] = 32'hB1B1_B1B1;
        slave_rdata[2] = 32'hC2C2_C2C2;
        slave_rdata[3] = 32'hD3D3_D3D3;
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
    
//==================================== AHB Master =================================//    
//=================================================================================// 
    
    task automatic drive_idle();
        hsel <= 'b0; 
        htrans <= IDLE; 
        hwrite <= 'b0;
        haddr <= '0; 
        hsize <= 'b010; 
        hwdata <= '0; 
        hwstrb <= '0;
    endtask

    task automatic ahb_write(input [31:0] addr, 
                             input [31:0] data, 
                             input [3:0] strb = 4'hF);
        @(negedge hclk);
        hsel = 1'b1;
        haddr = addr; 
        htrans = NONSEQ; 
        hwrite = 1'b1;
        hsize = 3'b010; 
        hready = 1'b1; 
        hwdata = data; 
        hwstrb = strb;

        forever begin
            @(negedge hclk);
            if (hreadyout) begin
                drive_idle();
                break;
            end
        end
        @(posedge hclk);
    endtask

    task automatic ahb_read(input [31:0] addr, 
                            output [31:0] rdata, 
                            output logic resp_err);
        @(negedge hclk);
        hsel = 'b1; 
        haddr = addr; 
        htrans = NONSEQ; 
        hwrite = 'b0;
        hsize = 'b010; 
        hready = 'b1;

        forever begin
            @(negedge hclk);
            if (hreadyout) begin
                rdata    = hrdata;
                resp_err = hresp;
                drive_idle();
                break;
            end
        end
        @(posedge hclk);
    endtask

    task automatic reset_dut();
        hrst_n = 'b0;
        hsel = 'b0; 
        haddr = 'b0; 
        htrans = IDLE; 
        hwrite = 'b0;
        hsize = 'b010; 
        hprot = 'b0; 
        hready = 'b1;
        hwdata = 'b0; 
        hwstrb = 'b0;
        reset_slaves();
        repeat (3) 
            @(posedge hclk);
        hrst_n = 1'b1;
        @(posedge hclk);
    endtask
    
//=================================================================================//    
//=================================================================================// 
    
//=================================== Slave 0 Test ================================//    
//=================================================================================// 
    
    logic [31:0] rdata;
    logic         rresp;

    task automatic test_write_read_slave0();
        $display("--- test_write_read_slave0 ---");
        ahb_write(32'h0000_0010, 32'hDEAD_BEEF);
        check("no error on write", hresp, 1'b0);

        slave_rdata[0] = 32'hDEAD_BEEF;
        ahb_read(32'h0000_0010, rdata, rresp);
        check32("read back matches", rdata, 32'hDEAD_BEEF);
        check("no error on read", rresp, 1'b0);
    endtask
    
//=================================================================================//    
//=================================================================================// 
    
//=================================== Slave 1 Test ================================//    
//=================================================================================// 

    task automatic test_wait_states_slave1();
        $display("--- test_wait_states_slave1 ---");
        slave_wait_cycles[1] = 4'd3;
        ahb_read(32'h1000_0004, rdata, rresp);
        check32("read from slave1 correct despite wait states", rdata, slave_rdata[1]);
        check("no error", rresp, 1'b0);
        slave_wait_cycles[1] = 4'd0;
    endtask
    
//=================================================================================//    
//=================================================================================// 
    
//================================== Address Error ================================//    
//=================================================================================// 

    task automatic test_decode_error();
        $display("--- test_decode_error ---");
        ahb_read(32'h5000_0000, rdata, rresp);
        check("HRESP asserted on unmapped address", rresp, 1'b1);
        check("no PSEL asserted during decode error", |psel, 1'b0);
    endtask
    
//=================================================================================//    
//=================================================================================// 
    
//=================================== APB SLVERR ==================================//    
//=================================================================================// 

    task automatic test_apb_slave_error();
        $display("--- test_apb_slave_error ---");
        slave_force_err[2] = 1'b1;
        ahb_write(32'h2000_0000, 32'h1234_5678); 
        check("HRESP asserted on PSLVERR", hresp, 1'b1);
        slave_force_err[2] = 1'b0;
    endtask
    
//=================================================================================//    
//=================================================================================// 
    
//================================= Watch-Dog TImer ===============================//    
//=================================================================================// 

   task automatic test_watchdog_timeout();
        $display("--- test_watchdog_timeout ---");
        slave_never_ready[3] = 1'b1;
        ahb_read(32'h3000_0000, rdata, rresp);
        check("HRESP asserted on watchdog timeout", rresp, 1'b1);
        slave_never_ready[3] = 1'b0;
    endtask
    
//=================================================================================//    
//=================================================================================// 
    
//==================================== Sequence ===================================//    
//=================================================================================// 

   initial begin
        reset_dut();

        test_write_read_slave0();
        test_wait_states_slave1();
        test_decode_error();
        test_apb_slave_error();
        test_watchdog_timeout();

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
