module dispnumber(
    input wire [31:0] x,
    input wire clk,clr,
    output reg [6:0] a_to_g,
    output reg[7:0] an
    //output wire dp
        );
    wire [2:0] s;
    reg [3:0] digit;
    wire [3:0] aen;
    reg [31:0] clkdiv;
    //assign dp = 1;
    assign s = clkdiv[20:18];
    assign aen = 8'b11111111;
    always @(*)
    case(s)
        0:digit = x[3:0];
        1:digit = x[7:4];
        2:digit = x[11:8];
        3:digit = x[15:12];
        4:digit = x[19:16];
        5:digit = x[23:20];
                  
        6:digit = x[27:24];
        7:digit = x[31:28];
        default:digit = x[3:0];
    endcase
    always @(*)
    case(digit)
        0:a_to_g = 7'b0000001;
        1:a_to_g = 7'b1001111;
        2:a_to_g = 7'b0010010;
        3:a_to_g = 7'b0000110;
        4:a_to_g = 7'b1001100;
        5:a_to_g = 7'b0100100;
        6:a_to_g = 7'b0100000;
        7:a_to_g = 7'b0001111;
        8:a_to_g = 7'b0000000;
        9:a_to_g = 7'b0000100;
        'hA:a_to_g = 7'b0001000;
        'hB:a_to_g = 7'b1100000;
        'hC:a_to_g = 7'b0110001;
        'hD:a_to_g = 7'b1000010;
        'hE:a_to_g = 7'b0110000;
        'hF:a_to_g = 7'b0111000;
        default:a_to_g = 7'b0000001;
    endcase
    
    always @(*)
    begin
        an = 8'b11111111;
        if(aen[s] == 1)
            an[s] = 0;
    end
    
    always @(posedge clk or negedge clr)
    begin
        if(clr == 0)
            clkdiv <= 0;
        else
            clkdiv <= clkdiv + 1'b1;
    end 
	 
endmodule
