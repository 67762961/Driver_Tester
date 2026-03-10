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
		sw0_n,sw1_n,sw2_n,
		sw3_n,sw4_n,sw5_n,
		led_d0,led_d1,led_d2,led_d3,
		led_d4,led_d5,led_d6,led_d7,
		sled_d0,
		sled_Dig,
		PWMO1,PWMO2
     );

input   clk;							// 时钟
input   rst_n;							// 复位信号 低电平有效
input   ckey0,ckey1,ckey2,ckey3,		// 四路拨码开关
		sw0_n,sw1_n,sw2_n,
		sw3_n,sw4_n,sw5_n;
		
output  led_d0,led_d1,led_d2,led_d3,	// Led控制信号
		led_d4,led_d5,led_d6,led_d7;
output	[7:0]	sled_d0;				// 数码管输出
output  [3:0]	sled_Dig;				// 段码输出
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
// 按键信号读取块
// 读取按键六位按键的信号

reg		[5:0]  key_rst;  
reg		[5:0]  key_rst_r;          // 按键打一拍后状态寄存器

// 每次时钟上升沿时将按键状态传入 key_rst 按键状态寄存器
// 并打一拍到 key_rst_r
always @ ( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		key_rst_r <= 6'b11_1111;
		key_rst <= 6'b11_1111;
	end
    else begin
		key_rst_r <= key_rst;
		key_rst <= {sw5_n,sw4_n,sw3_n,sw2_n,sw1_n,sw0_n};
	end
end

// 检测 key_rst 的下降沿
// 即当 按键按下 key_an 将产生一个单周期脉冲
wire[5:0] key_an = key_rst_r & ( ~key_rst);

//---------------------------------------------------------------------------
// 消抖计时器 若时钟不分频填制F_FFFF 五分频填3_3333
reg		[17:0]  cnt;						// 18位宽的计数器 用于按键消抖
always @ (posedge Clk_5 or negedge rst_n)
	if (!rst_n)
		cnt <= 18'h3_3333;            // 复位时计数器清零
	else if (key_an)
		cnt <= 18'h3_3333;            // 只要有一个按键脉冲计数器清零
	else
		if(cnt == 18'd0)
			cnt <= 18'h3_3333;  
		else
			cnt <= cnt - 18'b1;       // 计数器每个时钟周期-1

reg	[5:0]  low_sw;
reg	[5:0]  low_sw_r;

//---------------------------------------------------------------------------
// 消抖后按键状态检测

// 计数器满时锁存按键到low_sw 
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		low_sw <= 6'b11_1111;
	end
	else if (cnt == 19'h0) begin
		low_sw <= {sw5_n,sw4_n,sw3_n,sw2_n,sw1_n,sw0_n};
	end
	else
		low_sw <= low_sw;
end

// 锁存的 low_sw 打一拍
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		low_sw_r <= 6'b11_1111;
	else
		low_sw_r <= low_sw;
end

// 检测 low_sw 的下降沿
// 即当 计数器满 led_ctrl 将产生一个单周期脉冲
wire[5:0] led_ctrl = low_sw_r[5:0] & ( ~low_sw[5:0]);

reg		[2:0]		state_0;
reg		[2:0]		state_1;
reg					neg_0;
reg					neg_1;


// 按键控制 发波信号发出与变化量加减
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		state_0 <= 3'b0;
		state_1 <= 3'b0;
		neg_0 <= 1'b0;
		neg_1 <= 1'b0;
		
	end
	else begin 
		case (led_ctrl)
			6'b00_0001:// 右下按键 通道2反向
				neg_1 <= ~neg_1;
			6'b00_1000:// 右上按键 通道1反向
				neg_0 <= ~neg_0;
			6'b01_0000:begin// 第1排 中 通道1模式加
				if (state_0 == 3'd4)
					state_0 <= 3'b0;
				else
					state_0 = state_0 + 3'b1;
			end
			6'b10_0000:begin// 第1排 左 通道1模式减
				if (state_0 == 3'd0)
					state_0 <= 3'd4;
				else
					state_0 = state_0 - 3'b1;
			end
			6'b00_0010:begin// 第2排 中 通道2模式加
				if (state_1 == 3'd4)
					state_1 <= 3'b0;
				else
					state_1 = state_1 + 3'b1;
			end
			6'b00_0100:begin// 第2排 左 通道2模式减
				if (state_1 == 3'd0)
					state_1 <= 3'd4;
				else
					state_1 = state_1 - 3'b1;
			end
			default:
				;
		endcase
	end
end

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
reg [3:0]	sLed_data0; // 数码管数据个位寄存器
reg	[4:0]	sLed_flag;	
reg	[3:0]	sLed_DIG;
reg	[9:0]	sLed_DATA;
reg	[7:0]	sled_d0;	// 数码管输出

always @ (posedge Clk_5 or negedge rst_n) begin
	if (!rst_n)
		sLed_flag <= 5'b0;
	else begin
		sLed_flag = sLed_flag + 1'b1;
		if((5'b00000 <= sLed_flag) && (sLed_flag <= 5'b00011)) begin
			sLed_DIG <= 4'b1110;
			sLed_data0 <= sLed_DATA[3:0];
			sled_d0[7] <= 1'b1;
		end
		else if((5'b01000 <= sLed_flag) && (sLed_flag <= 5'b01011)) begin
			sLed_DIG <= 4'b1101;
			sLed_data0 <= sLed_DATA[7:4];
			sled_d0[7] <= 1'b1;
		end
		else if((5'b10000 <= sLed_flag) && (sLed_flag <= 5'b10011)) begin
			sLed_DIG <= 4'b1011;
			sLed_data0 <= state_1;
			sled_d0[7] <= ~neg_1;
		end
		else if((5'b11000 <= sLed_flag) && (sLed_flag <= 5'b11011)) begin
			sLed_DIG <= 4'b0111;
			sLed_data0 <= state_0;
			sled_d0[7] <= ~neg_0;
		end
		else begin
			sLed_DIG <= 4'b1111;
			sLed_data0 <= 4'hf;
			sled_d0[7] <= 1'b1;
		end

		case (sLed_data0)
			4'h0 : sled_d0[6:0] <= 7'h40; //显示"0"
			4'h1 : sled_d0[6:0] <= 7'h79; //显示"1"
			4'h2 : sled_d0[6:0] <= 7'h24; //显示"2"
			4'h3 : sled_d0[6:0] <= 7'h30; //显示"3"
			4'h4 : sled_d0[6:0] <= 7'h19; //显示"4"
			4'h5 : sled_d0[6:0] <= 7'h12; //显示"5"
			4'h6 : sled_d0[6:0] <= 7'h02; //显示"6"
			4'h7 : sled_d0[6:0] <= 7'h78; //显示"7"
			4'h8 : sled_d0[6:0] <= 7'h00; //显示"8"
			4'h9 : sled_d0[6:0] <= 7'h10; //显示"9"
		endcase
	end
end

//---------------------------------------------------------------------------
// 变化量初始化块
reg 	[11:0]		CNT_MAX;
reg					fabo;	

// 计时器最大值根据拨码切换
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		sLed_DATA <= 8'd0;
		CNT_MAX<=12'hfff;
		fabo<=1'b0;
	end
	else begin 
		case( mode )
			4'b0001: begin // 60kHz
				sLed_DATA <= 8'h60;
				CNT_MAX<=12'd166;
				fabo<=1'b1;
			end
			4'b0010: begin // 32kHz
				sLed_DATA <= 8'h32;
				CNT_MAX<=12'd312;
				fabo<=1'b1;
			end
			4'b0100: begin // 24kHz
				sLed_DATA <= 8'h24;
				CNT_MAX<=12'd416;
				fabo<=1'b1;
			end
			4'b1000: begin // 16kHz
				sLed_DATA <= 8'h16;
				CNT_MAX<=12'd625;
				fabo<=1'b1;
			end
			default: begin
				sLed_DATA <= 8'h00;
				CNT_MAX<=12'hfff;
				fabo<=1'b0;
			end
		endcase
	end
end
//---------------------------------------------------------------------------
// 发波信号计时器
reg		[11:0]   cnt2;
reg			Clk_Freq;
reg			Clk_1M;

// 信号计时器
always @ (posedge Clk_5 or negedge rst_n) begin
    if (!rst_n)
		cnt2 <= 12'b0;
    else begin
		if(cnt2 < CNT_MAX/2 - 1) // 周期向下取整
			cnt2 <= cnt2 + 12'b1;
		else begin
			cnt2 <= 12'b0;
			Clk_Freq <= ~Clk_Freq;
		end
	end
end

// 发波信号计时器
reg		[19:0]   cnt3;

// 信号计时器
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
		cnt3 <= 20'b0;
    else begin
		if(cnt3 == 20'd500000)begin 
			cnt3 <= 20'b0;
			Clk_1M <= ~Clk_1M;
		end
		else
			cnt3 <= cnt3 + 20'b1;	
	end
end

reg			PWMOO1;
reg			PWMOO2;

always @ (posedge Clk_5 or negedge rst_n) begin
    if (!rst_n)begin
		PWMOO1 <= 1'b0;
	end
	else begin
		if(fabo)begin
			case( state_0 )
				4'd1:
					PWMOO1 <= 1'b1;
				4'd2:
					PWMOO1 <= ~(Clk_1M|Clk_Freq);
				4'd3:
					PWMOO1 <= ~(~Clk_1M|~Clk_Freq);
				4'd4:
					PWMOO1 <= Clk_Freq;
				default:
					PWMOO1 <= 1'b0;
			endcase
		end
		else
			PWMOO1 <= 1'b0;
	end
end

always @ (posedge Clk_5 or negedge rst_n) begin
    if (!rst_n)begin
		PWMOO2 <= 1'b0;
	end
	else begin
		if(fabo)begin
			case( state_1 )
				4'd1:
					PWMOO2 <= 1'b1;
				4'd2:
					PWMOO2 <= ~(Clk_1M|Clk_Freq);
				4'd3:
					PWMOO2 <= ~(~Clk_1M|~Clk_Freq);
				4'd4:
					PWMOO2 <= Clk_Freq;
				default:
					PWMOO2 <= 1'b0;
			endcase
		end
		else
			PWMOO2 <= 1'b0;
	end
end

//---------------------------------------------------------------------------
// 输出脚连线	
	assign PWMO1 = neg_0 ? ~PWMOO1 : PWMOO1;
	assign PWMO2 = neg_1 ? ~PWMOO2 : PWMOO2;

	assign led_d7 = Led_d[7] ? 1'b1 : 1'b0;
	assign led_d6 = Led_d[6] ? 1'b1 : 1'b0;
	assign led_d5 = Led_d[5] ? 1'b1 : 1'b0;
	assign led_d4 = Led_d[4] ? 1'b1 : 1'b0;
	assign led_d3 = Led_d[3] ? 1'b1 : 1'b0;
	assign led_d2 = Led_d[2] ? 1'b1 : 1'b0;
	assign led_d1 = Led_d[1] ? 1'b1 : 1'b0;
	assign led_d0 = Led_d[0] ? 1'b1 : 1'b0;
	
	assign sled_Dig = sLed_DIG;

endmodule