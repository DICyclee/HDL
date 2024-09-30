module PDC(
  // input port
  clk,
  rst,
  enable,
  RAM_i_Q,
  RAM_o_Q,
  // output port
  RAM_i_OE,
  RAM_i_WE,
  RAM_i_A,
  RAM_i_D,
  RAM_o_OE,
  RAM_o_WE,
  RAM_o_A,
  RAM_o_D,
  done
);

input clk;
input rst;
input enable;
input [7:0] RAM_i_Q;
input [7:0] RAM_o_Q;

output reg RAM_i_OE;
output reg RAM_i_WE;
output reg [17:0] RAM_i_A;
output reg [7:0] RAM_i_D;
output reg RAM_o_OE;
output reg RAM_o_WE;
output reg [17:0] RAM_o_A;
output reg [7:0] RAM_o_D;
output reg done;

reg [2:0] cstate;
reg [2:0] nstate;

reg signed [39:0] adj_A [0:15];
reg signed [71:0] det_A;
reg [7:0] x1, x2, x3, x4, y1, y2, y3, y4;
reg signed [103:0] A_inv [0:15];
reg signed [114:0] a, b, c, d, e, f, g, h;

reg [143:0] x_in_no_rounding;
reg [143:0] y_in_no_rounding;
reg [143:0] x_in_rounding;
reg [143:0] y_in_rounding;
reg [7:0] x_in;
reg [7:0] y_in;
reg [7:0] x_out;
reg [7:0] y_out;

reg [3:0] pixel_counter;
reg [3:0] step_counter;

reg delay; 

localparam IDLE = 0;
localparam READ_ADJ_A = 1;
localparam READ_DET_A = 2;
localparam READ_VERTEX = 3;
localparam READ_WRITE_IMAGE = 4;
localparam DONE = 5;

always @(posedge clk or posedge rst) begin
    if(rst)
        cstate <= IDLE;
    else
        cstate <= nstate;
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        RAM_i_OE <= 0;
        RAM_o_WE <= 0;
        RAM_i_A <= 0;
        step_counter <= 0;
        pixel_counter <= 0;
        delay <= 0;
        x_in <= 0;
        x_out <= 0;
        y_in <= 0;
        y_out <= 0;   
        done <= 0;     
    end
    else begin
        case(cstate)
            IDLE:begin
                done <= 0;
            end  
            READ_ADJ_A:begin
                if(!RAM_i_OE)
                    RAM_i_OE <= 1;
                else begin
                    RAM_i_A <= RAM_i_A + 1;
                    if(!delay)
                        delay <= 1;
                    else begin
                        if(step_counter == 4)begin
                            step_counter <= 0;
                            if(pixel_counter == 15)begin
                                pixel_counter <= 0;
                                delay <= 0;
                            end
                            else
                                pixel_counter <= pixel_counter + 1;
                        end
                        else
                            step_counter <= step_counter + 1;
                        case(step_counter)
                            0:begin
                                adj_A[pixel_counter][7:0] <= RAM_i_Q;
                            end
                            1:begin
                                adj_A[pixel_counter][15:8] <= RAM_i_Q;
                            end
                            2:begin
                                adj_A[pixel_counter][23:16] <= RAM_i_Q;
                            end
                            3:begin
                                adj_A[pixel_counter][31:24] <= RAM_i_Q;
                            end                                                       
                            4:begin
                                adj_A[pixel_counter][39:32] <= RAM_i_Q;
                            end                                              
                        endcase                         
                    end                   
                end                
            end 
            READ_DET_A:begin        
                RAM_i_A <= RAM_i_A + 1;
                if(step_counter == 8)
                    step_counter <= 0;
                else
                    step_counter <= step_counter + 1;
                case(step_counter)
                    0:begin
                        det_A[7:0] <= RAM_i_Q;
                    end
                    1:begin
                        det_A[15:8] <= RAM_i_Q;
                    end
                    2:begin
                        det_A[23:16] <= RAM_i_Q;
                    end
                    3:begin
                        det_A[31:24] <= RAM_i_Q;
                    end                                                       
                    4:begin
                        det_A[39:32] <= RAM_i_Q;
                    end   
                    5:begin
                        det_A[47:40] <= RAM_i_Q;
                    end
                    6:begin
                        det_A[55:48] <= RAM_i_Q;
                    end
                    7:begin
                        det_A[63:56] <= RAM_i_Q;
                    end
                    8:begin
                        det_A[71:64] <= RAM_i_Q;
                    end                                                       
                endcase                        
            end
            READ_VERTEX:begin
                if(RAM_i_A == 96)
                    RAM_i_A <= RAM_i_A;
                else
                    RAM_i_A <= RAM_i_A + 1;
                if(step_counter == 7)
                    step_counter <= 0;
                else
                    step_counter <= step_counter + 1;
                case(step_counter)
                    0:begin
                        x1 <= RAM_i_Q;
                    end
                    1:begin
                        y1 <= RAM_i_Q;
                    end
                    2:begin
                        x2 <= RAM_i_Q;
                    end
                    3:begin
                        y2 <= RAM_i_Q;
                    end                                                       
                    4:begin
                        x3 <= RAM_i_Q;
                    end   
                    5:begin
                        y3 <= RAM_i_Q;
                    end
                    6:begin
                        x4 <= RAM_i_Q;
                    end
                    7:begin
                        y4 <= RAM_i_Q;
                    end  
                endcase                  
            end
            READ_WRITE_IMAGE:begin
                RAM_o_WE <= 1;   
                if(step_counter == 4)
                    step_counter <= 0;
                else
                    step_counter <= step_counter + 1;                
                case(step_counter)
                    0:begin
                        RAM_i_A <= {y_in, x_in} + 97;                      
                    end
                    1:begin
                        RAM_i_A <= RAM_i_A + 65536;
                    end
                    2:begin
                        RAM_i_A <= RAM_i_A + 65536;
                        RAM_o_A <= {y_out, x_out};
                        RAM_o_D <= RAM_i_Q;                      
                    end
                    3:begin
                        RAM_o_A <= RAM_o_A + 65536;
                        RAM_o_D <= RAM_i_Q; 
                    end
                    4:begin
                        RAM_o_A <= RAM_o_A + 65536;
                        RAM_o_D <= RAM_i_Q;     
                        if(x_out == 255)begin
                            x_out <= 0;
                            if(y_out == 255)
                                y_out <= 0;
                            else begin
                                y_out <= y_out + 1;
                            end
                        end
                        else
                            x_out <= x_out + 1;                                                                    
                    end                                               
                endcase                 
            end
            DONE:begin
                done <= 1;
                RAM_i_A <= 0;
                RAM_o_A <= 0;
                RAM_i_OE <= 0;
                RAM_o_WE <= 0;
            end      
        endcase
    end
end

always @(*) begin
    case(cstate)
        IDLE:begin
            if(enable)
                nstate = READ_ADJ_A;
            else
                nstate = IDLE;
        end  
        READ_ADJ_A:begin
            if(step_counter == 4 && pixel_counter == 15)
                nstate = READ_DET_A;
            else
                nstate = READ_ADJ_A;
        end 
        READ_DET_A:begin    
            if(step_counter == 8)
                nstate = READ_VERTEX;
            else
                nstate = READ_DET_A;     
        end
        READ_VERTEX:begin
            if(step_counter == 7)
                nstate = READ_WRITE_IMAGE;
            else
                nstate = READ_VERTEX;    
        end
        READ_WRITE_IMAGE:begin
            if(x_out == 255 && y_out == 255 && step_counter == 4)
                nstate = DONE;
            else
                nstate = READ_WRITE_IMAGE;              
        end
        DONE:begin
            nstate = IDLE;
        end
        default:begin
            nstate = cstate;
        end
    endcase
end

always @(*) begin
    A_inv[0] = (adj_A[0] << 64) / det_A;
    A_inv[1] = (adj_A[1] << 64 ) / det_A;
    A_inv[2] = (adj_A[2] << 64 ) / det_A;
    A_inv[3] = (adj_A[3] << 64 ) / det_A;    
    A_inv[4] = (adj_A[4] << 64 ) / det_A;
    A_inv[5] = (adj_A[5] << 64 ) / det_A;
    A_inv[6] = (adj_A[6] << 64 ) / det_A;
    A_inv[7] = (adj_A[7] << 64 ) / det_A;
    A_inv[8] = (adj_A[8] << 64 ) / det_A;
    A_inv[9] = (adj_A[9] << 64 ) / det_A;
    A_inv[10] = (adj_A[10] << 64 ) / det_A;
    A_inv[11] = (adj_A[11] << 64 ) / det_A;
    A_inv[12] = (adj_A[12] << 64 ) / det_A;
    A_inv[13] = (adj_A[13] << 64 ) / det_A;
    A_inv[14] = (adj_A[14] << 64 ) / det_A; 
    A_inv[15] = (adj_A[15] << 64 ) / det_A;  

    a = A_inv[0] * $signed({0, x1}) + A_inv[1] * $signed({0, x2}) + A_inv[2] * $signed({0, x3}) + A_inv[3] * $signed({0, x4});
    b = A_inv[4] * $signed({0, x1}) + A_inv[5] * $signed({0, x2}) + A_inv[6] * $signed({0, x3}) + A_inv[7] * $signed({0, x4});
    c = A_inv[8] * $signed({0, x1}) + A_inv[9] * $signed({0, x2}) + A_inv[10] * $signed({0, x3}) + A_inv[11] * $signed({0, x4});
    d = A_inv[12] * $signed({0, x1}) + A_inv[13] * $signed({0, x2}) + A_inv[14] * $signed({0, x3}) + A_inv[15] * $signed({0, x4});
    e = A_inv[0] * $signed({0, y1}) + A_inv[1] * $signed({0, y2}) + A_inv[2] * $signed({0, y3}) + A_inv[3] * $signed({0, y4});
    f = A_inv[4] * $signed({0, y1}) + A_inv[5] * $signed({0, y2}) + A_inv[6] * $signed({0, y3}) + A_inv[7] * $signed({0, y4});
    g = A_inv[8] * $signed({0, y1}) + A_inv[9] * $signed({0, y2}) + A_inv[10] * $signed({0, y3}) + A_inv[11] * $signed({0, y4});
    h = A_inv[12] * $signed({0, y1}) + A_inv[13] * $signed({0, y2}) + A_inv[14] * $signed({0, y3}) + A_inv[15] * $signed({0, y4});

    x_in_no_rounding = a * x_out + b * y_out + c * x_out * y_out + d;
    y_in_no_rounding = e * x_out + f * y_out + g * x_out * y_out + h;   

    x_in_rounding = (x_in_no_rounding[31]) ? x_in_no_rounding + 32'h8000_0000 : x_in_no_rounding;
    y_in_rounding = (y_in_no_rounding[31]) ? y_in_no_rounding + 32'h8000_0000 : y_in_no_rounding;     

    x_in = x_in_rounding[39:32];
    y_in = y_in_rounding[39:32];   
end

endmodule