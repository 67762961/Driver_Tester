`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company:   CRRC
// Engineer:		Du Chengzhi 20241385
//
// Create Date:   
// Design Name:     
// Module Name:  
// Project Name:    
// Target Device:  
// Tool versions:   Quartus II 13.1
// Description:		
//      连续脉冲的驱动能力测试
// Dependencies:
// 
// Revision:
//      1.0.0


module  Driver_Tester(
     clk,rst_n,
		ckey0,ckey1,ckey2,ckey3,
		led_d0,led_d1,led_d2,led_d3,
		led_d4,led_d5,led_d6,led_d7,
		sled_d0,
		sled_Dig,
		PWMO1,PWMO2
     );

input   clk;							// 时钟
input   rst_n;							// 复位信号 低电平有效
input   ckey0,ckey1,ckey2,ckey3;		// 四路拨码开关
		
output  led_d0,led_d1,led_d2,led_d3,	// Led控制信号
		led_d4,led_d5,led_d6,led_d7;
output	[6:0]	sled_d0;				// 数码管输出
output  [1:0]	sled_Dig;				// 段码输出
output	PWMO1,PWMO2;					// 六路pwm波输出


//---------------------------------------------------------------------------
// 慢时钟五分频
wire		Clk_5;       // 慢时钟 5分频
reg  [2:0]	Cnt_po_Clk;					// 分频计数器
reg  [2:0]	Cnt_ne_Clk;					// 分频计数器
reg			Clk_5_ne;
reg			Clk_5_po;

always @ ( posedge clk or negedge rst_n ) begin
	if (!rst_n) begin
		Cnt_po_Clk <= 0;
	end
	else begin
		if (Cnt_po_Clk == 3'b100)
			Cnt_po_Clk <= 3'b000;
		else
			Cnt_po_Clk <= Cnt_po_Clk + 3'd1;
	end
end
always @ ( negedge clk or negedge rst_n ) begin
	if (!rst_n) begin
		Cnt_ne_Clk <= 0;
	end
	else begin
		if (Cnt_ne_Clk == 3'b100)
			Cnt_ne_Clk <= 3'b000;
		else
			Cnt_ne_Clk <= Cnt_ne_Clk + 3'd1;
	end
end
always @ ( posedge clk or negedge rst_n ) begin
	if (!rst_n) begin
		Clk_5_po <= 0;
	end
	else begin
		if (Cnt_po_Clk > 3'b010)
			Clk_5_po <= 1'b1;
		else
			Clk_5_po <= 1'b0;
	end
end
always @ ( negedge clk or negedge rst_n ) begin
	if (!rst_n) begin
		Clk_5_ne <= 0;
	end
	else begin
		if (Cnt_ne_Clk > 3'b010)
			Clk_5_ne <= 1'b1;
		else
			Clk_5_ne <= 1'b0;
	end
end
assign Clk_5 = Clk_5_po | Clk_5_ne;


//---------------------------------------------------------------------------
// 拨码开关检测与模式指示灯控制块
reg		[7:0]		Led_d;				// 与八路Led直接相连
reg		[3:0]		mode;				// 模式寄存器

// 拨码开关检测与模式指示灯控制
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		mode <= 4'b0;
		Led_d[7:4] <= 4'b1111;
	end
	else begin 
		mode <= {ckey3,ckey2,ckey1,ckey0};
		Led_d[7:4] <= ~mode;
		Led_d[3:0] <= mode;
	end
end

//---------------------------------------------------------------------------
// 数码管输出块
reg	[6:0]	sLed_D0; //数码管输出寄存器
reg [3:0]	sLed_data0; // 数码管数据个位寄存器
reg	[4:0]	sLed_flag;	
reg	[1:0]	sLed_DIG;
reg	[9:0]	sLed_DATA;

always @ (posedge Clk_5 or negedge rst_n) begin
	if (!rst_n)
		sLed_flag <= 5'b0;
	else begin
		sLed_flag = sLed_flag + 1'b1;
		if((4'b0000 <= sLed_flag) && (sLed_flag <= 4'b0100)) begin
			sLed_DIG <= 2'b10;
			sLed_data0 <= sLed_DATA[3:0];
		end
		else if((4'b1000 <= sLed_flag) && (sLed_flag <= 4'b1100)) begin
			sLed_DIG <= 2'b01;
			sLed_data0 <= sLed_DATA[7:4];
		end
		else begin
			sLed_DIG <= 2'b11;
			sLed_data0 <= 4'hf;
		end

		case (sLed_data0)
			4'h0 : sLed_D0[6:0] <= 7'h40; //显示"0"
			4'h1 : sLed_D0[6:0] <= 7'h79; //显示"1"
			4'h2 : sLed_D0[6:0] <= 7'h24; //显示"2"
			4'h3 : sLed_D0[6:0] <= 7'h30; //显示"3"
			4'h4 : sLed_D0[6:0] <= 7'h19; //显示"4"
			4'h5 : sLed_D0[6:0] <= 7'h12; //显示"5"
			4'h6 : sLed_D0[6:0] <= 7'h02; //显示"6"
			4'h7 : sLed_D0[6:0] <= 7'h78; //显示"7"
			4'h8 : sLed_D0[6:0] <= 7'h00; //显示"8"
			4'h9 : sLed_D0[6:0] <= 7'h10; //显示"9"
		endcase
	end
end

//---------------------------------------------------------------------------
// 变化量初始化块
reg 	[11:0]		CNT_MAX;

// 计时器最大值根据拨码切换
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		sLed_DATA <= 8'd0;
	end
	else begin 
		case( mode )
			4'b0001: begin // 60kHz
				sLed_DATA <= 8'h60;
				CNT_MAX<=12'd166;
			end
			4'b0010: begin // 32kHz
				sLed_DATA <= 8'h32;
				CNT_MAX<=12'd312;
			end
			4'b0100: begin // 24kHz
				sLed_DATA <= 8'h24;
				CNT_MAX<=12'd416;
			end
			4'b1000: begin // 16kHz
				sLed_DATA <= 8'h16;
				CNT_MAX<=12'd625;
			end
		endcase
	end
end
//---------------------------------------------------------------------------
// 发波信号计时器
reg		[11:0]   cnt2;

// 信号计时器
always @ (posedge Clk_5 or negedge rst_n) begin
    if (!rst_n)
		cnt2 <= 12'b0;
    else begin
		if(cnt2 < CNT_MAX/2)
			cnt2 <= cnt2 + 12'b1;
		else
			cnt2 <= 12'b0;
	end
end

reg			PWMO1;
reg			PWMO2;

// 计时器触发信号取反
always @ (posedge Clk_5 or negedge rst_n) begin
    if (!rst_n)begin
		PWMO1 <= 1'b0;
		PWMO2 <= 1'b1;
	end
	else begin
		if(cnt2==12'b0)begin
			PWMO1 <= ~PWMO1;
			PWMO2 <= ~PWMO2;
		end
	end
end


//---------------------------------------------------------------------------
// 输出脚连线	
	assign led_d7 = Led_d[7] ? 1'b1 : 1'b0;
	assign led_d6 = Led_d[6] ? 1'b1 : 1'b0;
	assign led_d5 = Led_d[5] ? 1'b1 : 1'b0;
	assign led_d4 = Led_d[4] ? 1'b1 : 1'b0;
	assign led_d3 = Led_d[3] ? 1'b1 : 1'b0;
	assign led_d2 = Led_d[2] ? 1'b1 : 1'b0;
	assign led_d1 = Led_d[1] ? 1'b1 : 1'b0;
	assign led_d0 = Led_d[0] ? 1'b1 : 1'b0;
	
	assign sled_d0 = sLed_D0;
	assign sled_Dig = sLed_DIG;

endmodule