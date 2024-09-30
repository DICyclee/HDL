module Laser (
  input              CLK,
  input              RST,
  input      [3:0]     X,
  input      [3:0]     Y,
  input            valid,
  output reg [3:0]   C1X,
  output reg [3:0]   C1Y,
  output reg [3:0]   C2X,
  output reg [3:0]   C2Y,
  output reg        DONE
);

reg [1:0] cstate;
reg [1:0] nstate;

reg [3:0] target_X [0:39];
reg [3:0] target_Y [0:39];

reg [3:0] C1_center_X;
reg [3:0] C1_center_Y;
reg [3:0] C2_center_X;
reg [3:0] C2_center_Y;
reg [3:0] C1_second_start_X;
reg [3:0] C1_second_start_Y;
wire [3:0] C1_second_end_X = (C1_second_start_X >= 6) ? 13 : C1_second_start_X + 7;
wire [3:0] C1_second_end_Y = (C1_second_start_Y >= 6) ? 13 : C1_second_start_Y + 7;

reg [5:0] counter;
reg [5:0] target_find_counter;
reg [5:0] max_target_find_counter;
wire [39:0] in_C1;
reg [39:0] in_C2;
reg [39:0] in_C1_max;

reg [3:0] max_C1_center_X;
reg [3:0] max_C1_center_Y;
reg [3:0] max_C1_center_X_past;
reg [3:0] max_C1_center_Y_past;
reg [3:0] max_C1_center_X_more_past;
reg [3:0] max_C1_center_Y_more_past;
reg flag;

genvar i;

generate
	for (i = 0; i < 40; i = i + 1) begin : gen0
		InC u_inc(target_X[i], target_Y[i], C1_center_X, C1_center_Y, in_C1[i]);
	end
endgenerate

always @(*) begin
	target_find_counter = ((((((in_C1[0] || in_C2[0]) + (in_C1[1] || in_C2[1])) + ((in_C1[2] || in_C2[2]) + (in_C1[3] || in_C2[3])))) + 
						  ((((in_C1[4] || in_C2[4]) + (in_C1[5] || in_C2[5])) + ((in_C1[6] || in_C2[6]) + (in_C1[7] || in_C2[7]))))) + 
						  (((((in_C1[8] || in_C2[8]) + (in_C1[9] || in_C2[9])) + ((in_C1[10] || in_C2[10]) + (in_C1[11] || in_C2[11])))) + 
						  ((((in_C1[12] || in_C2[12]) + (in_C1[13] || in_C2[13])) + ((in_C1[14] || in_C2[14]) + (in_C1[15] || in_C2[15])))))) + 
						  (((((in_C1[16] || in_C2[16]) + (in_C1[17] || in_C2[17])) + ((in_C1[18] || in_C2[18]) + (in_C1[19] || in_C2[19])))) + 
						  ((((in_C1[20] || in_C2[20]) + (in_C1[21] || in_C2[21])) + ((in_C1[22] || in_C2[22]) + (in_C1[23] || in_C2[23]))))) + 
						  (((((in_C1[24] || in_C2[24]) + (in_C1[25] || in_C2[25])) + ((in_C1[26] || in_C2[26]) + (in_C1[27] || in_C2[27])))) + 
						  ((((in_C1[28] || in_C2[28]) + (in_C1[29] || in_C2[29])) + ((in_C1[30] || in_C2[30]) + (in_C1[31] || in_C2[31]))))) + 
						  (((((in_C1[32] || in_C2[32]) + (in_C1[33] || in_C2[33])) + ((in_C1[34] || in_C2[34]) + (in_C1[35] || in_C2[35])))) + 
						  ((((in_C1[36] || in_C2[36]) + (in_C1[37] || in_C2[37])) + ((in_C1[38] || in_C2[38]) + (in_C1[39] || in_C2[39])))));	
end

always @(*) begin
    case(cstate)
        0:begin 
			if(counter == 40)
				nstate = 1;
			else
				nstate = 0;
        end
		1:begin 
			if((!flag && C1_center_X == 9 && C1_center_Y == 9) || (flag && C1_center_X == C1_second_end_X && C1_center_Y == C1_second_end_Y))
				nstate = 2;
			else
				nstate = 1;			
		end
		default:begin 
			if(max_C1_center_X == max_C1_center_X_more_past && max_C1_center_Y == max_C1_center_Y_more_past)
				nstate = 0;
			else
				nstate = 1;
		end
    endcase
end

always @(posedge CLK or posedge RST) begin
    if(RST)
        cstate <= 0;
    else
        cstate <= nstate;
end

always @(posedge CLK or posedge RST) begin
    if(RST)begin
        DONE <= 0;
		counter <= 0;
		max_target_find_counter <= 0;				
		C1_center_X <= 8;
		C1_center_Y <= 7;		
		max_C1_center_X_past <= 7;
		max_C1_center_Y_past <= 6;											
		in_C2 <= 0;		
		flag <= 0;		
    end
    else begin
        case(cstate)
            0:begin						
				DONE <= 0;
				if(valid)begin
					target_X[counter] <= X;
					target_Y[counter] <= Y;
					counter <= counter + 1;
				end
            end
			1:begin
				if(target_find_counter >= max_target_find_counter)begin
					max_target_find_counter <= target_find_counter;
					max_C1_center_X <= C1_center_X;
					max_C1_center_Y <= C1_center_Y;
					in_C1_max <= in_C1;
				end
				if(!flag)begin
					if(C1_center_X == 9)begin
						C1_center_X <= 7;
						C1_center_Y <= C1_center_Y + 1;
					end
					else
						C1_center_X <= C1_center_X + 1;						
				end			
				else begin
					if(C1_center_X == C1_second_end_X)begin
						C1_center_X <= C1_second_start_X;
						C1_center_Y <= C1_center_Y + 1;
					end
					else
						C1_center_X <= C1_center_X + 1;						
				end
			end
			2:begin
				if(max_C1_center_X == max_C1_center_X_more_past && max_C1_center_Y == max_C1_center_Y_more_past)begin
					flag <= 0;
					DONE = 1;
					counter <= 0;									
					max_target_find_counter <= 0;
					C1X <= max_C1_center_X;
					C1Y <= max_C1_center_Y;
					C2X <= max_C1_center_X_past;
					C2Y <= max_C1_center_Y_past;
					C1_center_X <= 8;
					C1_center_Y <= 7;	
					max_C1_center_X_past <= 7;
					max_C1_center_Y_past <= 6;																			
				end
				else begin
					flag <= 1;
					C1_center_X <= (max_C1_center_X_past <= 6) ? 2 : max_C1_center_X_past - 4;
					C1_center_Y <= (max_C1_center_Y_past <= 6) ? 2 : max_C1_center_Y_past - 4;
					C1_second_start_X <= (max_C1_center_X_past <= 6) ? 2 : max_C1_center_X_past - 4;
					C1_second_start_Y <= (max_C1_center_Y_past <= 6) ? 2 : max_C1_center_Y_past - 4;	
					C2_center_X <= max_C1_center_X;
					C2_center_Y <= max_C1_center_Y;										
					max_C1_center_X_past <= max_C1_center_X;
					max_C1_center_Y_past <= max_C1_center_Y;
					max_C1_center_X_more_past <= max_C1_center_X_past;
					max_C1_center_Y_more_past <= max_C1_center_Y_past;
					in_C2 <= in_C1_max;					
				end
			end
        endcase
    end
end

endmodule

module InC(x, y, c_x, c_y, in_c);
input [3:0] x, y, c_x, c_y;
output reg in_c;

wire signed [4:0] x_diff = x - c_x;
wire signed [4:0] y_diff = y - c_y;
wire [3:0] x_diff_abs = (x_diff[4] ? -x_diff : x_diff);
wire [3:0] y_diff_abs = (y_diff[4] ? -y_diff : y_diff);

always @(*) begin
	case(y_diff_abs)
		0 : in_c = (x_diff_abs <= 4) ? 1 : 0;
		1 : in_c = (x_diff_abs <= 3) ? 1 : 0;
		2 : in_c = (x_diff_abs <= 3) ? 1 : 0;
		3 : in_c = (x_diff_abs <= 2) ? 1 : 0;
		4 : in_c = (x_diff_abs == 0) ? 1 : 0;
		default : in_c = 0;
	endcase
end

endmodule