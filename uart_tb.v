`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.09.2025 23:50:15
// Design Name: 
// Module Name: uart_tb
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


module uart_tb();
    
    localparam CLK_PERIOD = 20;  // 50MHz clock
    localparam CLKS_PER_BIT = 434;
    localparam BIT_PERIOD = CLK_PERIOD * CLKS_PER_BIT;
    
    reg clk = 0;
    reg rst_n = 0;
    reg [7:0] tx_data;
    reg tx_valid;
    wire tx_ready;
    wire [7:0] rx_data;
    wire rx_valid;
    reg rx_ready;
    wire uart_line;
    integer i;
    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;
    
    // DUT instantiation
    uart_top #(
        .CLK_FREQ(50_000_000),
        .BAUD_RATE(115200)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx(uart_line),
        .uart_tx(uart_line),  // Loopback
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_ready(rx_ready)
    );
    
    // Test sequence
    initial begin
        // Reset sequence
        rst_n = 0;
        tx_valid = 0;
        rx_ready = 1;
        #(CLK_PERIOD * 10);
        rst_n = 1;
        #(CLK_PERIOD * 10);
        
        // Test data transmission
        for (i = 0; i < 256; i=i+1) begin
            @(posedge clk);
            if (tx_ready) begin
                tx_data = i;
                tx_valid = 1;
                @(posedge clk);
                tx_valid = 0;
                
                // Wait for reception
                wait(rx_valid);
                @(posedge clk);
                
                if (rx_data != i) begin
                    $error("Data mismatch: sent %h, received %h", i, rx_data);
                end else begin
                    $display("Test %d passed: %h", i, rx_data);
                end
            end
            #(BIT_PERIOD * 12); // Allow time for transmission
        end
        
        $display("All tests completed");
        $finish;
    end
    
endmodule