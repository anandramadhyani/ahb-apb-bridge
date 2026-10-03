`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ananda Thirtha
// 
// Create Date: 29.09.2026 14:08:40
// Design Name: Control FSM Design
// Module Name: control_fsm
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


module control_fsm (
    input logic hclk,
    input logic hrst_n,
    
    input logic ahb_addr_valid,
    input logic size_err,
    
    input logic timeout_expired,
    
    //input logic [3 : 0] selected_slave,
    input logic addr_err,
        
    input logic apb_ready,
    input logic apb_error,
    
    output logic fsm_tx_ready,
    output logic fsm_tx_error,
    
    output logic apb_start,
    output logic apb_penable_en,      
    
    output logic start,
    output logic stop
    );
    
    typedef enum logic [2 : 0]{
        IDLE,
        SETUP,
        ACCESS,
        ERR1,
        ERR2
    } state_t;
    
    state_t state, next_state;
    
    always_ff @(posedge hclk or negedge hrst_n) begin
        if (!hrst_n) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end
    
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (ahb_addr_valid) begin
                    next_state = SETUP;
                end
            end
            
            SETUP: begin
                if (addr_err || size_err) begin
                    next_state = ERR1;
                end
                else begin
                    next_state = ACCESS;
                end
            end
            
            ACCESS: begin
                if (apb_ready) begin
                    if (apb_error) begin
                        next_state = ERR1;
                    end
                    else begin
                        next_state = ahb_addr_valid ? SETUP : IDLE;
                    end
                end
                else if (timeout_expired) begin
                    next_state = ERR1;
                end
            end
            
            ERR1: begin
                next_state = ERR2;
            end
            
            ERR2: begin
                next_state = ahb_addr_valid ? SETUP : IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    always_comb begin
        fsm_tx_ready = 'b0;
        fsm_tx_error = 'b0;
        apb_start = 'b0;
        apb_penable_en = 'b0;
        start = 'b0;
        stop = 'b0;
        case (state)
            IDLE: begin
                fsm_tx_ready = 'b1;
            end
            
            SETUP: begin
               if (!(addr_err || size_err)) begin
                   apb_start  = 'b1;
               end
            end
            
            ACCESS: begin
                apb_penable_en = 'b1;
                start = 'b1;
                if (apb_ready) begin
                    stop = 'b1;
                    if (!apb_error) begin
                        fsm_tx_ready = 'b1;
                    end
                end
                else if (timeout_expired) begin
                    stop = 'b1;
                end
            end
            
            ERR1: begin
                fsm_tx_ready = 'b0;
                fsm_tx_error = 'b1;
            end
            
            ERR2: begin
                fsm_tx_ready = 'b1;
                fsm_tx_error = 'b1;
            end
            
            default: begin
            
            end
        endcase
    end
    
endmodule
