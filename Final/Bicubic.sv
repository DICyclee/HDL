module Bicubic ( 
input CLK,
input RST,
input enable,
input [7:0] input_data,
output logic [13:0] iaddr,
output logic ird,
output logic we,
output logic [13:0] waddr,
output logic [7:0] output_data,
input [6:0] V0,
input [6:0] H0,
input [4:0] SW,
input [4:0] SH,
input [5:0] TW,
input [5:0] TH,
output logic DONE);

reg [2:0] cstate;
reg [2:0] nstate;
reg [3:0] cnt;
reg [6:0] xc;
reg [6:0] yc;
reg [10:0] a;
reg [10:0] b;
reg [10:0] c;
reg [8:0] d;
reg [10:0] poly_neg_1;
reg [10:0] poly_0;
reg [10:0] poly_1;
reg [10:0] poly_2;
reg drive;
reg [1:0] num;
reg [7:0] buffer [0:3];
reg [9:0] denominator;
reg [5:0] numerator;
reg [21:0] h_hit;
reg [21:0] v_hit;
reg signed [25:0] mul_1;
reg signed [14:0] mul_2;
reg signed [41:0] mul_3;
reg [9:0] x_mul_SW; 
reg [9:0] y_mul_SH;
reg [6:0] x_mul_tmp [0:4];
reg [6:0] y_mul_tmp [0:4];
reg signed [41:0] sum;
reg [25:0] mask [0:14];

wire [4:0] SW_minus_1 = SW - 1;
wire [4:0] SH_minus_1 = SH - 1;
wire [5:0] TW_minus_1 = TW - 1;
wire [5:0] TH_minus_1 = TH - 1;
wire [3:0] cnt_plus_1 = cnt + 1;
wire [13:0] iaddr_plus_1 = iaddr + 1;
wire [13:0] iaddr_plus_100 = iaddr + 100;
wire h_hit_star = &(!h_hit[14:0]);
wire v_hit_star = &(!v_hit[14:0]);
wire [19:0] div = {denominator, 15'd0} / numerator;
wire [6:0] vc = v_hit[21:15] + V0;
wire [6:0] hc = h_hit[21:15] + H0;
wire [13:0] hc_mul_100 = (hc << 6) + (hc << 5) + (hc << 2);
wire [13:0] fc = vc + hc_mul_100;
wire signed [42:0] result = sum + mul_3;
wire signed [42:0] result_rs = result >>> 7;
wire [7:0] r1 = result[39:32];

assign ird = 1;

always @(*) begin
    case(cstate)
        0:begin
			if(cnt == 4)begin
				if(h_hit_star && v_hit_star)
					nstate = 3;
				else if(h_hit_star)
					nstate = 5;
				else if(v_hit_star)
					nstate = 4;
				else
					nstate = 2;				
			end
			else
				nstate = 0;
		end
        1:begin
			nstate = 5;
		end	
		2:begin
			nstate = 4;
		end	
        3:begin
			if(cnt == 2)
				nstate = 0;
			else
				nstate = 3;
		end
        4:begin
			if(cnt == 9)begin
				if(drive)begin
					if(num == 3)
						nstate = 1;
					else
						nstate = 2;
				end
				else
					nstate = 0;	
			end			
			else
				nstate = 4;
		end
        default:begin
			if(cnt == 9)
				nstate = 0;
			else
				nstate = 5;
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
		xc <= -1;
		yc <= 0;
		cnt <= 0;		
		drive <= 0; 
		num <= -1;
		we <= 0;
		waddr <= -1;	
	end
	else begin
		case(cstate)
			0:begin
				if(cnt == 4)
					cnt <= 0;
				else
					cnt <= cnt_plus_1;
				case(cnt)
					0:begin
						we <= 0;
						drive <= 0;
						waddr <= waddr + 1;
						if(xc == TW_minus_1 && yc == TH_minus_1)
							DONE <= 1;
						else if(xc == TW_minus_1)begin
							xc <= 0;
							yc <= yc + 1;
						end
						else begin
							xc <= xc + 1;
						end							
					end
					1:begin
						denominator <= x_mul_SW;
						numerator <= TW_minus_1;		
					end
					2:begin
						h_hit <= div;
						denominator <= y_mul_SH;
						numerator <= TH_minus_1;					
					end			
					3:begin
						v_hit <= div;						
					end											
				endcase			
			end
			1:begin
				cnt <= 6;
				poly_neg_1 <= buffer[0];
				poly_0 <= buffer[1];
				poly_1 <= buffer[2];
				poly_2 <= buffer[3];
			end
			2:begin
				drive <= 1;
				num <= num + 1;
			end						
			3:begin
				if(cnt == 2)
					cnt <= 0;
				else
					cnt <= cnt_plus_1;
				case(cnt)
					0:begin
						iaddr <= fc;						
					end
					1:begin
						we <= 1;		
					end
					2:begin
						output_data <= input_data;						
					end																
				endcase
			end
			4:begin
				if(cnt == 9)
					cnt <= 0;
				else
					cnt <= cnt_plus_1;
				case(cnt)
					0:begin
						if(drive)
							iaddr <= fc - 101 + num;
						else
							iaddr <= fc - 100;
					end
					1:begin
						iaddr <= iaddr_plus_100;		
					end
					2:begin
						iaddr <= iaddr_plus_100;
						poly_neg_1 <= input_data;						
					end			
					3:begin
						iaddr <= iaddr_plus_100;
						poly_0 <= input_data;						
					end
					4:begin
						poly_1 <= input_data;						
					end
					5:begin
						poly_2 <= input_data;						
					end			
					6:begin
						mul_1 <= {{15{a[10]}}, a};
						mul_2 <= h_hit[14:0];
						mul_3 <= {{16{b[10]}}, b, 15'd0};						
					end
					7:begin
						mul_1 <= result_rs;
						mul_3 <= {{8{c[10]}}, c, 23'd0};						
					end			
					8:begin
						mul_1 <= result_rs;
						mul_3 <= {d, 31'd0};
						if(!drive)
							we <= 1;					
					end
					9:begin
						if(result[42])begin
							buffer[num] <= 0;
							output_data <= 0;
						end
						else begin
							if(result[31])begin
								if(&r1)begin
									buffer[num] <= 255;
									output_data <= 255;
								end
								else begin
									buffer[num] <= r1 + 1;
									output_data <= r1 + 1;    
								end
							end
							else begin
								buffer[num] <= r1;
								output_data <= r1;
							end
						end						
					end															
				endcase
			end
			5:begin
				if(cnt == 9)
					cnt <= 0;
				else
					cnt <= cnt_plus_1;
				case(cnt)
					0:begin
						iaddr <= fc - 1; 						
					end
					1:begin
						iaddr <= iaddr_plus_1;		
					end
					2:begin
						iaddr <= iaddr_plus_1;
						poly_neg_1 <= input_data;						
					end			
					3:begin		
						iaddr <= iaddr_plus_1;
						poly_0 <= input_data;									
					end
					4:begin		
						poly_1 <= input_data;				
					end
					5:begin	
						poly_2 <= input_data;										
					end			
					6:begin		
						mul_1 <= {{25{a[10]}}, a};
						mul_2 <= v_hit[14:0];
						mul_3 <= {{16{b[10]}}, b, 15'd0};									
					end
					7:begin		
						mul_1 <= result_rs;
						mul_3 <= {{8{c[10]}}, c, 23'd0};									
					end			
					8:begin		
						mul_1 <= result_rs;
						mul_3 <= {d, 31'd0};
						we <= 1;								
					end
					9:begin		
						if(result[42])begin
							output_data <= 0;
						end
						else begin
							if(result[31])begin
								if(&r1)
									output_data <= 255;
								else
									output_data <= r1 + 1;    
							end
							else
								output_data <= r1;
						end									
					end															
				endcase 
			end
		endcase		
	end
end

always @(*) begin
    a = ((poly_0 << 1) + poly_0) - ((poly_1 << 1) + poly_1) + poly_2 - poly_neg_1;
    b = {poly_neg_1, 1'd0} - ((poly_0 << 2) + poly_0) + (poly_1 << 2) - poly_2 ;
    c = poly_1  - poly_neg_1 ;
    d = poly_0 << 1;
end

always @(*) begin
	x_mul_tmp[0] = xc & {7{SW_minus_1[0]}};
	x_mul_tmp[1] = xc & {7{SW_minus_1[1]}};
	x_mul_tmp[2] = xc & {7{SW_minus_1[2]}};
	x_mul_tmp[3] = xc & {7{SW_minus_1[3]}};
	x_mul_tmp[4] = xc & {7{SW_minus_1[4]}};

	y_mul_tmp[0] = yc & {7{SH_minus_1[0]}};
	y_mul_tmp[1] = yc & {7{SH_minus_1[1]}};
	y_mul_tmp[2] = yc & {7{SH_minus_1[2]}};
	y_mul_tmp[3] = yc & {7{SH_minus_1[3]}};
	y_mul_tmp[4] = yc & {7{SH_minus_1[4]}};    

    x_mul_SW = x_mul_tmp[0] + {x_mul_tmp[1], 1'd0} + {x_mul_tmp[2], 2'd0} + {x_mul_tmp[3], 3'd0} + {x_mul_tmp[4], 4'd0};    
    y_mul_SH = y_mul_tmp[0] + {y_mul_tmp[1], 1'd0} + {y_mul_tmp[2], 2'd0} + {y_mul_tmp[3], 3'd0} + {y_mul_tmp[4], 4'd0};
end

always @(*) begin
	mask[0] = mul_1 & {26{mul_2[0]}};
	mask[1] = mul_1 & {26{mul_2[1]}};
	mask[2] = mul_1 & {26{mul_2[2]}};
	mask[3] = mul_1 & {26{mul_2[3]}};
	mask[4] = mul_1 & {26{mul_2[4]}};
	mask[5] = mul_1 & {26{mul_2[5]}};
	mask[6] = mul_1 & {26{mul_2[6]}};
	mask[7] = mul_1 & {26{mul_2[7]}};
	mask[8] = mul_1 & {26{mul_2[8]}};
	mask[9] = mul_1 & {26{mul_2[9]}};
	mask[10] = mul_1 & {26{mul_2[10]}};
	mask[11] = mul_1 & {26{mul_2[11]}};
	mask[12] = mul_1 & {26{mul_2[12]}};
	mask[13] = mul_1 & {26{mul_2[13]}};
	mask[14] = mul_1 & {26{mul_2[14]}};

    sum = (({{16{mask[0][25]}}, mask[0]} + {{15{mask[1][25]}}, mask[1], 1'd0}) + ({{14{mask[2][25]}}, mask[2], 2'd0} + {{13{mask[3][25]}}, mask[3], 3'd0})) + 
		  (({{12{mask[4][25]}}, mask[4], 4'd0} + {{11{mask[5][25]}}, mask[5], 5'd0}) + ({{10{mask[6][25]}}, mask[6], 6'd0} + {{9{mask[7][25]}}, mask[7], 7'd0})) + 
		  (({{8{mask[8][25]}}, mask[8], 8'd0} + {{7{mask[9][25]}}, mask[9], 9'd0}) + ({{6{mask[10][25]}}, mask[10], 10'd0} + {{5{mask[11][25]}}, mask[11], 11'd0})) +
		  ({{4{mask[12][25]}}, mask[12], 12'd0} + {{3{mask[13][25]}}, mask[13], 13'd0}) + {{2{mask[14][25]}}, mask[14], 14'd0};
end  

endmodule