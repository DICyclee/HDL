`timescale 1ns/10ps

module  CED(
	input  clk,
	input  rst,
	input  enable,
	output reg ird,
	input  [7:0] idata,	
	output reg [13:0] iaddr,
	output reg cwr_mag_0,
	output reg signed [12:0] cdata_mag_wr0,
	output reg crd_mag_0,
	input  [12:0] cdata_mag_rd0,
	output reg [13:0] caddr_mag_0,
	output reg cwr_ang_0,
	output reg [12:0] cdata_ang_wr0,
	output reg crd_ang_0,
	input  [12:0] cdata_ang_rd0,
	output reg [13:0] caddr_ang_0,
	output reg cwr1,
	output reg [12:0] cdata_wr1,
	output reg crd1,
	input  [12:0] cdata_rd1,
	output reg [13:0] caddr_1,
	output reg cwr2,
	output reg [12:0] cdata_wr2,
	output reg [13:0] caddr_2,
	output reg done
);

reg [2:0] cstate;
reg [2:0] nstate;

reg [3:0] counter;
reg [13:0] iaddr_counter;
reg [6:0] x;
reg [6:0] y;

reg [7:0] buffer [0:8];
reg signed [12:0] buffer2 [0:8];

reg signed [12:0] Gx_conv_buffer [0:8];
reg signed [12:0] Gy_conv_buffer [0:8];
reg signed [12:0] Gx;
reg signed [12:0] Gy;
reg signed [12:0] Gx_abs;
reg signed [12:0] Gy_abs;
reg signed [28:0] temp_result;

wire signed [2:0] Sx [0:8];
wire signed [2:0] Sy [0:8];

reg flag;

parameter L0_READ = 0;
parameter L0_WRITE = 1;
parameter L1_READ = 2;
parameter L1_WRITE = 3;
parameter L2_READ = 4;
parameter L2_WRITE = 5;

assign Sx[0] = 3'b111;
assign Sx[1] = 3'b000;
assign Sx[2] = 3'b001;
assign Sx[3] = 3'b110;
assign Sx[4] = 3'b000;
assign Sx[5] = 3'b010;
assign Sx[6] = 3'b111;
assign Sx[7] = 3'b000;
assign Sx[8] = 3'b001;

assign Sy[0] = 3'b111;
assign Sy[1] = 3'b110;
assign Sy[2] = 3'b111;
assign Sy[3] = 3'b000;
assign Sy[4] = 3'b000;
assign Sy[5] = 3'b000;
assign Sy[6] = 3'b001;
assign Sy[7] = 3'b010;
assign Sy[8] = 3'b001;	

always @(posedge clk or posedge rst) begin
	if(rst)
		cstate <= L0_READ;
	else
		cstate <= nstate;	
end

always @(posedge clk or posedge rst) begin
	if(rst)begin
		iaddr <= 0;
		counter <= 0;
		iaddr_counter <= 0;
		x <= 0;
		y <= 0;
		caddr_mag_0 <= 0;
		caddr_ang_0 <= 0;
		caddr_1 <= 0;
		caddr_2 <= 0;
		flag <= 0;
	end
	else begin
		case(cstate)
			L0_READ:begin
				done <= 0;
				ird <= 1;
				if(counter == 10)
					counter <= 0;
				else
					counter <= counter + 1;
              	case(counter)
					0:begin
						iaddr <= iaddr_counter;
					end
					1:begin
						iaddr <= iaddr_counter + 1;                
					end      
					2:begin
						iaddr <= iaddr_counter + 2;                   
						buffer[0] <= idata;      
					end
					3:begin
						iaddr <= iaddr_counter + 128;  
						buffer[1] <= idata;    				                  
					end  
					4:begin
						iaddr <= iaddr_counter + 129;
						buffer[2] <= idata;                   
					end
					5:begin
						iaddr <= iaddr_counter + 130;
						buffer[3] <= idata;                   
					end      
					6:begin
						iaddr <= iaddr_counter + 256;
						buffer[4] <= idata;                         
					end
					7:begin
						iaddr <= iaddr_counter + 257;
						buffer[5] <= idata;                      
					end        
					8:begin
						iaddr <= iaddr_counter + 258;
						buffer[6] <= idata;                     
					end
					9:begin
						buffer[7] <= idata;                      
					end                       
					10:begin
						ird <= 0;
						cwr_mag_0 <= 1;
						cwr_ang_0 <= 1;
						buffer[8] <= idata;                      
					end    				                                                    
              	endcase  					
			end	
			L0_WRITE:begin
				cwr_mag_0 <= 0;
				cwr_ang_0 <= 0;		

				if(caddr_mag_0 == 15875)
					caddr_mag_0 <= 0;
				else
					caddr_mag_0 <= caddr_mag_0 + 1;	

				if(caddr_ang_0 == 15875)
					caddr_ang_0 <= 0;
				else
					caddr_ang_0 <= caddr_ang_0 + 1;										

				if(x == 125)begin
					x <= 0;
					if(y == 125)begin
						y <= 0;
					end
					else
						y <= y + 1;
				end
				else
					x <= x + 1;				
			end
			L1_READ:begin
				if(y == 0 || y == 125 || x == 0 || x == 125)begin
					cwr1 <= 1;
					cdata_wr1 <= 0;
				end
				else begin
					if(counter == 6)
						counter <= 0;
					else
						counter <= counter + 1;						
					case(counter)
						0:begin
							crd_ang_0 <= 1;	
						end
						1:begin
							crd_mag_0 <= 1;
							case(cdata_ang_rd0)
								13'd0:begin
									caddr_mag_0 <= caddr_1 - 1;
								end
								13'd45:begin
									caddr_mag_0 <= caddr_1 - 125;
								end
								13'd90:begin
									caddr_mag_0 <= caddr_1 - 126;
								end
								13'd135:begin
									caddr_mag_0 <= caddr_1 - 127;									
								end										
							endcase
						end
						2:begin
							caddr_mag_0 <= caddr_1;																									
						end
						3:begin
							buffer2[0] <= cdata_mag_rd0;		
							case(cdata_ang_rd0)
								13'd0:begin
									caddr_mag_0 <= caddr_1 + 1;
								end
								13'd45:begin
									caddr_mag_0 <= caddr_1 + 125;								
								end
								13'd90:begin
									caddr_mag_0 <= caddr_1 + 126;							
								end
								13'd135:begin
									caddr_mag_0 <= caddr_1 + 127;								
								end																								
							endcase							
						end		
						4:begin
							buffer2[1] <= cdata_mag_rd0;																													
						end
						5:begin
							crd_mag_0 <= 0;
							crd_ang_0 <= 0;
							buffer2[2] <= cdata_mag_rd0;																													
						end						
						6:begin
							cwr1 <= 1;
							if(buffer2[1] >= buffer2[0] && buffer2[1] >= buffer2[2])
								cdata_wr1 <= buffer2[1];
							else
								cdata_wr1 <= 0;																								
						end																		
					endcase		
				end
			end
			L1_WRITE:begin
				cwr1 <= 0;
				if(x == 125)begin
					x <= 0;
					if(y == 125)begin
						y <= 0;
					end
					else
						y <= y + 1;
				end
				else
					x <= x + 1;	

				if(caddr_1 == 15875)begin
					caddr_1 <= 0;
				end
				else
					caddr_1 <= caddr_1 + 1;			

				if(caddr_ang_0 == 15875)begin
					caddr_ang_0 <= 0;
				end
				else
					caddr_ang_0 <= caddr_ang_0 + 1;								
			end			
			L2_READ:begin
				if(y == 0 || y == 125 || x == 0 || x == 125)begin
					cwr2 <= 1;
					cdata_wr2 <= 0;
				end
				else begin
					if(counter == 12)
						counter <= 0;
					else
						counter <= counter + 1;						
					case(counter)
						0:begin
							crd1 <= 1;
							caddr_1 <= caddr_2;
						end
						1:begin			
						end
						2:begin
							if(cdata_rd1 >= 13'd100)begin
								flag <= 1;
								cwr2 <= 1;
								crd1 <= 0;
								cdata_wr2 <= 255;
							end
							else if(cdata_rd1 < 13'd50)begin
								flag <= 1;
								cwr2 <= 1;
								crd1 <= 0;
								cdata_wr2 <= 0;								
							end
							else begin
								caddr_1 <= caddr_2 - 127;
							end
						end		
						3:begin
							caddr_1 <= caddr_2 - 126;																													
						end
						4:begin
							caddr_1 <= caddr_2 - 125;
							buffer2[0] <= cdata_rd1;
						end						
						5:begin
							caddr_1 <= caddr_2 - 1;
							buffer2[1] <= cdata_rd1;																						
						end							
						6:begin
							caddr_1 <= caddr_2 + 1;
							buffer2[2] <= cdata_rd1;																						
						end	
						7:begin
							caddr_1 <= caddr_2 + 125;
							buffer2[3] <= cdata_rd1;																						
						end													
						8:begin
							caddr_1 <= caddr_2 + 126;
							buffer2[5] <= cdata_rd1;																						
						end		
						9:begin
							caddr_1 <= caddr_2 + 127;
							buffer2[6] <= cdata_rd1;																						
						end						
						10:begin
							buffer2[7] <= cdata_rd1;																						
						end		
						11:begin
							crd1 <= 0;					
							buffer2[8] <= cdata_rd1;																						
						end		
						12:begin
							cwr2 <= 1;
							if(buffer2[0] >= 13'd100 || buffer2[1] >= 13'd100 || buffer2[2] >= 13'd100 || buffer2[3] >= 13'd100 || buffer2[5] >= 13'd100 || buffer2[6] >= 13'd100 || buffer2[7] >= 13'd100 || buffer2[8] >= 13'd100)
								cdata_wr2 <= 255;
							else
								cdata_wr2 <= 0;
						end								
					endcase		
				end				
			end
			L2_WRITE:begin
				cwr2 <= 0;
				counter <= 0;
				flag <= 0;
				if(x == 125)begin
					x <= 0;
					if(y == 125)begin
						y <= 0;
					end
					else
						y <= y + 1;
				end
				else
					x <= x + 1;	

				if(caddr_2 == 15875)begin
					caddr_2 <= 0;
					done <= 1;
				end
				else
					caddr_2 <= caddr_2 + 1;			
			end											
		endcase
	end
end

always @(*) begin	
	case(cstate)
		L0_READ:begin
			if(counter == 10)
				nstate = L0_WRITE;
			else
				nstate = L0_READ;
		end
		L0_WRITE:begin
			if(x == 125 && y == 125)
				nstate = L1_READ;
			else
				nstate = L0_READ;
		end	
		L1_READ:begin
			if((y == 0 || y == 125 || x == 0 || x == 125) || counter == 6)
				nstate = L1_WRITE;
			else
				nstate = L1_READ;
		end
		L1_WRITE:begin
			if(x == 125 && y == 125)
				nstate = L2_READ;
			else
				nstate = L1_READ;
		end			
		L2_READ:begin
			if((y == 0 || y == 125 || x == 0 || x == 125) || flag == 1 || counter == 12)
				nstate = L2_WRITE;
			else
				nstate = L2_READ;
		end
		L2_WRITE:begin
			nstate = L2_READ;
		end						
	endcase	
end

always @(*) begin
	Gx_conv_buffer[0] = $signed({0, buffer[0]}) * Sx[0];
	Gx_conv_buffer[1] = $signed({0, buffer[1]}) * Sx[1];
	Gx_conv_buffer[2] = $signed({0, buffer[2]}) * Sx[2];
	Gx_conv_buffer[3] = $signed({0, buffer[3]}) * Sx[3];
	Gx_conv_buffer[4] = $signed({0, buffer[4]}) * Sx[4];
	Gx_conv_buffer[5] = $signed({0, buffer[5]}) * Sx[5];
	Gx_conv_buffer[6] = $signed({0, buffer[6]}) * Sx[6];
	Gx_conv_buffer[7] = $signed({0, buffer[7]}) * Sx[7];
	Gx_conv_buffer[8] = $signed({0, buffer[8]}) * Sx[8];		

	Gy_conv_buffer[0] = $signed({0, buffer[0]}) * Sy[0];
	Gy_conv_buffer[1] = $signed({0, buffer[1]}) * Sy[1];
	Gy_conv_buffer[2] = $signed({0, buffer[2]}) * Sy[2];
	Gy_conv_buffer[3] = $signed({0, buffer[3]}) * Sy[3];
	Gy_conv_buffer[4] = $signed({0, buffer[4]}) * Sy[4];
	Gy_conv_buffer[5] = $signed({0, buffer[5]}) * Sy[5];
	Gy_conv_buffer[6] = $signed({0, buffer[6]}) * Sy[6];
	Gy_conv_buffer[7] = $signed({0, buffer[7]}) * Sy[7];
	Gy_conv_buffer[8] = $signed({0, buffer[8]}) * Sy[8];		

	Gx = Gx_conv_buffer[0] + Gx_conv_buffer[1] + Gx_conv_buffer[2] + Gx_conv_buffer[3] + Gx_conv_buffer[4] + Gx_conv_buffer[5] + Gx_conv_buffer[6] + Gx_conv_buffer[7] + Gx_conv_buffer[8];
	Gy = Gy_conv_buffer[0] + Gy_conv_buffer[1] + Gy_conv_buffer[2] + Gy_conv_buffer[3] + Gy_conv_buffer[4] + Gy_conv_buffer[5] + Gy_conv_buffer[6] + Gy_conv_buffer[7] + Gy_conv_buffer[8];

	Gx_abs = Gx[12] ? ~Gx + 1 : Gx;
	Gy_abs = Gy[12] ? ~Gy + 1 : Gy;

	cdata_mag_wr0 = Gx_abs + Gy_abs;	

	if(Gx == 13'd0)begin
		if(Gy == 13'd0)
			cdata_ang_wr0 = 13'd0;
		else
			cdata_ang_wr0 = 13'd90;			
	end
	else begin
		temp_result = (Gy << 16) / Gx;
		if(temp_result < $signed(29'h00006a09) && temp_result > $signed(29'h1fff95f7))
			cdata_ang_wr0 = 13'd0;
		else if(temp_result > $signed(29'h00006a09) && temp_result < $signed(29'h00026a09))
			cdata_ang_wr0 = 13'd45;
		else if(temp_result > $signed(29'h00026a09) || temp_result < $signed(29'h1ffd95f7))
			cdata_ang_wr0 = 13'd90;
		else
			cdata_ang_wr0 = 13'd135;			
	end
end

always @(*) begin
	iaddr_counter = 128*y + x;	
end

endmodule