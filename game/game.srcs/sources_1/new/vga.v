`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:35:19 12/16/2017 
// Design Name: 
// Module Name:    vga 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module vga(
  clk,clrn,d_in,rd_a,x,y,r,g,b,hs,vs
    );


input clk,clrn;
input [11:0] d_in;
output [18:0] rd_a;
output [8:0] y;
output [7:0] x;
output [3:0] r,g,b;
output hs,vs;
reg [9:0] h_count;
reg [9:0] v_count;

reg vga_clk;
reg [11:0] data_reg;
reg video_out;
wire rdn;
always@ (posedge clk or negedge clrn)begin
  if(clrn == 0)
    vga_clk <= 1'b1;
  else
    vga_clk <= ~vga_clk;
end

always@(posedge vga_clk or negedge clrn)begin
  if(clrn == 0 )
  h_count <= 10'h0;
  else if(h_count == 10'd799)
  h_count <= 10'h0;
  else
  h_count <= h_count+10'h1;
end

always@(posedge vga_clk or negedge clrn)begin
  if(clrn == 0)
  v_count <= 0;
  else if (h_count == 10'd799) begin
           if (v_count == 10'd524) begin
               v_count <= 10'h0;
           end else begin
               v_count <= v_count + 10'h1;
           end
       end
end

always@(posedge vga_clk or negedge clrn)begin
  if(clrn == 0)begin
    video_out <= 1'b0;
    data_reg <= 12'h0;
  end
  else begin
    video_out<= ~rdn;
    data_reg <= d_in;
  end
end

assign rdn = ~(((h_count >= 10'd143) && (h_count < 10'd783)) && 
                ((v_count >= 10'd35) && (v_count < 10'd515)));

wire [18:0] row = v_count - 10'd35;
wire [18:0] col = h_count - 10'd143;
assign rd_a = (row-1)* 18'd640+col;
assign hs = (h_count >= 10'd96);
assign vs = (v_count >= 10'd2);
assign r = (video_out) ? data_reg[11:8] : 4'h0;
assign g = (video_out) ? data_reg[7:4] : 4'h0;
assign b = (video_out) ? data_reg[3:0] : 4'h0;
assign y = col[8:0];
assign x = row[7:0];

endmodule
