`timescale 1ns/10ps
					   
module  CONV(		   
	input clk,
	input reset,
	output reg busy,	
	input ready,	
	//gray-image mem
	output reg [13:0] iaddr,
	input [7:0]	idata,	
	output ioe,
	//L0 mem
	output reg wen_L0,
	output oe_L0,
	output reg [13:0] addr_L0,
	output reg [11:0] w_data_L0,
	input [11:0] r_data_L0,
	//L1 mem
	output reg wen_L1,
	output oe_L1,
	output reg [11:0] addr_L1,
	output reg [11:0] w_data_L1,
	input [11:0] r_data_L1,
	//weight mem
	output oe_weight,
	output reg [15:0] addr_weight,
	input signed [7:0] r_data_weight,
	//L2 mem
	output reg wen_L2,
	output reg [3:0] addr_L2,
	output reg signed [31:0] w_data_L2
	);

//you can only motify your code below

reg [3:0] cstate;
reg [3:0] nstate;
reg flag;
reg [7:0] buffer [1:15];
reg [7:0] buffer_padding [1:16];
reg [7:0] buffer_conv [1:9];
reg signed [12:0] conv_result;
reg signed [19:0] fc;
reg signed [19:0] fc_tmp;
reg signed [31:0] fc_acc;
reg signed [31:0] result;
reg [7:0]fc_tmp_0;
reg [8:0]fc_tmp_1;
reg [9:0]fc_tmp_2;
reg [10:0]fc_tmp_3;
reg [11:0]fc_tmp_4;
reg [12:0]fc_tmp_5;
reg [13:0]fc_tmp_6;
reg [14:0]fc_tmp_7;
reg [15:0]fc_tmp_8;
reg [16:0]fc_tmp_9;
reg [17:0]fc_tmp_10;
reg [18:0]fc_tmp_11;
reg [19:0] fc2 [0:11];

wire [13:0] addr_L0_plus1;
wire [11:0] addr_L1_plus1;
wire [3:0] addr_L2_plus1;
wire [15:0] addr_weight_plus1;
wire [13:0] iaddr_plus128;
wire [13:0] addr_L0_plus128;
wire L0_x_right;
wire L0_y_down;
wire L1_x_left; 
wire L1_y_up;
wire L1_x_right;
wire L1_y_down; 

//combinational circuit
assign ioe = 1;	
assign oe_L1 = 1;
assign oe_weight = 1;

assign addr_L0_plus1 = addr_L0 + 1;
assign addr_L1_plus1 = addr_L1 + 1;
assign addr_L2_plus1 = addr_L2 + 1;
assign addr_weight_plus1 = addr_weight + 1;
assign iaddr_plus128 = {{iaddr[13:7] + 1}, iaddr[6:0]};
assign addr_L0_plus128 = {{addr_L0[13:7] + 1}, addr_L0[6:0]};

assign L0_x_right = (&addr_L0[6:0]);
assign L0_y_down = (&addr_L0[13:7]);

assign L1_x_left = (&(!addr_L1_plus1[5:0]));
assign L1_y_up = (&(!addr_L1_plus1[11:6]));
assign L1_x_right = (&addr_L1_plus1[5:0]);
assign L1_y_down = (&addr_L1_plus1[11:6]);

always @(*) begin
	buffer_padding[1] = L1_x_left || L1_y_up ? 0 : buffer[1];
	buffer_padding[2] = L1_x_left ? 0 : buffer[2];
	buffer_padding[3] = L1_x_left ? 0 : buffer[3];
	buffer_padding[4] = L1_x_left || L1_y_down ? 0 : buffer[4];
	buffer_padding[5] = L1_y_up ? 0 : buffer[5];		
	buffer_padding[6] = buffer[6];
	buffer_padding[7] = buffer[7];
	buffer_padding[8] = L1_y_down ? 0 : buffer[8];
	buffer_padding[9] = L1_y_up ? 0 : buffer[9];		
	buffer_padding[10] = buffer[10];
	buffer_padding[11] = buffer[11];
	buffer_padding[12] = L1_y_down ? 0 : buffer[12];
	buffer_padding[13] = L1_x_right || L1_y_up ? 0 : buffer[13];
	buffer_padding[14] = L1_x_right ? 0 : buffer[14];	
	buffer_padding[15] = L1_x_right ? 0 : buffer[15];
	buffer_padding[16] = L1_x_right || L1_y_down ? 0 : idata;

	case(cstate)
		4:begin
			buffer_conv[1] = buffer_padding[1];
			buffer_conv[2] = buffer_padding[2];
			buffer_conv[3] = buffer_padding[3];
			buffer_conv[4] = buffer_padding[5];
			buffer_conv[5] = buffer_padding[6];
			buffer_conv[6] = buffer_padding[7];
			buffer_conv[7] = buffer_padding[9];
			buffer_conv[8] = buffer_padding[10];
			buffer_conv[9] = buffer_padding[11];															
		end
		5:begin
			buffer_conv[1] = buffer_padding[2];
			buffer_conv[2] = buffer_padding[3];
			buffer_conv[3] = buffer_padding[4];
			buffer_conv[4] = buffer_padding[6];
			buffer_conv[5] = buffer_padding[7];
			buffer_conv[6] = buffer_padding[8];
			buffer_conv[7] = buffer_padding[10];
			buffer_conv[8] = buffer_padding[11];
			buffer_conv[9] = buffer_padding[12];				
		end
		8:begin
			buffer_conv[1] = buffer_padding[5];
			buffer_conv[2] = buffer_padding[6];
			buffer_conv[3] = buffer_padding[7];
			buffer_conv[4] = buffer_padding[9];
			buffer_conv[5] = buffer_padding[10];
			buffer_conv[6] = buffer_padding[11];
			buffer_conv[7] = buffer_padding[13];
			buffer_conv[8] = buffer_padding[14];
			buffer_conv[9] = buffer_padding[15];			
		end
		default:begin
			buffer_conv[1] = buffer_padding[6];
			buffer_conv[2] = buffer_padding[7];
			buffer_conv[3] = buffer_padding[8];
			buffer_conv[4] = buffer_padding[10];
			buffer_conv[5] = buffer_padding[11];
			buffer_conv[6] = buffer_padding[12];
			buffer_conv[7] = buffer_padding[14];
			buffer_conv[8] = buffer_padding[15];
			buffer_conv[9] = buffer_padding[16];					
		end
	endcase    

	conv_result = (buffer_conv[3] + buffer_conv[5]) + (({buffer_conv[6], 1'b0}) + buffer_conv[7]) + 
				  (({buffer_conv[8], 1'b0}) - ({buffer_conv[1], 1'b0}) - ({buffer_conv[9], 1'b0}) - buffer_conv[9]);

	conv_result = (conv_result < 0) ? 0 : conv_result;

	fc_tmp_0 = {{8{r_data_L1[0]}} & r_data_weight};
	fc_tmp_1 = {{({8{r_data_L1[1]}} & r_data_weight), 1'b0}}; 
	fc_tmp_2 = {{({8{r_data_L1[2]}} & r_data_weight), 2'b0}}; 
	fc_tmp_3 = {{({8{r_data_L1[3]}} & r_data_weight), 3'b0}}; 
	fc_tmp_4 = {{({8{r_data_L1[4]}} & r_data_weight), 4'b0}}; 
	fc_tmp_5 = {{({8{r_data_L1[5]}} & r_data_weight), 5'b0}}; 
	fc_tmp_6 = {{({8{r_data_L1[6]}} & r_data_weight), 6'b0}}; 
	fc_tmp_7 = {{({8{r_data_L1[7]}} & r_data_weight), 7'b0}};
	fc_tmp_8 = {{({8{r_data_L1[8]}} & r_data_weight), 8'b0}};
	fc_tmp_9 = {{({8{r_data_L1[9]}} & r_data_weight), 9'b0}};
	fc_tmp_10 = {{({8{r_data_L1[10]}} & r_data_weight), 10'b0}};
	fc_tmp_11 = {{({8{r_data_L1[11]}} & r_data_weight), 11'b0}};

	fc2[0] = {{12{fc_tmp_0[7]}}, fc_tmp_0};
	fc2[1] = {{11{fc_tmp_1[8]}}, fc_tmp_1};
	fc2[2] = {{10{fc_tmp_2[9]}}, fc_tmp_2};
	fc2[3] = {{9{fc_tmp_3[10]}}, fc_tmp_3};
	fc2[4] = {{8{fc_tmp_4[11]}}, fc_tmp_4};
	fc2[5] = {{7{fc_tmp_5[12]}}, fc_tmp_5};
	fc2[6] = {{6{fc_tmp_6[13]}}, fc_tmp_6};
	fc2[7] = {{5{fc_tmp_7[14]}}, fc_tmp_7};
	fc2[8] = {{4{fc_tmp_8[15]}}, fc_tmp_8};
	fc2[9] = {{3{fc_tmp_9[16]}}, fc_tmp_9};
	fc2[10] = {{2{fc_tmp_10[17]}},fc_tmp_10};
	fc2[11] = {{1{fc_tmp_11[18]}},fc_tmp_11};

	fc = ((fc2[0] + fc2[1]) + (fc2[2] + fc2[3])) + ((fc2[4] + fc2[5]) + (fc2[6] + fc2[7])) + ((fc2[8] + fc2[9]) + (fc2[10] + fc2[11]));		

	fc_acc = w_data_L2 + $signed(fc_tmp);
	result = (fc_acc < 0) ? (fc_acc >>> 16) : fc_acc;	
end

always @(*) begin
	case(cstate)
		//L0 + L1
		0:begin
			nstate = 1;
		end
		1:begin
        	nstate = 2;
		end
		2:begin
			nstate = 3;
		end
		3:begin
			nstate = 4;
		end
		4:begin	
			nstate = 5;
		end			
		5:begin
			nstate = 6;
		end
		6:begin
			nstate = 7;								
		end
		7:begin
			nstate = 8;
		end					
		8:begin	
			nstate = 9;			
		end		
		9:begin
			nstate = 10;
		end	        
		10:begin
			if(L0_x_right && L0_y_down && (!wen_L2))
				nstate = 11;
			else
				nstate = 0;
		end
		//L2
		11:begin
			nstate = 12;
		end
		12:begin
			nstate = 13;
		end		
		13:begin
			if(&(!addr_L1))
				nstate = 14;
			else
				nstate = 13;
		end
		14:begin
			if(addr_L2[3] && addr_L2[0])
				nstate = 15;
			else
				nstate = 12;
		end			
		default:begin
			nstate = cstate;
		end				
	endcase	
end

//sequential circuit
always @(posedge clk or posedge reset) begin
	if(reset)
		cstate <= 0;
	else
		cstate <= nstate;
end

always @(posedge clk or posedge reset) begin
	if(reset)begin
		busy <= 0;     
		flag <= 0;
		iaddr <= -129;
		addr_L0 <= -2;
		addr_L1 <= -2;
		addr_L2 <= -1;
		addr_weight <= 0;
		wen_L0 <= 0; 
		wen_L1 <= 0;
		wen_L2 <= 1;			
	end
	else begin
		case(cstate)
			0:begin
				busy <= 1;
				iaddr <= iaddr_plus128;
				wen_L1 <= 0;
			end
			1:begin
				iaddr <= iaddr_plus128;
				buffer[9] <= idata;
			end
			2:begin
				iaddr <= iaddr_plus128;
				buffer[10] <= idata;
			end
			3:begin
				iaddr <= iaddr - 383;  
				buffer[11] <= idata;
			end
			4:begin
				iaddr <= iaddr_plus128;  
				buffer[12] <= idata;
				if(!flag)
					wen_L0 <= 1;
				w_data_L0 <= conv_result;
				w_data_L1 <= conv_result;
			end			
            5:begin
				addr_L0 <= addr_L0_plus128;
				iaddr <= iaddr_plus128;		
				buffer[13] <= idata;	
				w_data_L0 <= conv_result;
				w_data_L1 <= (conv_result > w_data_L1) ? conv_result : w_data_L1;		
			end
            6:begin
				wen_L0 <= 0;
				iaddr <= iaddr_plus128;
				buffer[14] <= idata;	
				addr_L0 <= addr_L0 - 127;							
			end
            7:begin
				buffer[15] <= idata;			
			end					
            8:begin			
				if(!flag)
					wen_L0 <= 1;					
				w_data_L0 <= conv_result;				
				w_data_L1 <= (conv_result > w_data_L1) ? conv_result : w_data_L1;
			end		
			9:begin
				addr_L0 <= addr_L0_plus128;
				w_data_L0 <= conv_result;	
				w_data_L1 <= (conv_result > w_data_L1) ? conv_result : w_data_L1;
			end	
			10:begin
				buffer[1] <= buffer[9];
				buffer[2] <= buffer[10];
				buffer[3] <= buffer[11];
				buffer[4] <= buffer[12];	
				buffer[5] <= buffer[13];
				buffer[6] <= buffer[14];
				buffer[7] <= buffer[15];
				buffer[8] <= idata;	
				wen_L0 <= 0;	
				if(L0_x_right)
					wen_L2 <= 0;
				if(L0_x_right && (!wen_L2) && (!flag))begin
					iaddr <= iaddr - 257;
					addr_L0 <= addr_L0 - 1;		
					flag <= 1;			
				end
				else begin
					iaddr <= iaddr - 383;
					addr_L0 <= addr_L0 - 127;
					flag <= 0;
				end
				if(flag)
					wen_L1 <= 0;
				else begin
					wen_L1 <= 1;
					addr_L1 <= addr_L1_plus1;
				end
			end
			11:begin
				wen_L1 <= 0;			
				addr_L1 <= addr_L1_plus1;
			end
			12:begin
				wen_L2 <= 0;
				w_data_L2 <= 0;
				fc_tmp <= 0;					
				addr_L1 <= addr_L1_plus1;
				addr_L2 <= addr_L2_plus1;
				addr_weight <= addr_weight_plus1;								
			end
			13:begin
				fc_tmp <= fc;
				w_data_L2 <= fc_acc;
				addr_L1 <= addr_L1_plus1;
				addr_weight <= addr_weight_plus1;								
			end			
			14:begin	
				wen_L2 <= 1;
				w_data_L2 <= result;
				addr_L1 <= 0;
				addr_weight <= addr_L2_plus1 << 12;									
			end
			15:begin
				busy <= 0;		
			end									
		endcase
	end
end

endmodule