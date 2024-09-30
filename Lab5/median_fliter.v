module median_fliter(
  // input port
  input                  clk,
  input                  rst,
  input               enable,
  input  [7:0]     RAM_IMG_Q,
  input  [7:0]     RAM_OUT_Q,
  // output port
  output reg          RAM_IMG_OE,
  output reg          RAM_IMG_WE,
  output reg [15:0]   RAM_IMG_A,
  output reg [7:0]    RAM_IMG_D,
  output reg          RAM_OUT_OE,
  output reg          RAM_OUT_WE,
  output reg [15:0]   RAM_OUT_A,
  output reg [7:0]    RAM_OUT_D,
  output reg          done
);

reg [1:0] cstate;
reg [1:0] nstate;

reg [7:0] buffer [1:9];

reg [3:0] counter;

reg [7:0] x;
reg [7:0] y;

reg [7:0] buffer_sorting [1:9];
reg [7:0] buffer_sorting_temp;

parameter read = 0;
parameter padding = 1;
parameter write = 2;
parameter move = 3;

always@(posedge clk or posedge rst)begin
    if(rst)
        cstate <= read;
    else 
        cstate <= nstate;
end

always@(posedge clk or posedge rst)begin
    if(rst)begin
      RAM_OUT_A <= 0;
      x <= 0;
      y <= 0;     
      done <= 0; 
      counter <= 0;
    end
    else begin
        case(cstate)
            read:begin
              RAM_IMG_OE <= 1;
              if(counter == 10)
                counter <= 0;
              else
                counter <= counter + 1;
              case(counter)
                0:begin
                  RAM_IMG_A <= RAM_OUT_A - 257;
                end
                1:begin
                  RAM_IMG_A <= RAM_OUT_A - 256;              
                end      
                2:begin
                  RAM_IMG_A <= RAM_OUT_A - 255;
                  buffer[1] <= RAM_IMG_Q;                     
                end
                3:begin
                  RAM_IMG_A <= RAM_OUT_A - 1;
                  buffer[2] <= RAM_IMG_Q;                   
                end  
                4:begin
                  RAM_IMG_A <= RAM_OUT_A;
                  buffer[3] <= RAM_IMG_Q;                   
                end
                5:begin
                  RAM_IMG_A <= RAM_OUT_A + 1;
                  buffer[4] <= RAM_IMG_Q;                   
                end      
                6:begin
                  RAM_IMG_A <= RAM_OUT_A + 255;
                  buffer[5] <= RAM_IMG_Q;                       
                end
                7:begin
                  RAM_IMG_A <= RAM_OUT_A + 256;
                  buffer[6] <= RAM_IMG_Q;                    
                end        
                8:begin
                  RAM_IMG_A <= RAM_OUT_A + 257;
                  buffer[7] <= RAM_IMG_Q;                   
                end
                9:begin
                  buffer[8] <= RAM_IMG_Q;                    
                end        
                10:begin
                  RAM_IMG_OE <= 0;    
                  buffer[9] <= RAM_IMG_Q;               
                end                                                                       
              endcase    
            end   
            padding:begin
              if(y == 0)begin
                if(x == 0)begin
                  buffer[1] <= 0;
                  buffer[2] <= 0;
                  buffer[3] <= 0;
                  buffer[4] <= 0;
                  buffer[7] <= 0;                                                                        
                end
                else if(x == 255)begin
                  buffer[1] <= 0;
                  buffer[2] <= 0;
                  buffer[3] <= 0;
                  buffer[6] <= 0;
                  buffer[9] <= 0;                     
                end
                else begin
                  buffer[1] <= 0;
                  buffer[2] <= 0;
                  buffer[3] <= 0;                  
                end
              end
              else if(y == 255)begin
                if(x == 0)begin
                  buffer[1] <= 0;
                  buffer[4] <= 0;
                  buffer[7] <= 0;
                  buffer[8] <= 0;
                  buffer[9] <= 0;                   
                end
                else if(x == 255)begin
                  buffer[3] <= 0;
                  buffer[6] <= 0;
                  buffer[7] <= 0;
                  buffer[8] <= 0;
                  buffer[9] <= 0;                    
                end
                else begin
                  buffer[7] <= 0;
                  buffer[8] <= 0;
                  buffer[9] <= 0;                     
                end                
              end
              else if(x == 0)begin 
                buffer[1] <= 0;
                buffer[4] <= 0;
                buffer[7] <= 0; 
              end
              else if(x == 255)begin
                buffer[3] <= 0;
                buffer[6] <= 0;
                buffer[9] <= 0;               
              end
              else begin
                buffer[1] <= buffer[1];
                buffer[2] <= buffer[2];
                buffer[3] <= buffer[3];
                buffer[4] <= buffer[4];  
                buffer[5] <= buffer[5];
                buffer[6] <= buffer[6];
                buffer[7] <= buffer[7];
                buffer[8] <= buffer[8];          
                buffer[9] <= buffer[9];                                           
              end
            end               
            write:begin
              RAM_OUT_WE <= 1;
              RAM_OUT_D <= buffer_sorting[5];              
            end
            move:begin
              RAM_OUT_WE <= 0;
              RAM_OUT_A <= RAM_OUT_A + 1;
              if(RAM_OUT_A == 65535)
                done <= 1;
              if(x == 255)begin
                x <= 0;
                y <= y + 1;
              end
              else    
                x <= x + 1;                                
            end
        endcase 
    end
end


always@(*)begin
    case(cstate)
        read:begin
          if(counter == 10)
            nstate = padding;
          else
            nstate = read;
        end   
        padding:begin
           nstate = write;
        end               
        write:begin
           nstate = move;          
        end
        move:begin    
           nstate = read;                                
        end
        default:begin
           nstate = read;               
        end
    endcase 
end

always@(*)begin // Bitonic Sorting

    buffer_sorting[1] = buffer[1];
    buffer_sorting[2] = buffer[2];
    buffer_sorting[3] = buffer[3];        
    buffer_sorting[4] = buffer[4];
    buffer_sorting[5] = buffer[5];
    buffer_sorting[6] = buffer[6];    
    buffer_sorting[7] = buffer[7];
    buffer_sorting[8] = buffer[8];
    buffer_sorting[9] = buffer[9];            

    // First round
    // Sort every two elements ascending and descending (only the first eight elements are processed)   
    if(buffer_sorting[1] < buffer_sorting[2])begin
        buffer_sorting[1] = buffer_sorting[1];
        buffer_sorting[2] = buffer_sorting[2];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[1];
        buffer_sorting[1] = buffer_sorting[2];
        buffer_sorting[2] = buffer_sorting_temp;
    end
    if(buffer_sorting[3] < buffer_sorting[4])begin
        buffer_sorting_temp = buffer_sorting[3];
        buffer_sorting[3] = buffer_sorting[4];
        buffer_sorting[4] = buffer_sorting_temp;
    end
    else begin
        buffer_sorting[3] = buffer_sorting[3];
        buffer_sorting[4] = buffer_sorting[4];
    end
    if(buffer_sorting[5] < buffer_sorting[6])begin
        buffer_sorting[5] = buffer_sorting[5];
        buffer_sorting[6] = buffer_sorting[6];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[5];
        buffer_sorting[5] = buffer_sorting[6];
        buffer_sorting[6] = buffer_sorting_temp;
    end
    if(buffer_sorting[7] < buffer_sorting[8])begin
        buffer_sorting_temp = buffer_sorting[7];
        buffer_sorting[7] = buffer_sorting[8];
        buffer_sorting[8] = buffer_sorting_temp;
    end
    else begin
        buffer_sorting[7] = buffer_sorting[7];
        buffer_sorting[8] = buffer_sorting[8];
    end                        

    // Second round
    // Sort every four elements ascending and descending, and then sort every two elements (only the first eight elements are processed)
    if(buffer_sorting[1] < buffer_sorting[3])begin
        buffer_sorting[1] = buffer_sorting[1];
        buffer_sorting[3] = buffer_sorting[3];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[1];
        buffer_sorting[1] = buffer_sorting[3];
        buffer_sorting[3] = buffer_sorting_temp;
    end
    if(buffer_sorting[2] < buffer_sorting[4])begin
        buffer_sorting[2] = buffer_sorting[2];
        buffer_sorting[4] = buffer_sorting[4];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[2];
        buffer_sorting[2] = buffer_sorting[4];
        buffer_sorting[4] = buffer_sorting_temp;
    end
    if(buffer_sorting[5] < buffer_sorting[7])begin
        buffer_sorting_temp = buffer_sorting[5];
        buffer_sorting[5] = buffer_sorting[7];
        buffer_sorting[7] = buffer_sorting_temp;
    end
    else begin
        buffer_sorting[5] = buffer_sorting[5];
        buffer_sorting[7] = buffer_sorting[7];
    end
    if(buffer_sorting[6] < buffer_sorting[8])begin
        buffer_sorting_temp = buffer_sorting[6];
        buffer_sorting[6] = buffer_sorting[8];
        buffer_sorting[8] = buffer_sorting_temp;
    end
    else begin
        buffer_sorting_temp = buffer_sorting[7];
        buffer_sorting[6] = buffer_sorting[6];
        buffer_sorting[8] = buffer_sorting[8];
    end         

    if(buffer_sorting[1] < buffer_sorting[2])begin
        buffer_sorting[1] = buffer_sorting[1];
        buffer_sorting[2] = buffer_sorting[2];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[1];
        buffer_sorting[1] = buffer_sorting[2];
        buffer_sorting[2] = buffer_sorting_temp;
    end
    if(buffer_sorting[3] < buffer_sorting[4])begin
        buffer_sorting[3] = buffer_sorting[3];
        buffer_sorting[4] = buffer_sorting[4];            
    end
    else begin
        buffer_sorting_temp = buffer_sorting[3];
        buffer_sorting[3] = buffer_sorting[4];
        buffer_sorting[4] = buffer_sorting_temp;
    end
    if(buffer_sorting[5] < buffer_sorting[6])begin
        buffer_sorting_temp = buffer_sorting[5];
        buffer_sorting[5] = buffer_sorting[6];
        buffer_sorting[6] = buffer_sorting_temp;
    end
    else begin
        buffer_sorting[5] = buffer_sorting[5];
        buffer_sorting[6] =  buffer_sorting[6];
    end
    if(buffer_sorting[7] < buffer_sorting[8])begin
        buffer_sorting_temp = buffer_sorting[7];
        buffer_sorting[7] = buffer_sorting[8];
        buffer_sorting[8] = buffer_sorting_temp;
    end
    else begin
        buffer_sorting[7] = buffer_sorting[7];
        buffer_sorting[8] = buffer_sorting[8];
    end        

    // Third round
    // Sort all eight elements ascending and descending, then every four, and finally every two (only the first eight elements are processed)
    if(buffer_sorting[1] < buffer_sorting[5])begin
        buffer_sorting[1] = buffer_sorting[1];
        buffer_sorting[5] = buffer_sorting[5];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[1];
        buffer_sorting[1] = buffer_sorting[5];
        buffer_sorting[5] = buffer_sorting_temp;
    end
    if(buffer_sorting[2] < buffer_sorting[6])begin
        buffer_sorting[2] = buffer_sorting[2];
        buffer_sorting[6] = buffer_sorting[6];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[2];
        buffer_sorting[2] = buffer_sorting[6];
        buffer_sorting[6] = buffer_sorting_temp;
    end             
    if(buffer_sorting[3] < buffer_sorting[7])begin
        buffer_sorting[3] = buffer_sorting[3];
        buffer_sorting[7] = buffer_sorting[7];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[3];
        buffer_sorting[3] = buffer_sorting[7];
        buffer_sorting[7] = buffer_sorting_temp;
    end  
    if(buffer_sorting[4] < buffer_sorting[8])begin
        buffer_sorting[4] = buffer_sorting[4];
        buffer_sorting[8] = buffer_sorting[8];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[4];
        buffer_sorting[4] = buffer_sorting[8];
        buffer_sorting[8] = buffer_sorting_temp;
    end        

    if(buffer_sorting[1] < buffer_sorting[3])begin
        buffer_sorting[1] = buffer_sorting[1];
        buffer_sorting[3] = buffer_sorting[3];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[1];
        buffer_sorting[1] = buffer_sorting[3];
        buffer_sorting[3] = buffer_sorting_temp;
    end
    if(buffer_sorting[2] < buffer_sorting[4])begin
        buffer_sorting[2] = buffer_sorting[2];
        buffer_sorting[4] = buffer_sorting[4];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[2];
        buffer_sorting[2] = buffer_sorting[4];
        buffer_sorting[4] = buffer_sorting_temp;
    end             
    if(buffer_sorting[5] < buffer_sorting[7])begin
        buffer_sorting[5] = buffer_sorting[5];
        buffer_sorting[7] = buffer_sorting[7];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[5];
        buffer_sorting[5] = buffer_sorting[7];
        buffer_sorting[7] = buffer_sorting_temp;
    end  
    if(buffer_sorting[6] < buffer_sorting[8])begin
        buffer_sorting[6] = buffer_sorting[6];
        buffer_sorting[8] = buffer_sorting[8];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[6];
        buffer_sorting[6] = buffer_sorting[8];
        buffer_sorting[8] = buffer_sorting_temp;
    end        

    if(buffer_sorting[1] < buffer_sorting[2])begin
        buffer_sorting[1] = buffer_sorting[1];
        buffer_sorting[2] = buffer_sorting[2];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[1];
        buffer_sorting[1] = buffer_sorting[2];
        buffer_sorting[2] = buffer_sorting_temp;
    end
    if(buffer_sorting[3] < buffer_sorting[4])begin
        buffer_sorting[3] = buffer_sorting[3];
        buffer_sorting[4] = buffer_sorting[4];            
    end
    else begin
        buffer_sorting_temp = buffer_sorting[3];
        buffer_sorting[3] = buffer_sorting[4];
        buffer_sorting[4] = buffer_sorting_temp;
    end          
    if(buffer_sorting[5] < buffer_sorting[6])begin
        buffer_sorting[5] = buffer_sorting[5];
        buffer_sorting[6] = buffer_sorting[6];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[5];
        buffer_sorting[5] = buffer_sorting[6];
        buffer_sorting[6] = buffer_sorting_temp;
    end
    if(buffer_sorting[7] < buffer_sorting[8])begin
        buffer_sorting[7] = buffer_sorting[7];
        buffer_sorting[8] = buffer_sorting[8];            
    end
    else begin
        buffer_sorting_temp = buffer_sorting[7];
        buffer_sorting[7] = buffer_sorting[8];
        buffer_sorting[8] = buffer_sorting_temp;
    end     

    // Final round
    // Insert the last element into the sorted first eight elements
    if(buffer_sorting[8] < buffer_sorting[9])begin
        buffer_sorting[8] = buffer_sorting[8];
        buffer_sorting[9] = buffer_sorting[9];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[8];
        buffer_sorting[8] = buffer_sorting[9];
        buffer_sorting[9] = buffer_sorting_temp;            
    end
    if(buffer_sorting[7] < buffer_sorting[8])begin
        buffer_sorting[7] = buffer_sorting[7];
        buffer_sorting[8] = buffer_sorting[8];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[7];
        buffer_sorting[7] = buffer_sorting[8];
        buffer_sorting[8] = buffer_sorting_temp;            
    end
    if(buffer_sorting[6] < buffer_sorting[7])begin
        buffer_sorting[6] = buffer_sorting[6];
        buffer_sorting[7] = buffer_sorting[7];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[6];
        buffer_sorting[6] = buffer_sorting[7];
        buffer_sorting[7] = buffer_sorting_temp;            
    end
    if(buffer_sorting[5] < buffer_sorting[6])begin
        buffer_sorting[5] = buffer_sorting[5];
        buffer_sorting[6] = buffer_sorting[6];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[5];
        buffer_sorting[5] = buffer_sorting[6];
        buffer_sorting[6] = buffer_sorting_temp;            
    end        
    if(buffer_sorting[4] < buffer_sorting[5])begin
        buffer_sorting[4] = buffer_sorting[4];
        buffer_sorting[5] = buffer_sorting[5];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[4];
        buffer_sorting[4] = buffer_sorting[5];
        buffer_sorting[5] = buffer_sorting_temp;            
    end        
    if(buffer_sorting[3] < buffer_sorting[4])begin
        buffer_sorting[3] = buffer_sorting[3];
        buffer_sorting[4] = buffer_sorting[4];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[3];
        buffer_sorting[3] = buffer_sorting[4];
        buffer_sorting[4] = buffer_sorting_temp;            
    end           
    if(buffer_sorting[2] < buffer_sorting[3])begin
        buffer_sorting[2] = buffer_sorting[2];
        buffer_sorting[3] = buffer_sorting[3];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[2];
        buffer_sorting[2] = buffer_sorting[3];
        buffer_sorting[3] = buffer_sorting_temp;            
    end         
    if(buffer_sorting[1] < buffer_sorting[2])begin
        buffer_sorting[1] = buffer_sorting[1];
        buffer_sorting[2] = buffer_sorting[2];
    end
    else begin
        buffer_sorting_temp = buffer_sorting[1];
        buffer_sorting[1] = buffer_sorting[2];
        buffer_sorting[2] = buffer_sorting_temp;            
    end                            
end

endmodule