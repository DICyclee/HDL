module ALU(
  input signed [15:0] src_A_i,
  input signed [15:0] src_B_i,
  input  [2:0]  inst_i,
  input  [7:0]  sortNum1_i,
  input  [7:0]  sortNum2_i,
  input  [7:0]  sortNum3_i,
  input  [7:0]  sortNum4_i,
  input  [7:0]  sortNum5_i,
  input  [7:0]  sortNum6_i,
  input  [7:0]  sortNum7_i,
  input  [7:0]  sortNum8_i,
  input  [7:0]  sortNum9_i,
  output reg [7:0]  sortNum1_o,
  output reg [7:0]  sortNum2_o,
  output reg [7:0]  sortNum3_o,
  output reg [7:0]  sortNum4_o,
  output reg [7:0]  sortNum5_o,
  output reg [7:0]  sortNum6_o,
  output reg [7:0]  sortNum7_o,
  output reg [7:0]  sortNum8_o,
  output reg [7:0]  sortNum9_o,
  output reg signed [15:0] data_o
);

reg signed [15:0] add_temp;

reg signed [15:0] sub_temp;

reg signed [31:0] mul_max_32;
reg signed [31:0] mul_min_32;
reg signed [31:0] mul;

reg signed [15:0] gelu_first_const_1;
reg signed [47:0] gelu_first_const_2;
reg signed [15:0] gelu_first_const_3;

reg signed [15:0] tanh_const_1;
reg signed [15:0] tanh_const_2;

reg signed [15:0] tanh_boundary_1;
reg signed [15:0] tanh_boundary_2;
reg signed [15:0] tanh_boundary_3;
reg signed [15:0] tanh_boundary_4;

reg signed [31:0] gelu_max_32;
reg signed [31:0] gelu_min_32;
reg signed [79:0] gelu_max_80;
reg signed [79:0] gelu_min_80;

reg signed [15:0] gelu_temp16;
reg signed [31:0] gelu_temp32;
reg signed [79:0] gelu_temp80;

reg [7:0] buffer [1:9];
reg [7:0] buffer_temp;

always @(*) begin
  case(inst_i)
    3'b000:begin // Signed Addition  
      add_temp = src_A_i + src_B_i;
      if((add_temp > 0) && (src_A_i < 0) && (src_B_i < 0))
        data_o = 16'b100000_0000000000;
      else if((add_temp < 0) && (src_A_i > 0) && (src_B_i > 0))
        data_o = 16'b011111_1111111111;
      else
        data_o = add_temp;                
    end
    3'b001:begin // Signed Subtraction
      sub_temp = src_A_i - src_B_i;
      if((sub_temp > 0) && (src_A_i < 0) && (src_B_i > 0))
        data_o = 16'b100000_0000000000;
      else if((sub_temp < 0) && (src_A_i > 0) && (src_B_i < 0))
        data_o = 16'b011111_1111111111;
      else
        data_o = sub_temp;          
    end   
    3'b010:begin // Signed Multiplication
      // 將16bits的最大值跟最小值擴展到32bits，以便拿來做比較    
      mul_max_32 = 32'b000000_011111_1111111111_0000000000;
      mul_min_32 = 32'b111111_100000_0000000000_0000000000;
      mul = src_A_i * src_B_i;
      // rounding
      if((mul[9:0] > 10'b1000000000) || ((mul[9:0] == 10'b1000000000) && (mul[10] == 1)))
        mul = mul + 11'b10000000000;
      else
        mul = mul;
      // saturation
      if(mul > mul_max_32)
        data_o = 16'b011111_1111111111;
      else if(mul < mul_min_32)
        data_o = 16'b100000_0000000000;             
      else
        data_o = mul[25:10];        
    end  
    3'b011: begin // GeLU
        gelu_first_const_1 = 16'b000000_0000101110; // 0.044921875
        gelu_first_const_2 = 48'b000000_000000_000001_0000000000_0000000000_0000000000; // 1
        gelu_first_const_3 = 16'b000000_1100110001; // 0.7978515625

        tanh_boundary_1 = 16'b111110_1000000000; // -1.5
        tanh_boundary_2 = 16'b111111_1000000000; // -0.5
        tanh_boundary_3 = 16'b000000_1000000000; //  0.5
        tanh_boundary_4 = 16'b000001_1000000000; //  1.5 

        tanh_const_1 = 16'b111111_0000000000; // -1
        tanh_const_2 = 16'b000001_0000000000; // 1

        // 將16bits的最大值跟最小值擴展到32bits和80bits，以便拿來計算或做比較 
        gelu_max_32 = 32'b000000_011111_1111111111_0000000000;
        gelu_min_32 = 32'b111111_100000_0000000000_0000000000;
        gelu_max_80 = 80'b000000_000000_000000_000000_011111_1111111111_0000000000_0000000000_0000000000_0000000000;
        gelu_min_80 = 80'b111111_111111_111111_111111_100000_0000000000_0000000000_0000000000_0000000000_0000000000;       
        
        gelu_temp80 = gelu_first_const_3 * src_A_i * (gelu_first_const_2 + gelu_first_const_1 * (src_A_i * src_A_i)); // 進行第一步的GeLU計算 : 0.7978515625 ∗ x ∗ (1 + 0.044921875 ∗ x^2)

        // first rounding
        if((gelu_temp80[39:0] > 40'b1000000000_0000000000_0000000000_0000000000) || ((gelu_temp80[39:0] == 40'b1000000000_0000000000_0000000000_0000000000) && (gelu_temp80[40] == 1)))
            gelu_temp80 = gelu_temp80 + 41'b1_0000000000_0000000000_0000000000_0000000000;
        else
            gelu_temp80 = gelu_temp80;
        if(gelu_temp80 > gelu_max_80)
            gelu_temp16 = 16'b011111_1111111111;
        else if(gelu_temp80 < gelu_min_80)
            gelu_temp16 = 16'b100000_0000000000; 
        else
            gelu_temp16 = gelu_temp80[55:40];
        
        // tanh() calculation and rounding 
        if(gelu_temp16 <= tanh_boundary_1)begin
            gelu_temp16 = tanh_const_1; // linear equation : y = -1
        end
        else if(gelu_temp16 <= tanh_boundary_2) begin
            if((gelu_temp16[0] == 1) && (gelu_temp16[1] == 1)) // 這個case要進行rounding
                gelu_temp16 = (gelu_temp16 >>> 1) + $signed(16'b111111_1100000000) + $signed(16'b000000_0000000001); // linear equation : y = 0.5x - 0.25
            else
                gelu_temp16 = (gelu_temp16 >>> 1) + $signed(16'b111111_1100000000); // linear equation : y = 0.5x - 0.25
        end
        else if(gelu_temp16 <= tanh_boundary_3)begin
            gelu_temp16 = gelu_temp16; // linear equation : y = x
        end
        else if(gelu_temp16 <= tanh_boundary_4) begin
            if(gelu_temp16[0] == 1 && gelu_temp16[1] == 1) // 這個case要進行rounding
                gelu_temp16 = (gelu_temp16 >>> 1) + $signed(16'b000000_0100000000) + $signed(16'b000000_0000000001); // linear equation : y = 0.5x + 0.25
            else
                gelu_temp16 = (gelu_temp16 >>> 1) + $signed(16'b000000_0100000000); // linear equation : y = 0.5x + 0.25            
        end
        else 
            gelu_temp16 = tanh_const_2;

        // 進行剩下的GeLU計算 : 0.5 ∗ x ∗ (1 + gelu_temp16)
        gelu_temp16 = gelu_temp16 + $signed(16'b000001_0000000000);
        gelu_temp32 = (gelu_temp16 * src_A_i);
        gelu_temp32 = (gelu_temp32 >>> 1);
        
        // final rounding
        if((gelu_temp32[9:0] > 10'b1000000000) || ((gelu_temp32[9:0] == 10'b1000000000) && (gelu_temp32[10] == 1)))
            gelu_temp32 = gelu_temp32 + 11'b10000000000;
        else
            gelu_temp32 = gelu_temp32;
        if(gelu_temp32 > gelu_max_32)
            data_o = 16'b011111_1111111111;
        else if(gelu_temp32 < gelu_min_32)
            data_o = 16'b011111_1111111111;
        else
            data_o = gelu_temp32[25:10];
    end
    3'b100:begin // CLZ
      if(src_A_i[15] == 0)begin
        data_o = 1;
        if(src_A_i[14] == 0)begin
          data_o = 2;
          if(src_A_i[13] == 0)begin
            data_o = 3;
            if(src_A_i[12] == 0)begin
              data_o = 4;
              if(src_A_i[11] == 0)begin
                data_o = 5;
                if(src_A_i[10] == 0)begin
                  data_o = 6;
                  if(src_A_i[9] == 0)begin
                    data_o = 7;
                    if(src_A_i[8] == 0)begin
                      data_o = 8;
                      if(src_A_i[7] == 0)begin
                        data_o = 9;
                        if(src_A_i[6] == 0)begin
                          data_o = 10;
                          if(src_A_i[5] == 0)begin
                            data_o = 11;
                            if(src_A_i[4] == 0)begin
                              data_o = 12;
                              if(src_A_i[3] == 0)begin
                                data_o = 13;
                                if(src_A_i[2] == 0)begin
                                  data_o = 14;
                                  if(src_A_i[1] == 0)begin
                                    data_o = 15;
                                    if(src_A_i[0] == 0)begin
                                      data_o = 16;
                                    end
                                    else begin
                                      data_o = 15;
                                    end                                         
                                  end
                                  else begin
                                    data_o = 14;
                                  end                                        
                                end
                                else begin
                                  data_o = 13;
                                end                                  
                              end
                              else begin
                                data_o = 12;
                              end                                    
                            end
                            else begin
                              data_o = 11;
                            end                                 
                          end
                          else begin
                            data_o = 10;
                          end                                                        
                        end
                        else begin
                          data_o = 9;
                        end                              
                      end
                      else begin
                        data_o = 8;
                      end                     
                    end                      
                    else begin
                      data_o = 7;
                    end                     
                  end
                  else begin
                    data_o = 6;
                  end                   
                end
                else begin
                  data_o = 5;
                end                    
              end
              else begin
                data_o = 4;
              end                      
            end
            else begin
              data_o = 3;
            end            
          end
          else begin
            data_o = 2;
           end          
        end
        else begin
          data_o = 1;
        end
      end
      else begin
        data_o = 0;
      end
    end   
    3'b101:begin // Sort nine numbers

        // Bitonic Sorting
        // 由於bitonic sorting只能處理長度為2的冪次的陣列，因此我會先對前八個elements做排序，最後再將第九個element插入已經排序好的前八個elements中

        // 將輸入的九個數字賦值給buffer來做排序
        buffer[1] = sortNum1_i;
        buffer[2] = sortNum2_i;
        buffer[3] = sortNum3_i;
        buffer[4] = sortNum4_i;
        buffer[5] = sortNum5_i;                         
        buffer[6] = sortNum6_i;
        buffer[7] = sortNum7_i;
        buffer[8] = sortNum8_i;
        buffer[9] = sortNum9_i;

        // First round
        // Sort every two elements ascending and descending (only the first eight elements are processed) 
        if(buffer[1] < buffer[2])begin
            buffer[1] = buffer[1];
            buffer[2] = buffer[2];
        end
        else begin
            buffer_temp = buffer[1];
            buffer[1] = buffer[2];
            buffer[2] = buffer_temp;
        end
        if(buffer[3] < buffer[4])begin
            buffer_temp = buffer[3];
            buffer[3] = buffer[4];
            buffer[4] = buffer_temp;
        end
        else begin
            buffer[3] = buffer[3];
            buffer[4] = buffer[4];
        end
        if(buffer[5] < buffer[6])begin
            buffer[5] = buffer[5];
            buffer[6] = buffer[6];
        end
        else begin
            buffer_temp = buffer[5];
            buffer[5] = buffer[6];
            buffer[6] = buffer_temp;
        end
        if(buffer[7] < buffer[8])begin
            buffer_temp = buffer[7];
            buffer[7] = buffer[8];
            buffer[8] = buffer_temp;
        end
        else begin
            buffer[7] = buffer[7];
            buffer[8] = buffer[8];
        end                        

        // Second round
        // Sort every four elements ascending and descending, and then sort every two elements (only the first eight elements are processed)
        if(buffer[1] < buffer[3])begin
            buffer[1] = buffer[1];
            buffer[3] = buffer[3];
        end
        else begin
            buffer_temp = buffer[1];
            buffer[1] = buffer[3];
            buffer[3] = buffer_temp;
        end
        if(buffer[2] < buffer[4])begin
            buffer[2] = buffer[2];
            buffer[4] = buffer[4];
        end
        else begin
            buffer_temp = buffer[2];
            buffer[2] = buffer[4];
            buffer[4] = buffer_temp;
        end
        if(buffer[5] < buffer[7])begin
            buffer_temp = buffer[5];
            buffer[5] = buffer[7];
            buffer[7] = buffer_temp;
        end
        else begin
            buffer[5] = buffer[5];
            buffer[7] = buffer[7];
        end
        if(buffer[6] < buffer[8])begin
            buffer_temp = buffer[6];
            buffer[6] = buffer[8];
            buffer[8] = buffer_temp;
        end
        else begin
            buffer_temp = buffer[7];
            buffer[6] = buffer[6];
            buffer[8] = buffer[8];
        end         

        if(buffer[1] < buffer[2])begin
            buffer[1] = buffer[1];
            buffer[2] = buffer[2];
        end
        else begin
            buffer_temp = buffer[1];
            buffer[1] = buffer[2];
            buffer[2] = buffer_temp;
        end
        if(buffer[3] < buffer[4])begin
            buffer[3] = buffer[3];
            buffer[4] = buffer[4];            
        end
        else begin
            buffer_temp = buffer[3];
            buffer[3] = buffer[4];
            buffer[4] = buffer_temp;
        end
        if(buffer[5] < buffer[6])begin
            buffer_temp = buffer[5];
            buffer[5] = buffer[6];
            buffer[6] = buffer_temp;
        end
        else begin
            buffer[5] = buffer[5];
            buffer[6] =  buffer[6];
        end
        if(buffer[7] < buffer[8])begin
            buffer_temp = buffer[7];
            buffer[7] = buffer[8];
            buffer[8] = buffer_temp;
        end
        else begin
            buffer[7] = buffer[7];
            buffer[8] = buffer[8];
        end        

        // Third round
        // Sort all eight elements ascending and descending, then every four, and finally every two (only the first eight elements are processed)
        if(buffer[1] < buffer[5])begin
            buffer[1] = buffer[1];
            buffer[5] = buffer[5];
        end
        else begin
            buffer_temp = buffer[1];
            buffer[1] = buffer[5];
            buffer[5] = buffer_temp;
        end
        if(buffer[2] < buffer[6])begin
            buffer[2] = buffer[2];
            buffer[6] = buffer[6];
        end
        else begin
            buffer_temp = buffer[2];
            buffer[2] = buffer[6];
            buffer[6] = buffer_temp;
        end             
        if(buffer[3] < buffer[7])begin
            buffer[3] = buffer[3];
            buffer[7] = buffer[7];
        end
        else begin
            buffer_temp = buffer[3];
            buffer[3] = buffer[7];
            buffer[7] = buffer_temp;
        end  
        if(buffer[4] < buffer[8])begin
            buffer[4] = buffer[4];
            buffer[8] = buffer[8];
        end
        else begin
            buffer_temp = buffer[4];
            buffer[4] = buffer[8];
            buffer[8] = buffer_temp;
        end        

        if(buffer[1] < buffer[3])begin
            buffer[1] = buffer[1];
            buffer[3] = buffer[3];
        end
        else begin
            buffer_temp = buffer[1];
            buffer[1] = buffer[3];
            buffer[3] = buffer_temp;
        end
        if(buffer[2] < buffer[4])begin
            buffer[2] = buffer[2];
            buffer[4] = buffer[4];
        end
        else begin
            buffer_temp = buffer[2];
            buffer[2] = buffer[4];
            buffer[4] = buffer_temp;
        end             
        if(buffer[5] < buffer[7])begin
            buffer[5] = buffer[5];
            buffer[7] = buffer[7];
        end
        else begin
            buffer_temp = buffer[5];
            buffer[5] = buffer[7];
            buffer[7] = buffer_temp;
        end  
        if(buffer[6] < buffer[8])begin
            buffer[6] = buffer[6];
            buffer[8] = buffer[8];
        end
        else begin
            buffer_temp = buffer[6];
            buffer[6] = buffer[8];
            buffer[8] = buffer_temp;
        end        

        if(buffer[1] < buffer[2])begin
            buffer[1] = buffer[1];
            buffer[2] = buffer[2];
        end
        else begin
            buffer_temp = buffer[1];
            buffer[1] = buffer[2];
            buffer[2] = buffer_temp;
        end
        if(buffer[3] < buffer[4])begin
            buffer[3] = buffer[3];
            buffer[4] = buffer[4];            
        end
        else begin
            buffer_temp = buffer[3];
            buffer[3] = buffer[4];
            buffer[4] = buffer_temp;
        end          
        if(buffer[5] < buffer[6])begin
            buffer[5] = buffer[5];
            buffer[6] = buffer[6];
        end
        else begin
            buffer_temp = buffer[5];
            buffer[5] = buffer[6];
            buffer[6] = buffer_temp;
        end
        if(buffer[7] < buffer[8])begin
            buffer[7] = buffer[7];
            buffer[8] = buffer[8];            
        end
        else begin
            buffer_temp = buffer[7];
            buffer[7] = buffer[8];
            buffer[8] = buffer_temp;
        end     

        // Final round
        // Insert the last element into the sorted first eight elements
        if(buffer[8] < buffer[9])begin
            buffer[8] = buffer[8];
            buffer[9] = buffer[9];
        end
        else begin
            buffer_temp = buffer[8];
            buffer[8] = buffer[9];
            buffer[9] = buffer_temp;            
        end
        if(buffer[7] < buffer[8])begin
            buffer[7] = buffer[7];
            buffer[8] = buffer[8];
        end
        else begin
            buffer_temp = buffer[7];
            buffer[7] = buffer[8];
            buffer[8] = buffer_temp;            
        end
        if(buffer[6] < buffer[7])begin
            buffer[6] = buffer[6];
            buffer[7] = buffer[7];
        end
        else begin
            buffer_temp = buffer[6];
            buffer[6] = buffer[7];
            buffer[7] = buffer_temp;            
        end
        if(buffer[5] < buffer[6])begin
            buffer[5] = buffer[5];
            buffer[6] = buffer[6];
        end
        else begin
            buffer_temp = buffer[5];
            buffer[5] = buffer[6];
            buffer[6] = buffer_temp;            
        end        
        if(buffer[4] < buffer[5])begin
            buffer[4] = buffer[4];
            buffer[5] = buffer[5];
        end
        else begin
            buffer_temp = buffer[4];
            buffer[4] = buffer[5];
            buffer[5] = buffer_temp;            
        end        
        if(buffer[3] < buffer[4])begin
            buffer[3] = buffer[3];
            buffer[4] = buffer[4];
        end
        else begin
            buffer_temp = buffer[3];
            buffer[3] = buffer[4];
            buffer[4] = buffer_temp;            
        end           
        if(buffer[2] < buffer[3])begin
            buffer[2] = buffer[2];
            buffer[3] = buffer[3];
        end
        else begin
            buffer_temp = buffer[2];
            buffer[2] = buffer[3];
            buffer[3] = buffer_temp;            
        end         
        if(buffer[1] < buffer[2])begin
            buffer[1] = buffer[1];
            buffer[2] = buffer[2];
        end
        else begin
            buffer_temp = buffer[1];
            buffer[1] = buffer[2];
            buffer[2] = buffer_temp;            
        end    

        // 將最後排序好的buffer的數字賦值給輸出訊號
        sortNum1_o = buffer[1];
        sortNum2_o = buffer[2];
        sortNum3_o = buffer[3];
        sortNum4_o = buffer[4];
        sortNum5_o = buffer[5];
        sortNum6_o = buffer[6];
        sortNum7_o = buffer[7];
        sortNum8_o = buffer[8];
        sortNum9_o = buffer[9];                         
    end         
  endcase    
end
endmodule