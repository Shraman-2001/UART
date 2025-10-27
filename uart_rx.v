`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.09.2025 22:40:03
// Design Name: 
// Module Name: uart_rx
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


module uart_rx #(
    parameter CLKS_PER_BIT = 434,
    parameter DATA_WIDTH = 8
)(
    input  wire i_clk,
    input  wire i_rst_n,
    input  wire i_rx_serial,
    output reg  o_rx_dv,
    output reg  [DATA_WIDTH-1:0] o_rx_byte,
    output reg  o_rx_error
);

    // State machine parameters
    localparam IDLE       = 3'b000;
    localparam START_BIT  = 3'b001;
    localparam DATA_BITS  = 3'b010;
    localparam STOP_BIT   = 3'b011;
    localparam CLEANUP    = 3'b100;
    
    // Internal signals - ALL PROPERLY INITIALIZED
    reg [2:0] r_state;
    reg [13:0] r_clk_count;
    reg [2:0] r_bit_index;
    reg [DATA_WIDTH-1:0] r_rx_data;
    reg r_rx_data_r, r_rx_data_sync;
    
    // Input synchronization with proper initialization
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_rx_data_r    <= 1'b1;    // Initialize to idle high
            r_rx_data_sync <= 1'b1;    // Initialize to idle high
        end else begin
            r_rx_data_r    <= i_rx_serial;
            r_rx_data_sync <= r_rx_data_r;
        end
    end
    
    // Main state machine with complete initialization
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_state     <= IDLE;
            r_clk_count <= 14'b0;      // Explicit width
            r_bit_index <= 3'b0;       // Explicit width
            r_rx_data   <= {DATA_WIDTH{1'b0}};  // Initialize all bits
            o_rx_dv     <= 1'b0;
            o_rx_byte   <= {DATA_WIDTH{1'b0}};  // Initialize output
            o_rx_error  <= 1'b0;
        end else begin
            // Default assignments to prevent latches
            o_rx_dv <= 1'b0;  // Default to not valid
            
            case (r_state)
                IDLE: begin
                    r_clk_count <= 14'b0;
                    r_bit_index <= 3'b0;
                    o_rx_error  <= 1'b0;
                    
                    if (r_rx_data_sync == 1'b0) // Start bit detected
                        r_state <= START_BIT;
                    else
                        r_state <= IDLE;
                end
                
                START_BIT: begin
                    if (r_clk_count == (CLKS_PER_BIT-1)/2) begin
                        if (r_rx_data_sync == 1'b0) begin
                            r_clk_count <= 14'b0;
                            r_state <= DATA_BITS;
                        end else begin
                            r_state <= IDLE; // False start bit
                        end
                    end else begin
                        r_clk_count <= r_clk_count + 1;
                        r_state <= START_BIT;
                    end
                end
                
                DATA_BITS: begin
                    if (r_clk_count < CLKS_PER_BIT-1) begin
                        r_clk_count <= r_clk_count + 1;
                    end else begin
                        r_clk_count <= 14'b0;
                        r_rx_data[r_bit_index] <= r_rx_data_sync;
                        
                        if (r_bit_index < DATA_WIDTH-1) begin
                            r_bit_index <= r_bit_index + 1;
                        end else begin
                            r_bit_index <= 3'b0;
                            r_state <= STOP_BIT;
                        end
                    end
                end
                
                STOP_BIT: begin
                    if (r_clk_count < CLKS_PER_BIT-1) begin
                        r_clk_count <= r_clk_count + 1;
                    end else begin
                        r_clk_count <= 14'b0;
                        if (r_rx_data_sync == 1'b1) begin
                            o_rx_dv <= 1'b1;
                            o_rx_byte <= r_rx_data;
                            o_rx_error <= 1'b0;
                        end else begin
                            o_rx_error <= 1'b1; // Framing error
                            o_rx_byte <= {DATA_WIDTH{1'b0}}; // Clear on error
                        end
                        r_state <= CLEANUP;
                    end
                end
                
                CLEANUP: begin
                    r_state <= IDLE;
                end
                
                default: begin
                    r_state <= IDLE;
                    r_clk_count <= 14'b0;
                    r_bit_index <= 3'b0;
                    r_rx_data <= {DATA_WIDTH{1'b0}};
                end
            endcase
        end
    end
endmodule