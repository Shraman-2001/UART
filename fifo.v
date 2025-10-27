`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.09.2025 23:25:14
// Design Name: 
// Module Name: fifo
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

module fifo #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16
)(
    input  wire clk,
    input  wire rst_n,
    input  wire wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    input  wire rd_en,
    output reg  [DATA_WIDTH-1:0] rd_data,
    output wire full,
    output wire empty
);

    // Use fixed address width instead of clog2
    localparam ADDR_WIDTH = 4;  // For FIFO_DEPTH = 16
    
    reg [DATA_WIDTH-1:0] memory [0:FIFO_DEPTH-1];
    reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;  // Extra bit for full/empty detection
    
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= {(ADDR_WIDTH+1){1'b0}};  // Proper initialization
            rd_ptr <= {(ADDR_WIDTH+1){1'b0}};  // Proper initialization
            rd_data <= {DATA_WIDTH{1'b0}};     // Initialize output
            
            // Initialize memory to prevent X propagation
            for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
                memory[i] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            // Write operation
            if (wr_en && !full) begin
                memory[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
                wr_ptr <= wr_ptr + 1;
            end
            
            // Read operation
            if (rd_en && !empty) begin
                rd_data <= memory[rd_ptr[ADDR_WIDTH-1:0]];
                rd_ptr <= rd_ptr + 1;
            end
        end
    end
    
    assign full = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) && 
                  (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);
    assign empty = (wr_ptr == rd_ptr);

endmodule