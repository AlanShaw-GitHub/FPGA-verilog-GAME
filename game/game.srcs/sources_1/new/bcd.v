`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/12/23 19:15:00
// Design Name: 
// Module Name: top
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


module bcd(
    input [11:0] in,
    output [15:0] out 
    );
    
    wire [11:0]split1 =in;
    wire [11:0]split2 = in/10;
    wire [11:0]split3 = in/100;
    wire [11:0]split4 = in/1000;

    assign out[3:0] = (split1[3:0] > 12'd9 )? 9: split1[3:0];
    assign out[7:4] = (split2[3:0] > 12'd9 )? 9: split2[3:0];
    assign out[11:8] = (split3[3:0] > 12'd9 )? 9: split3[3:0];
    assign out[15:12] = (split4[3:0] > 12'd9 )? 9: split4[3:0];
    
endmodule
