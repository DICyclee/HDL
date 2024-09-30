module geofence ( clk,reset,X,Y,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
output reg valid;
output reg is_inside;

reg [2:0] cstate;
reg [2:0] nstate;
reg [9:0] xt [0:7];
reg [9:0] yt [0:7];
reg signed [10:0] tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7, tmp8;
wire signed [10:0] tmp1_minus_tmp2 = tmp1 - tmp2;
wire signed [10:0] tmp3_minus_tmp4 = tmp3 - tmp4;
wire signed [10:0] tmp5_minus_tmp6 = tmp5 - tmp6;
wire signed [10:0] tmp7_minus_tmp8 = tmp7 - tmp8;
wire signed [20:0] front_result, back_result;
reg [2:0] cnt;
reg [2:0] i;
reg [2:0] j;
reg qd[1:4];
wire flag1 = (qd[1] && !(qd[2] || qd[3] || qd[4])) || (qd[2] && !(qd[1] || qd[3] || qd[4])) || (qd[3] && !(qd[1] || qd[2] || qd[4])) || (qd[4] && !(qd[1] || qd[2] || qd[3]));
wire flag2 = (qd[1] && qd[2] && !(qd[3] || qd[4])) || (qd[2] && qd[3] && !(qd[1] || qd[4])) || (qd[3] && qd[4] && !(qd[1] || qd[2])) || (qd[4] && qd[1] && !(qd[2] || qd[3]));
wire flag3 = qd[1] && qd[2] && qd[3] && qd[4];

multiplier m1(tmp1_minus_tmp2, tmp3_minus_tmp4, front_result);
multiplier m2(tmp5_minus_tmp6, tmp7_minus_tmp8, back_result);

always @(*) begin
    tmp1 <= xt[i];   
    tmp7 <= yt[i]; 
    case(cstate)
        3:begin
            tmp2 <= xt[0];
            tmp4 <= yt[i]; 
            tmp6 <= xt[i];
            tmp8 <= yt[0];            
            if(i == 7)begin
                tmp3 <= yt[1];        
                tmp5 <= xt[1];                                   
            end
            else begin
                tmp3 <= yt[i + 1];
                tmp5 <= xt[i + 1];                                        
            end        
        end      
        default:begin
            tmp2 <= xt[1];
            tmp3 <= yt[i + 1];
            tmp4 <= yt[1];
            tmp5 <= xt[i + 1];
            tmp6 <= xt[1];
            tmp8 <= yt[1];
        end     
    endcase
end

always @(*) begin
    case (cstate)
        0:begin     
            nstate = 1;     
        end
        1:begin
            if(cnt == 7) 
                nstate = 2;
            else
                nstate = 1;             
        end
        2:begin
            if(flag1 || flag2 || flag3)
                nstate = 4;            
            else if(j == 6 && (back_result > front_result || i == 2))
                nstate = 3;
            else
                nstate = 2;
        end
        3:begin
            if(front_result > back_result || i == 7)
                nstate = 4;
            else
                nstate = 3;
        end
        default:begin
            nstate = 0;
        end 
    endcase
end

always @(posedge clk or posedge reset) begin
    if(reset)
        cstate <= 0;
    else
        cstate <= nstate;
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        valid <= 0;
        is_inside <= 1;        
        cnt <= 0;
        i <= 2;
        j <= 2;
        qd[1] <= 0;
        qd[2] <= 0;
        qd[3] <= 0;
        qd[4] <= 0;        
    end
    else begin
        case(cstate)
            0:begin     
                xt[cnt] <= X;
                yt[cnt] <= Y;
                cnt <= 1;                             
            end
            1:begin              
                xt[cnt] <= X;
                yt[cnt] <= Y;                
                cnt <= cnt + 1;
                if(X > xt[0] && Y > yt[0])
                    qd[1] <= 1;
                else if(X < xt[0] && Y > yt[0])
                    qd[2] <= 1;
                else if(X < xt[0] && Y < yt[0])
                    qd[3] <= 1;
                else if(X > xt[0] && Y < yt[0])
                    qd[4] <= 1;         
            end
            2:begin
                if(flag1 || flag2 || flag3)
                    valid <= 1;
                    if(flag1 || flag2)
                        is_inside <= 0;    
                else if(front_result > back_result) begin
                    xt[i] <= xt[i + 1];
                    xt[i + 1] <= xt[i];
                    yt[i] <= yt[i + 1];
                    yt[i + 1] <= yt[i];
                    if(i == 2)begin
                        i <= j + 1;
                        j <= j + 1;
                    end
                    else
                        i <= i - 1;
                end
                else begin
                    i <= j + 1;
                    j <= j + 1;
                end
                if(j == 6 && (back_result > front_result || i == 2))
                    i <= 1;                
            end
            3:begin
                if(front_result > back_result)begin
                    is_inside <= 0;
                    valid <= 1;                    
                end 
                else if(i == 7)
                    valid <= 1;
                i <= i + 1;
            end
            4:begin
                valid <= 0;
                is_inside <= 1;
                cnt <= 0;
                i <= 2;                
                j <= 2;
                qd[1] <= 0;
                qd[2] <= 0;
                qd[3] <= 0;
                qd[4] <= 0;                  
            end
        endcase
    end
end

endmodule

module multiplier(x, y, p);

input [10:0] x, y;
output [20:0] p;

wire [11:0] mul_tmp0 = {1'b1, !(y[10] & x[0]), {x[9:0] & {10{y[0]}}}};
wire [10:0] mul_tmp1 = {!(y[10] & x[1]), {x[9:0] & {10{y[1]}}}};
wire [10:0] mul_tmp2 = {!(y[10] & x[2]), {x[9:0] & {10{y[2]}}}};
wire [10:0] mul_tmp3 = {!(y[10] & x[3]), {x[9:0] & {10{y[3]}}}};
wire [10:0] mul_tmp4 = {!(y[10] & x[4]), {x[9:0] & {10{y[4]}}}};
wire [10:0] mul_tmp5 = {!(y[10] & x[5]), {x[9:0] & {10{y[5]}}}};
wire [10:0] mul_tmp6 = {!(y[10] & x[6]), {x[9:0] & {10{y[6]}}}};
wire [10:0] mul_tmp7 = {!(y[10] & x[7]), {x[9:0] & {10{y[7]}}}};
wire [10:0] mul_tmp8 = {!(y[10] & x[8]), {x[9:0] & {10{y[8]}}}};
wire [10:0] mul_tmp9 = {!(y[10] & x[9]), {x[9:0] & {10{y[9]}}}};
wire [11:0] mul_tmp10 = {1'b1, (y[10] & x[10]), {~(y[9:0] & {10{x[10]}})}};

assign p =  (mul_tmp0 + ({mul_tmp1, 1'b0} + {mul_tmp2, 2'b0})) + (({mul_tmp3, 3'b0} + {mul_tmp4, 4'b0}) + ({mul_tmp5, 5'b0} + {mul_tmp6, 6'b0})) + 
            (({mul_tmp7, 7'b0} + {mul_tmp8, 8'b0}) + ({mul_tmp9, 9'b0} + {mul_tmp10, 10'b0}));
            
endmodule