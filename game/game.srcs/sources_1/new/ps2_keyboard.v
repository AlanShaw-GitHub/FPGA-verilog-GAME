`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/12/24 21:30:59
// Design Name: 
// Module Name: ps2_keyboard
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


module ps2_keyboard (input clk, clrn, ps2_clk, ps2_data, rdn, 
            output [7:0] data, 
            output ready,
            output reg overflow // fifo overflow
            );
  reg [3:0] count;     // count ps2_data bits, internal signal, for test
  reg [9:0] buffer;     // ps2_data bits
  reg [7:0] fifo[7:0];   // data fifo
  reg [2:0] w_ptr, r_ptr;  // fifo write and read pointers
  reg [2:0] ps2_clk_sync;

  always @ (posedge clk) begin
    ps2_clk_sync <= {ps2_clk_sync[1:0],ps2_clk};
  end
  wire sampling = ps2_clk_sync[2] & ~ps2_clk_sync[1];
  always @ (posedge clk) begin
    if (clrn == 0) begin
        count <= 0;
        w_ptr <= 0;
        r_ptr <= 0;
        overflow <= 0;
    end else if (sampling) begin
        if (count == 4'd10) begin
            if ((buffer[0] == 0) &&   // start bit
               (ps2_data) &&     // stop bit
               (~buffer[9:1])) begin   // 
                   fifo[w_ptr] <= buffer[8:1];   // kbd scan code
                   w_ptr <= w_ptr + 3'b1;
                   overflow <= overflow |  (r_ptr == (w_ptr + 3'b1));
                          end  
                   count <= 0; // for next
            end else begin
                   buffer[count] <= ps2_data;   // store ps2_data
                   count <= count + 3'b1;   // count ps2_data bits
            end
        end
        if (!rdn && ready) begin
          r_ptr <= r_ptr + 3'b1;
          overflow <= 0;
        end
   end
assign ready = (w_ptr != r_ptr);
assign data = fifo[r_ptr];
endmodule

