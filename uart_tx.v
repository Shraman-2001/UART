`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.09.2025 23:10:11
// Design Name: 
// Module Name: uart_tx
// Project Name: 
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


module uart_tx #(
    parameter CLKS_PER_BIT = 434,  // 50MHz/115200 baud
    parameter DATA_WIDTH = 8
)(
    input  wire i_clk,
    input  wire i_rst_n,
    input  wire i_tx_dv,
    input  wire [DATA_WIDTH-1:0] i_tx_byte,
    output reg  o_tx_active,
    output reg  o_tx_serial,
    output reg  o_tx_done
);

    // State machine parameters
    localparam IDLE       = 3'b000;
    localparam START_BIT  = 3'b001;
    localparam DATA_BITS  = 3'b010;
    localparam STOP_BIT   = 3'b011;
    localparam CLEANUP    = 3'b100;
    
    // Internal signals
    reg [2:0] r_state;
    reg [13:0] r_clk_count;  // 14-bit counter for up to 125MHz
    reg [2:0] r_bit_index;
    reg [DATA_WIDTH-1:0] r_tx_data;
    
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_state     <= IDLE;
            r_clk_count <= 0;
            r_bit_index <= 0;
            r_tx_data   <= 0;
            o_tx_active <= 1'b0;
            o_tx_serial <= 1'b1;  // Idle high
            o_tx_done   <= 1'b0;
        end else begin
            case (r_state)
                IDLE: begin
                    o_tx_serial <= 1'b1;  // Line idle high
                    o_tx_done   <= 1'b0;
                    o_tx_active <= 1'b0;
                    r_clk_count <= 0;
                    r_bit_index <= 0;
                    
                    if (i_tx_dv == 1'b1) begin
                        r_tx_data   <= i_tx_byte;
                        o_tx_active <= 1'b1;
                        r_state     <= START_BIT;
                    end else begin
                        r_state <= IDLE;
                    end
                end
                
                START_BIT: begin
                    o_tx_serial <= 1'b0;  // Start bit
                    
                    if (r_clk_count < CLKS_PER_BIT-1) begin
                        r_clk_count <= r_clk_count + 1;
                    end else begin
                        r_clk_count <= 0;
                        r_state <= DATA_BITS;
                    end
                end
                
                DATA_BITS: begin
                    o_tx_serial <= r_tx_data[r_bit_index];
                    
                    if (r_clk_count < CLKS_PER_BIT-1) begin
                        r_clk_count <= r_clk_count + 1;
                    end else begin
                        r_clk_count <= 0;
                        
                        if (r_bit_index < DATA_WIDTH-1) begin
                            r_bit_index <= r_bit_index + 1;
                        end else begin
                            r_bit_index <= 0;
                            r_state <= STOP_BIT;
                        end
                    end
                end
                
                STOP_BIT: begin
                    o_tx_serial <= 1'b1;  // Stop bit
                    
                    if (r_clk_count < CLKS_PER_BIT-1) begin
                        r_clk_count <= r_clk_count + 1;
                    end else begin
                        o_tx_done   <= 1'b1;
                        o_tx_active <= 1'b0;
                        r_state     <= CLEANUP;
                    end
                end
                
                CLEANUP: begin
                    o_tx_done <= 1'b1;
                    r_state   <= IDLE;
                end
                
                default: r_state <= IDLE;
            endcase
        end
    end
endmodule