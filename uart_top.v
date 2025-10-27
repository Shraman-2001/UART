`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.09.2025 23:19:37
// Design Name: 
// Module Name: uart_top
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


module uart_top #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 115200,
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16
)(
    input  wire clk,
    input  wire rst_n,
    
    // UART physical interface
    input  wire uart_rx,
    output wire uart_tx,
    
    // User interface - TX
    input  wire [DATA_WIDTH-1:0] tx_data,
    input  wire tx_valid,
    output wire tx_ready,
    
    // User interface - RX
    output wire [DATA_WIDTH-1:0] rx_data,
    output wire rx_valid,
    input  wire rx_ready,
    
    // Status
    output wire tx_active,
    output wire rx_error
);

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    
    // Internal connections - properly declared
    wire tx_dv_internal, tx_done_internal;
    wire rx_dv_internal;
    wire [DATA_WIDTH-1:0] tx_byte_internal, rx_byte_internal;
    
    // TX FIFO signals
    wire tx_fifo_full, tx_fifo_empty;
    wire tx_fifo_rd_en;
    
    // RX FIFO signals  
    wire rx_fifo_full, rx_fifo_empty;
    
    // TX FIFO
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) tx_fifo_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(tx_valid && !tx_fifo_full),
        .wr_data(tx_data),
        .rd_en(tx_fifo_rd_en),
        .rd_data(tx_byte_internal),
        .full(tx_fifo_full),
        .empty(tx_fifo_empty)
    );
    
    assign tx_ready = !tx_fifo_full;
    
    // TX control logic with proper initialization
    reg tx_state;
    localparam TX_IDLE = 1'b0, TX_ACTIVE = 1'b1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state <= TX_IDLE;
        end else begin
            case (tx_state)
                TX_IDLE: begin
                    if (!tx_fifo_empty) begin
                        tx_state <= TX_ACTIVE;
                    end
                end
                TX_ACTIVE: begin
                    if (tx_done_internal) begin
                        tx_state <= TX_IDLE;
                    end
                end
                default: tx_state <= TX_IDLE;
            endcase
        end
    end
    
    assign tx_fifo_rd_en = (tx_state == TX_IDLE) && !tx_fifo_empty;
    assign tx_dv_internal = tx_fifo_rd_en;
    
    // RX FIFO
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) rx_fifo_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(rx_dv_internal && !rx_fifo_full),
        .wr_data(rx_byte_internal),
        .rd_en(rx_ready && !rx_fifo_empty),
        .rd_data(rx_data),
        .full(rx_fifo_full),
        .empty(rx_fifo_empty)
    );
    
    assign rx_valid = !rx_fifo_empty;
    
    // UART TX instance
    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT),
        .DATA_WIDTH(DATA_WIDTH)
    ) uart_tx_inst (
        .i_clk(clk),
        .i_rst_n(rst_n),
        .i_tx_dv(tx_dv_internal),
        .i_tx_byte(tx_byte_internal),
        .o_tx_active(tx_active),
        .o_tx_serial(uart_tx),
        .o_tx_done(tx_done_internal)
    );
    
    // UART RX instance  
    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT),
        .DATA_WIDTH(DATA_WIDTH)
    ) uart_rx_inst (
        .i_clk(clk),
        .i_rst_n(rst_n),
        .i_rx_serial(uart_rx),
        .o_rx_dv(rx_dv_internal),
        .o_rx_byte(rx_byte_internal),
        .o_rx_error(rx_error)
    );

endmodule