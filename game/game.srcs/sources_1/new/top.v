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


module top(
input wire clk_i,rstn_i,
input btnc_i,//游戏重新开始
input [3:0] sw_i,//速度选择开关  开始/暂停游戏开关
input miso,//加速度传感器引脚
output mosi,ss,sclk,//加速度传感器引脚
output [6:0] disp_seg_o,//七段数码管显示
output [7:0] disp_an_o,//七段数码管enable
output [3:0] vga_red_o,vga_green_o,vga_blue_o,//vga信号
output vga_hs_o,vga_vs_o,//vga信号
output [15:0] led_o//led灯 用于展示此时的加速度值的正负
    );
    reg [31:0] clkdiv;
    wire [11:0] xaxi;//x轴加速度（补码）
    wire [11:0] yaxi;//y轴加速度（补码）
    wire [11:0] zaxi;
    wire [11:0] temp;
    wire [11:0] x_axi;//x轴加速度（原码）
    wire [11:0] y_axi;//y轴加速度（原码）
    wire [11:0] easy_location,normal_location,hard_location;//显示屏右侧指示当前难度的rom的地址
    wire [11:0] easy_data,normal_data,hard_data;//显示屏右侧指示当前难度的rom的数据
    wire ready;//加速度传感器ready信号
    wire [9:0] y; // horizontal count
    wire [8:0] x; // vertical count
    reg [18:0] location_reg1;//关于主显示图案的计算出的地址
    reg [18:0] location_reg2;//关于小球一个测量点的计算出的地址
    reg [18:0] location_reg3;//关于小球另一个测量点的计算出的地址
    wire [15:0] data1;//与下面两个都为加速度传感器的值
    wire [15:0] data2;
    reg [11:0] data;
    wire [11:0] main_data;//主显示图案的data，下面类似
    wire [11:0] wall_data;
    wire [11:0] defence_data;
    wire [11:0] boll_data;
    wire [18:0] boll_location;
    reg [9:0] position_y;//小球位置坐标
    reg [8:0] position_x;
    reg over;
    wire enable;
    reg status;
    reg [31:0] count;
    reg [1:0] roll;
    reg [1:0] choice;//1:easy,2:normal,3:hard
    reg [2:0] speed_x,speed_y;//速度值
    reg win;
    wire [11:0] over_data,win_data;//胜利、失败图案相关
    wire [13:0] over_location,win_location;

    initial begin//初始化
      speed_x = 1;
      speed_y = 1;
      roll = 0;
      over = 0;
      status = 0;
      count = 0;
      choice = 2'd01;
      position_y = 10'd200;
      position_x = 9'd32;
    end    
    //在七段数码管显示实时的加速度值
    assign x_axi[11:0] = (xaxi[11] == 0)? xaxi : {1'b0,~xaxi[10:0]+10'd1};
    assign y_axi[11:0] = (yaxi[11] == 0)? yaxi : {1'b0,~yaxi[10:0]+10'd1};
    assign led_o[7:0] = {xaxi[11],xaxi[11],xaxi[11],xaxi[11],xaxi[11],xaxi[11],xaxi[11],xaxi[11]};
    assign led_o[15:8] = {~yaxi[11],~yaxi[11],~yaxi[11],~yaxi[11],~yaxi[11],~yaxi[11],~yaxi[11],~yaxi[11]};
    //计算当前小球运动速度
    always@* begin
        if(x_axi < 11'd250)
            speed_x = 3'd1;
        else if(x_axi >= 11'd250 && x_axi < 11'd500)
            speed_x = 3'd2;
        else 
            speed_x = 3'd3;
            
        if(y_axi < 11'd250)
                speed_y = 3'd1;
            else if(y_axi >= 11'd250 && y_axi < 11'd500)
                speed_y = 3'd2;
            else 
                speed_y = 3'd3;

    end
    //难度选择模块
    always@*begin
        if(sw_i[1] == 1)
            choice = 2'b01;
        else if(sw_i[2] == 1)
            choice = 2'b10;
        else if(sw_i[3] == 1)
            choice = 2'b11;                    
    end

    //七段数码管、bcd转换模块
    bcd bcd1(.in(x_axi),.out(data1));
    bcd bcd2(.in(y_axi),.out(data2));
    dispnumber disp(.x({data1,data2}),.clk(clk_i),.clr(rstn_i),.a_to_g(disp_seg_o),.an(disp_an_o[7:0]));
    
    vgac main(.vga_clk(clkdiv[1]),.clrn(rstn_i),.d_in(data),.row_addr(x),.col_addr(y),.rdn(enable),.r(vga_red_o),.g(vga_green_o),.b(vga_blue_o),.hs(vga_hs_o),.vs(vga_vs_o));
   

    //四个图片rom
    blk_mem_gen_0 mainwindow(.clka(clk_i),.ena(1'b1),.addra(status ? location_reg2 : location_reg1),.douta(main_data),.clkb(clk_i),.enb(1'b1),.addrb(location_reg3),.doutb(wall_data) );
    blk_mem_gen_1 boll(.clka(clk_i),.ena(1'b1),.addra(boll_location[9:0]),.douta(boll_data));
    blk_mem_gen_2 overgame(.clka(clk_i),.ena(1'b1),.addra(over_location),.douta(over_data));
    blk_mem_gen_3 wingame(.clka(clk_i),.ena(1'b1),.addra(win_location),.douta(win_data));
    //计数器，作为小球运动的触发时钟
    always@(posedge clkdiv[1])begin
        if(count < 100000)begin
            count <= count+1;
            status <= 0;
        end
        if(count >= 100000)begin
            count <= 0;
            status <= 1;
        end
    end
    reg [2:0] divide;
    //总的速度值
    wire [3:0] total_speed_x = speed_x + choice;
    wire [3:0] total_speed_y = speed_y + choice;
    wire [3:0] total_speed = (total_speed_x + total_speed_y)/2;
    //小球运动的时序模块
    always@(negedge status)begin
        if(btnc_i == 1)begin
            position_y <= 10'd200;
            position_x <= 9'd32;
        end

        if(divide == 3'b101)
            divide <= 0;
        else
            divide <= divide+1'b1;

        if(roll == 2'b10)
            roll <= 0;
        else
            roll <= roll+1'b1;
            
    win <= ( position_y > 534 && position_y < 569 && position_x < 204 && position_x > 171 && btnc_i == 0) ? 1 : 0;
    if(divide == 3'b000)begin        
        if(xaxi[11] == 1'b1 && roll == 2'b00 && ~over && ~win && sw_i[0] == 1'b1)begin
            position_x <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_x : position_x - 1;
        end
        if(xaxi[11] == 1'b0 && roll == 2'b00 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_x <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_x : position_x + 1;
        end
        if(yaxi[11] == 1'b1 && roll == 2'b01 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_y <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_y : position_y + 1;
        end
        if(yaxi[11] == 1'b0 && roll == 2'b01 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_y <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_y : position_y - 1;
        end
        if(roll == 2'b10)begin
            over <= (main_data == 12'h000 &&  btnc_i == 0) ? 1 : 0;
        end
    end
    else if(divide == 3'b001 && total_speed != 4'b0001)begin   
        if(xaxi[11] == 1'b1 && roll == 2'b00 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_x <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_x : position_x - 1;
        end
        if(xaxi[11] == 1'b0 && roll == 2'b00 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_x <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_x : position_x + 1;
        end
        if(yaxi[11] == 1'b1 && roll == 2'b01 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_y <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_y : position_y + 1;
        end
        if(yaxi[11] == 1'b0 && roll == 2'b01 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_y <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_y : position_y - 1;
        end
        if(roll == 2'b10)begin
            over <= (main_data == 12'h000 &&  btnc_i == 0) ? 1 : 0;
        end
    end
    else if(divide == 3'b010 && total_speed != 4'b0010 && total_speed != 4'b0001)begin
        if(xaxi[11] == 1'b1 && roll == 2'b00 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_x <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_x : position_x - 1;
        end
        if(xaxi[11] == 1'b0 && roll == 2'b00 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_x <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_x : position_x + 1;
        end
        if(yaxi[11] == 1'b1 && roll == 2'b01 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_y <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_y : position_y + 1;
        end
        if(yaxi[11] == 1'b0 && roll == 2'b01 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_y <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_y : position_y - 1;
        end
        if(roll == 2'b10)begin
            over <= (main_data == 12'h000 &&  btnc_i == 0) ? 1 : 0;
        end
    end    
    else if(divide == 3'b011 && total_speed != 4'b0001 && total_speed != 4'b0010 && total_speed != 4'b0011)begin
        if(xaxi[11] == 1'b1 && roll == 2'b00 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_x <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_x : position_x - 1;
        end
        if(xaxi[11] == 1'b0 && roll == 2'b00 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_x <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_x : position_x + 1;
        end
        if(yaxi[11] == 1'b1 && roll == 2'b01 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_y <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_y : position_y + 1;
        end
        if(yaxi[11] == 1'b0 && roll == 2'b01 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_y <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_y : position_y - 1;
        end
        if(roll == 2'b10)begin
            over <= (main_data == 12'h000 &&  btnc_i == 0) ? 1 : 0;
        end
    end
    else if(divide == 3'b100 && (total_speed == 4'b0110 || total_speed == 4'b0101))begin
        if(xaxi[11] == 1'b1 && roll == 2'b00 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_x <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_x : position_x - 1;
        end
        if(xaxi[11] == 1'b0 && roll == 2'b00 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_x <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_x : position_x + 1;
        end
        if(yaxi[11] == 1'b1 && roll == 2'b01 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_y <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_y : position_y + 1;
        end
        if(yaxi[11] == 1'b0 && roll == 2'b01 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_y <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_y : position_y - 1;
        end
        if(roll == 2'b10)begin
            over <= (main_data == 12'h000 &&  btnc_i == 0) ? 1 : 0;
        end
    end
    else if(divide == 3'b101 && total_speed == 4'b0110)begin
        if(xaxi[11] == 1'b1 && roll == 2'b00 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_x <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_x : position_x - 1;
        end
        if(xaxi[11] == 1'b0 && roll == 2'b00 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_x <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_x : position_x + 1;
        end
        if(yaxi[11] == 1'b1 && roll == 2'b01 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_y <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_y : position_y + 1;
        end
        if(yaxi[11] == 1'b0 && roll == 2'b01 && ~over && ~win  && sw_i[0] == 1'b1)begin
            position_y <= (main_data[7:4] == 4'b1100 || wall_data[7:4] == 4'b1100) ? position_y : position_y - 1;
        end
        if(roll == 2'b10)begin
            over <= (main_data == 12'h000 &&  btnc_i == 0) ? 1 : 0;
        end
    end
     
    end
    
    
    //传给rom的地址计算
    always@*begin
        if(xaxi[11] == 1'b1 && roll == 2'b00)begin
            location_reg2 = (position_x - 9'd15)*10'd640+position_y+10'd12;
            location_reg3 = (position_x - 9'd15)*10'd640+position_y-10'd12;
        end
        if(xaxi[11] == 1'b0 && roll == 2'b00)begin
            location_reg2 = (position_x + 9'd15)*10'd640+position_y+10'd12;
            location_reg3 = (position_x + 9'd15)*10'd640+position_y-10'd12;
        end
        if(yaxi[11] == 1'b1 && roll == 2'b01)begin
            location_reg2 = (position_x + 9'd12)*10'd640+position_y+10'd15;
            location_reg3 = (position_x - 9'd12)*10'd640+position_y+10'd15;
        end
        if(yaxi[11] == 1'b0 && roll == 2'b01)begin
            location_reg2 = (position_x + 9'd12)*10'd640+position_y-10'd15;
            location_reg3 = (position_x - 9'd12)*10'd640+position_y-10'd15;
        end
        if(roll == 2'b10)begin
            location_reg2 = position_x*10'd640+position_y;
        end
    end
    
    wire [9:0] diff_y;
    wire [8:0] diff_x;
    assign diff_x = 15 + x - position_x;
    assign diff_y = 15 + y - position_y;
    assign boll_location = diff_x*30 + diff_y;
    
    assign easy_location = (x-160)*60 + y-580;
    assign normal_location = (x-220)*60 + y-580;
    assign hard_location = (x-290)*60 + y-580;
    
    //三个显示难易程度字符的地址的计算
    basic_rom basic(.clka(clk_i),.ena(1'b1),.addra(easy_location),.douta(easy_data));
    normal_rom normal(.clka(clk_i),.ena(1'b1),.addra(normal_location),.douta(normal_data));
    hard_rom hard(.clka(clk_i),.ena(1'b1),.addra(hard_location),.douta(hard_data));
    assign win_location = (x - 190)*100 + y - 270;
    assign over_location = (x - 210)*150 + y - 245;
    
    //vga输入data的值的计算
    always@*begin
      location_reg1 = x*10'd640+y;
      if(over == 1 && x >= 210 && x < 270 && y >= 245  && y < 395)
          data = (over_data == 12'hfff) ? 12'hf00 : main_data;
      else if(win == 1 && x >= 190 && x < 290 && y >= 270 && y < 370)
          data = (win_data == 12'h000) ? main_data : win_data;
      else if((x >= position_x-15 && x < position_x+15) && (y >= position_y-15 && y < position_y+15))
          data = (boll_data == 12'h000) ? main_data : boll_data;
      else if(y > 580)begin
          if(x >= 160 && x < 200)
              data = easy_data == 12'hfff ? 12'hfff : (choice == 2'b01 ? 12'hf00 : 12'h000);
          else if(x >= 220 && x < 260)   
              data = normal_data == 12'hfff ? 12'hfff : (choice == 2'b10 ? 12'hf00 : 12'h000);
          else if(x >= 290 && x < 330) 
              data = hard_data == 12'hfff ? 12'hfff : (choice == 2'b11 ? 12'hf00 : 12'h000);
          else
              data = main_data;
      end
      else
          data = main_data;  

    end

    //adxl362加速度传感器调用模块
    ADXL362Ctrl #(.SYSCLK_FREQUENCY_HZ(100000000),
           .SCLK_FREQUENCY_HZ( 1000000),
           .NUM_READS_AVG(16),
           .UPDATE_FREQUENCY_HZ(1000)) 
           acceleration( .SYSCLK(clk_i),
                 .RESET(~rstn_i),
                 .ACCEL_X(xaxi),
                 .ACCEL_Y(yaxi),
                 .ACCEL_Z(zaxi),
                 .ACCEL_TMP(temp),
                 .Data_Ready(ready),
                 .SCLK(sclk),
                 .MOSI(mosi),
                 .MISO(miso),
                 .SS(ss));
    //时钟分频模块
    always @(posedge clk_i or negedge rstn_i)
                 begin
                     if(rstn_i == 0)
                         clkdiv <= 0;
                     else
                         clkdiv <= clkdiv + 1'b1;
    end 
    
    
endmodule
