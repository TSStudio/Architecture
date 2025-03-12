//注意此模块默认被除数的位宽大于等于除数的位宽。
//当quotient_vld信号为高电平且error为低电平时，输出的数据是除法计算的正确结果。
//当输入除数为0时，error信号拉高，且商和余数为0；
//当ready信号为低电平时，不能将开始信号start拉高，此时拉高start信号会被忽略。
module div #(
	parameter 			L_DIVN			= 	8				,//被除数的位宽；
	parameter 			L_DIVR			= 	4				 //除数的位宽；
)(
	input									clk 			,//时钟信号；
	input 									rst_n			,//复位信号，低电平有效；

	input 									start 			,//开始计算信号，高电平有效，必须在ready信号为高电平时输入才有效。
	input				[L_DIVN - 1 : 0]	dividend		,//被除数输入；
	input				[L_DIVR - 1 : 0]	divisor			,//除数输入；

	output 	logic 							ready			,//高电平表示此模块空闲。
	output 	logic 							error			,//高电平表示输入除数为0，输入数据错误。
	output  logic 		 					quotient_vld	,//商和余数输出有效指示信号，高电平有效；
	output	logic 		[L_DIVR - 1 : 0]	remainder		,//余数，余数的大小不会超过除数大小。
	output	logic		[L_DIVN - 1 : 0]	quotient 		 //商。
);	
	localparam          L_CNT   		= 	clogb2(L_DIVN)	;//利用函数自动计算移位次数计数器的位宽。
	localparam 			IDLE 			= 	3'b001  		;//状态机空闲状态的编码；
	localparam 			ADIVR			= 	3'b010  		;//状态机移动除数状态的编码;
	localparam 			DIV				= 	3'b100  		;//状态机进行减法计算和移动被除数状态的编码;

	logic 									vld				;//
	logic  				[2 : 0]				state_c			;//状态机的现态；
	logic  				[2 : 0]				state_n			;//状态机的次态；
	logic				[L_DIVN : 0]		dividend_r		;//保存被除数；
	logic				[L_DIVR - 1 : 0]	divisor_r   	;//保存除数。
	logic				[L_DIVN - 1 : 0]	quotient_r 		;//保存商。
	logic				[L_CNT - 1 : 0]		shift_dividend	;//用于记录被除数左移的次数。
	logic				[L_CNT - 1 : 0]		shift_divisor	;//用于记录除数左移的次数。
	
	logic 				[L_DIVR : 0] 		comparison		;//被除数的高位减去除数。
	logic   								max				;//高电平表示被除数左移次数已经用完，除法运算基本结束，可能还需要进行一次减法运算。
	
	//自动计算计数器位宽函数。
	function integer clogb2(input integer depth);begin
		if(depth == 0)
			clogb2 = 1;
		else if(depth != 0)
			for(clogb2=0 ; depth>0 ; clogb2=clogb2+1)
				depth=depth >> 1;
		end
	endfunction

	//max为高电平表示被除数左移的次数等于除数左移次数加上被除数与除数的位宽差；
	assign max = (shift_dividend == (L_DIVN - L_DIVR) + shift_divisor);

	//用来判断除数和被除数第一次做减法的高位两者的大小，当被除数高位大于等于除数时，comparison最高位为0，反之为1。
	//comparison的计算结果还能表示被除数高位与除数减法运算的结果。
	//在移动除数时，判断的是除数左移一位后与被除数高位的大小关系，进而判断能不能把除数进行左移。
	assign comparison = ((divisor[L_DIVR-1] == 0) && ((state_c == ADIVR))) ? 
				dividend_r[L_DIVN : L_DIVN - L_DIVR] - {divisor_r[L_DIVR-2 : 0],1'b0} : 
				dividend_r[L_DIVN : L_DIVN - L_DIVR] - divisor_r;//计算被除数高位减去除数，如果计算结果最高位为0，表示被除数高位大于等于除数，如果等于1表示被除数高位小于除数。
	
	//状态机次态到现态的转换；
	always_ff@(posedge clk or negedge rst_n)begin
		if(rst_n==1'b0)begin//初始值为空闲状态；
			state_c <= IDLE;
		end
		else begin//状态机次态到现态的转换；
			state_c <= state_n;
		end
	end

	//状态机的次态变化。
	always_comb begin
		case(state_c)
			IDLE : begin//如果开始计算信号为高电平且除数和被除数均不等于0。
				if(start & (dividend != 0) & (divisor != 0))begin
					state_n = ADIVR;
				end
				else begin//如果开始条件无效或者除数、被除数为0，则继续处于空闲状态。
					state_n = state_c;
				end
			end
			ADIVR : begin//如果除数的最高位为高电平或者除数左移一位大于被除数的高位，则跳转到除法运算状态；
				if(divisor_r[L_DIVR-1] | comparison[L_DIVR])begin
					state_n = DIV;
				end
				else begin
					state_n = state_c;
				end
			end
			DIV : begin
				if(max)begin//如果被除数移动次数达到最大值，则状态机回到空闲状态，计算完成。
					state_n = IDLE;
				end
				else begin
					state_n = state_c;
				end
			end
			default : begin//状态机跳转到空闲状态；
				state_n = IDLE;
			end
		endcase
	end

	//对被除数进行移位或进行减法运算。
	//初始时需要加载除数和被除数，然后需要判断除数和被除数的高位，确定除数是否需要移位。
	//然后根据除数和被除数高位的大小，确认被除数是移位还是与除数进行减法运算，注意被除数移动时，为了保证结果不变，商也会左移一位。
	//如果被除数高位与除数进行减法运算，则商的最低位变为1，好比此时商1进行的减法运算。经减法结果赋值到被除数对应位。
	always_ff@(posedge clk or negedge rst_n)begin
		if(rst_n==1'b0)begin//初始值为0;
			divisor_r <= 0;
			dividend_r <= 0;
			quotient_r <= 0;
			shift_divisor <= 0;
			shift_dividend <= 0;
		end//状态机处于加载状态时，将除数和被除数加载到对应寄存器，开始计算；
		else if(state_c == IDLE && start && (dividend != 0) & (divisor != 0))begin
			dividend_r <= dividend;//加载被除数到寄存器；
			divisor_r <= divisor;//加载除数到寄存器；
			quotient_r <= 0;//将商清零；
			shift_dividend <= 0;//将移位的被除数寄存器清零；
			shift_divisor <= 0; //将移位的除数寄存器清零；
		end//状态机处于除数左移状态，且除数左移后小于等于被除数高位且除数最高位为0。
		else if(state_c == ADIVR && (~comparison[L_DIVR]) && (~divisor_r[L_DIVR-1]))begin
			divisor_r <= divisor_r << 1;//将除数左移1位；
			shift_divisor <= shift_divisor + 1;//除数总共被左移的次数加1；
		end
		else if(state_c == DIV)begin//该状态需要完成被除数移位和减法运算。
			if(comparison[L_DIVR] && (~max))begin//当除数大于被除数高位时，被除数需要移位。
				dividend_r <= dividend_r << 1;//将被除数左移1位；
				quotient_r <= quotient_r << 1;//同时把商左移1位；
				shift_dividend <= shift_dividend + 1;//被除数总共被左移的次数加1；
			end
			else if(~comparison[L_DIVR])begin//当除数小于等于被除数高位时，被除数高位减去除数作为新的被除数高位。
				dividend_r[L_DIVN : L_DIVN - L_DIVR] <= comparison;//减法结果赋值给被除数进行减法运算的相应位。
				quotient_r[0] <= 1;//因为做了一次减法，则商加1。
			end
		end
	end
	
	//生成状态机从计算除结果的状态跳转到空闲状态的指示信号，用于辅助设计输出有效指示信号。
	always_ff@(posedge clk)begin
		vld <= (state_c == DIV) && (state_n == IDLE);
	end

	//生成商、余数及有效指示信号；
	always_ff@(posedge clk or negedge rst_n)begin
		if(rst_n==1'b0)begin//初始值为0;
			quotient <= 0;
			remainder <= 0;
			quotient_vld <= 1'b0;
		end//如果开始计算时，发现除数或者被除数为0，则商和余数均输出0，且将输出有效信号拉高。
		else if(state_c == IDLE && start && ((dividend== 0) || (divisor==0)))begin
			quotient <= 0;
			remainder <= 0;
			quotient_vld <= 1'b1;
		end
		else if(vld)begin//当计算完成时。
			quotient <= quotient_r;//把计算得到的商输出。
			quotient_vld <= 1'b1;//把商有效是指信号拉高。
			//移动剩余部分以补偿对齐变化，计算得到余数；
			remainder <= (dividend_r[L_DIVN - 1 : 0]) >> shift_dividend;
		end
		else begin
			quotient_vld <= 1'b0;
		end
	end

	//当输入除数为0时，将错误指示信号拉高，其余时间均为低电平。
	always_ff@(posedge clk or negedge rst_n)begin
		if(rst_n==1'b0)begin//初始值为0;
			error <= 1'b0;
		end
		else if(state_c == IDLE && start)begin
			if(divisor==0)//开始计算时，如果除数为0，把错误指示信号拉高。
				error <= 1'b1;
			else//开始计算时，如果除数不为0，把错误指示信号拉低。
				error <= 1'b0;
		end
	end
	
	//状态机处于空闲且不处于复位状态；
	always_ff@(*)begin
		if(start || state_c != IDLE || vld)
			ready = 1'b0;
		else 
			ready = 1'b1;
	end

endmodule