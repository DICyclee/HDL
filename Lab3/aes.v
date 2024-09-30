module aes(
    input              clk,
    input              rst,
    input              valid,
    input      [127:0] matrix1,
    input      [127:0] matrix2,
    output  reg  [1:0]   count,
    output  reg  [127:0] matrix3
);

reg [1:0] cstate;
reg [1:0] nstate;

reg [7:0] temp1 [0:3][0:3];
reg [7:0] temp2 [0:3][0:3];
reg [7:0] temp3 [0:3][0:3];
reg [7:0] temp4 [0:3][0:3];

parameter ADD_ROUND_KEY = 1;
parameter SHIFT_ROW = 2;
parameter MIX_COLUMNS = 3;

always @(posedge clk or posedge rst) begin
    if(rst)
        cstate <= ADD_ROUND_KEY;
    else
        cstate <= nstate;
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        count <= 0;
        matrix3 <= 0;     
    end
    else begin
        case(cstate)
            ADD_ROUND_KEY:begin
                if(valid)begin
                    count <= 1;
                    matrix3 <= matrix1 ^ matrix2;                 
                end
            end
            SHIFT_ROW:begin
                count <= 2;
                // fixed
                matrix3[127:120] <= matrix3[127:120];
                matrix3[95:88] <= matrix3[95:88];
                matrix3[63:56] <= matrix3[63:56];
                matrix3[31:24] <= matrix3[31:24];
                // left rotate 1
                matrix3[119:112] <= matrix3[87:80];
                matrix3[87:80] <= matrix3[55:48]; 
                matrix3[55:48] <= matrix3[23:16]; 
                matrix3[23:16] <= matrix3[119:112];
                // left rotate 2
                matrix3[111:104] <= matrix3[47:40];
                matrix3[79:72] <= matrix3[15:8]; 
                matrix3[47:40] <= matrix3[111:104];
                matrix3[15:8] <= matrix3[79:72];
                // left rotate 3
                matrix3[103:96] <= matrix3[7:0];
                matrix3[71:64] <= matrix3[103:96];
                matrix3[39:32] <= matrix3[71:64];
                matrix3[7:0] <= matrix3[39:32];                                                                         
            end
            MIX_COLUMNS:begin
                count <= 3;
                matrix3[127:120] <= temp1[0][0] ^ temp1[1][0] ^ temp1[2][0] ^ temp1[3][0];
                matrix3[95:88] <= temp1[0][1] ^ temp1[1][1] ^ temp1[2][1] ^ temp1[3][1];
                matrix3[63:56] <= temp1[0][2] ^ temp1[1][2] ^ temp1[2][2] ^ temp1[3][2];
                matrix3[31:24] <= temp1[0][3] ^ temp1[1][3] ^ temp1[2][3] ^ temp1[3][3];

                matrix3[119:112] <= temp2[0][0] ^ temp2[1][0] ^ temp2[2][0] ^ temp2[3][0];
                matrix3[87:80] <= temp2[0][1] ^ temp2[1][1] ^ temp2[2][1] ^ temp2[3][1];
                matrix3[55:48] <= temp2[0][2] ^ temp2[1][2] ^ temp2[2][2] ^ temp2[3][2];                                                                                 
                matrix3[23:16] <= temp2[0][3] ^ temp2[1][3] ^ temp2[2][3] ^ temp2[3][3];   
                
                matrix3[111:104] <= temp3[0][0] ^ temp3[1][0] ^ temp3[2][0] ^ temp3[3][0];
                matrix3[79:72] <= temp3[0][1] ^ temp3[1][1] ^ temp3[2][1] ^ temp3[3][1];
                matrix3[47:40] <= temp3[0][2] ^ temp3[1][2] ^ temp3[2][2] ^ temp3[3][2];                                                                                 
                matrix3[15:8] <= temp3[0][3] ^ temp3[1][3] ^ temp3[2][3] ^ temp3[3][3];

                matrix3[103:96] <= temp4[0][0] ^ temp4[1][0] ^ temp4[2][0] ^ temp4[3][0];
                matrix3[71:64] <= temp4[0][1] ^ temp4[1][1] ^ temp4[2][1] ^ temp4[3][1];
                matrix3[39:32] <= temp4[0][2] ^ temp4[1][2] ^ temp4[2][2] ^ temp4[3][2];                                                                            
                matrix3[7:0] <= temp4[0][3] ^ temp4[1][3] ^ temp4[2][3] ^ temp4[3][3];                  
            end                        
        endcase
    end
end

always @(*) begin
    case(cstate)
        ADD_ROUND_KEY:begin
            if(valid)
                nstate = SHIFT_ROW;
            else
                nstate = ADD_ROUND_KEY;        
        end
        SHIFT_ROW:begin
            nstate = MIX_COLUMNS;
        end
        MIX_COLUMNS:begin
            nstate = ADD_ROUND_KEY;
        end                        
    endcase
end

always @(*) begin
    // 2*matrix3[127:120] + 3*matrix3[119:112] + 1*matrix3[111:104] + 1*matrix3[103:96]
    temp1[0][0] = matrix3[127] ? (matrix3[127:120] << 1) ^ 8'b00011011 : matrix3[127:120] << 1;
    temp1[1][0] = matrix3[119] ? ((matrix3[119:112] << 1) ^ 8'b00011011) ^ matrix3[119:112] : (matrix3[119:112] << 1) ^ matrix3[119:112];
    temp1[2][0] = matrix3[111:104];
    temp1[3][0] = matrix3[103:96];

    // 2*matrix3[95:88] + 3*matrix3[87:80] + 1*matrix3[79:72] + 1*matrix3[71:64]
    temp1[0][1] = matrix3[95] ? (matrix3[95:88] << 1) ^ 8'b00011011 : matrix3[95:88] << 1;
    temp1[1][1] = matrix3[87] ? ((matrix3[87:80] << 1) ^ 8'b00011011) ^ matrix3[87:80] : (matrix3[87:80] << 1) ^ matrix3[87:80];
    temp1[2][1] = matrix3[79:72];
    temp1[3][1] = matrix3[71:64];     

    // 2*matrix3[63:56] + 3*matrix3[55:48] + 1*matrix3[47:40] + 1*matrix3[39:32]
    temp1[0][2] = matrix3[63] ? (matrix3[63:56] << 1) ^ 8'b00011011 : matrix3[63:56] << 1;
    temp1[1][2] = matrix3[55] ? ((matrix3[55:48] << 1) ^ 8'b00011011) ^ matrix3[55:48] : (matrix3[55:48] << 1) ^ matrix3[55:48];
    temp1[2][2] = matrix3[47:40];
    temp1[3][2] = matrix3[39:32];
    
    // 2*matrix3[31:24] + 3*matrix3[23:16] + 1*matrix3[15:8] + 1*matrix3[7:0]
    temp1[0][3] = matrix3[31] ? (matrix3[31:24] << 1) ^ 8'b00011011 : matrix3[31:24] << 1;
    temp1[1][3] = matrix3[23] ? ((matrix3[23:16] << 1) ^ 8'b00011011) ^ matrix3[23:16] : (matrix3[23:16] << 1) ^ matrix3[23:16];
    temp1[2][3] = matrix3[15:8];
    temp1[3][3] = matrix3[7:0];  
end

always @(*) begin
    // 1*matrix3[127:120] + 2*matrix3[119:112] + 3*matrix3[111:104] + 1*matrix3[103:96]
    temp2[0][0] = matrix3[127:120];
    temp2[1][0] = matrix3[119] ? (matrix3[119:112] << 1) ^ 8'b00011011 : matrix3[119:112] << 1;
    temp2[2][0] = matrix3[111] ? ((matrix3[111:104] << 1) ^ 8'b00011011) ^ matrix3[111:104] : (matrix3[111:104] << 1) ^ matrix3[111:104];
    temp2[3][0] = matrix3[103:96];

    // 1*matrix3[95:88] + 2*matrix3[87:80] + 3*matrix3[79:72] + 1*matrix3[71:64]
    temp2[0][1] = matrix3[95:88];
    temp2[1][1] = matrix3[87] ? (matrix3[87:80] << 1) ^ 8'b00011011 : matrix3[87:80] << 1;
    temp2[2][1] = matrix3[79] ? ((matrix3[79:72] << 1) ^ 8'b00011011) ^ matrix3[79:72] : (matrix3[79:72] << 1) ^ matrix3[79:72];
    temp2[3][1] = matrix3[71:64];     

    // 1*matrix3[63:56] + 2*matrix3[55:48] + 3*matrix3[47:40] + 1*matrix3[39:32]
    temp2[0][2] = matrix3[63:56];
    temp2[1][2] = matrix3[55] ? (matrix3[55:48] << 1) ^ 8'b00011011 : matrix3[55:48] << 1;
    temp2[2][2] = matrix3[47] ? ((matrix3[47:40] << 1) ^ 8'b00011011) ^ matrix3[47:40] : (matrix3[47:40] << 1) ^ matrix3[47:40];
    temp2[3][2] = matrix3[39:32];
    
    // 1*matrix3[31:24] + 2*matrix3[23:16] + 3*matrix3[15:8] + 1*matrix3[7:0]
    temp2[0][3] = matrix3[31:24];
    temp2[1][3] = matrix3[23] ? (matrix3[23:16] << 1) ^ 8'b00011011 : matrix3[23:16] << 1;
    temp2[2][3] = matrix3[15] ? ((matrix3[15:8] << 1) ^ 8'b00011011) ^ matrix3[15:8] : (matrix3[15:8] << 1) ^ matrix3[15:8];
    temp2[3][3] = matrix3[7:0];
end

always @(*) begin
    // 1*matrix3[127:120] + 1*matrix3[119:112] + 2*matrix3[111:104] + 3*matrix3[103:96]
    temp3[0][0] = matrix3[127:120];
    temp3[1][0] = matrix3[119:112];
    temp3[2][0] = matrix3[111] ? (matrix3[111:104] << 1) ^ 8'b00011011 : matrix3[111:104] << 1;
    temp3[3][0] = matrix3[103] ? ((matrix3[103:96] << 1) ^ 8'b00011011) ^ matrix3[103:96] : (matrix3[103:96] << 1) ^ matrix3[103:96];

    // 1*matrix3[95:88] + 1*matrix3[87:80] + 2*matrix3[79:72] + 3*matrix3[71:64]
    temp3[0][1] = matrix3[95:88];
    temp3[1][1] = matrix3[87:80];
    temp3[2][1] = matrix3[79] ? (matrix3[79:72] << 1) ^ 8'b00011011 : matrix3[79:72] << 1;
    temp3[3][1] = matrix3[71] ? ((matrix3[71:64] << 1) ^ 8'b00011011) ^ matrix3[71:64] : (matrix3[71:64] << 1) ^ matrix3[71:64];    

    // 1*matrix3[63:56] + 1*matrix3[55:48] + 2*matrix3[47:40] + 3*matrix3[39:32]
    temp3[0][2] = matrix3[63:56];
    temp3[1][2] = matrix3[55:48];
    temp3[2][2] = matrix3[47] ? (matrix3[47:40] << 1) ^ 8'b00011011 : matrix3[47:40] << 1;
    temp3[3][2] = matrix3[39] ? ((matrix3[39:32] << 1) ^ 8'b00011011) ^ matrix3[39:32] : (matrix3[39:32] << 1) ^ matrix3[39:32];   
    
    // 1*matrix3[31:24] + 1*matrix3[23:16] + 2*matrix3[15:8] + 3*matrix3[7:0]
    temp3[0][3] = matrix3[31:24];
    temp3[1][3] = matrix3[23:16];
    temp3[2][3] = matrix3[15] ? (matrix3[15:8] << 1) ^ 8'b00011011 : matrix3[15:8] << 1;
    temp3[3][3] = matrix3[7] ? ((matrix3[7:0] << 1) ^ 8'b00011011) ^ matrix3[7:0] : (matrix3[7:0] << 1) ^ matrix3[7:0]; 
end

always @(*) begin
    // 3*matrix3[127:120] + 1*matrix3[119:112] + 1*matrix3[111:104] + 2*matrix3[103:96]
    temp4[0][0] = matrix3[127] ? ((matrix3[127:120] << 1) ^ 8'b00011011) ^ matrix3[127:120] : (matrix3[127:120] << 1) ^ matrix3[127:120];
    temp4[1][0] = matrix3[119:112];
    temp4[2][0] = matrix3[111:104];
    temp4[3][0] = matrix3[103] ? (matrix3[103:96] << 1) ^ 8'b00011011 : matrix3[103:96] << 1;

    // 3*matrix3[95:88] + 1*matrix3[87:80] + 1*matrix3[79:72] + 2*matrix3[71:64]
    temp4[0][1] = matrix3[95] ? ((matrix3[95:88] << 1) ^ 8'b00011011) ^ matrix3[95:88] : (matrix3[95:88] << 1) ^ matrix3[95:88];
    temp4[1][1] = matrix3[87:80];
    temp4[2][1] = matrix3[79:72];
    temp4[3][1] = matrix3[71] ? (matrix3[71:64] << 1) ^ 8'b00011011 : matrix3[71:64] << 1;   

    // 3*matrix3[63:56] + 1*matrix3[55:48] + 1*matrix3[47:40] + 2*matrix3[39:32]
    temp4[0][2] = matrix3[63] ? ((matrix3[63:56] << 1) ^ 8'b00011011) ^ matrix3[63:56] : (matrix3[63:56] << 1) ^ matrix3[63:56];
    temp4[1][2] = matrix3[55:48];
    temp4[2][2] = matrix3[47:40];
    temp4[3][2] = matrix3[39] ? (matrix3[39:32] << 1) ^ 8'b00011011 : matrix3[39:32] << 1;   
    
    // 3*matrix3[31:24] + 1*matrix3[23:16] + 1*matrix3[15:8] + 2*matrix3[7:0]
    temp4[0][3] = matrix3[31] ? ((matrix3[31:24] << 1) ^ 8'b00011011) ^ matrix3[31:24] : (matrix3[31:24] << 1) ^ matrix3[31:24];
    temp4[1][3] = matrix3[23:16];
    temp4[2][3] = matrix3[15:8];
    temp4[3][3] = matrix3[7] ? (matrix3[7:0] << 1) ^ 8'b00011011 : matrix3[7:0] << 1;  
end

endmodule