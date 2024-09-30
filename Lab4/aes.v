module aes(
    input           clk,
    input           rst,
    input  [127:0]  plaintext,
    input  [127:0]  key,
    input  [7:0]    rom_data,
    output reg [7:0]    rom_addr,
    output reg [127:0]  ciphertext,
    output reg      done
);

reg [2:0] cstate;
reg [2:0] nstate;

reg [3:0] round_counter;
reg [4:0] rom_counter;
reg [3:0] const_counter;
reg [2:0] KeyExpansion_counter;

reg [7:0] temp1 [0:3][0:3];
reg [7:0] temp2 [0:3][0:3];
reg [7:0] temp3 [0:3][0:3];
reg [7:0] temp4 [0:3][0:3];

reg [127:0] key_buffer;
reg [31:0] key_ex;

wire [7:0] const_buffer [0:9];

parameter AddRoundKey_first = 0;
parameter AddRoundKey_normal = 1;
parameter SubBytes = 2;
parameter ShiftRows = 3;
parameter MixColumns = 4;
parameter KeyExpansion = 5;

assign const_buffer[0] = 8'h01;
assign const_buffer[1] = 8'h02;
assign const_buffer[2] = 8'h04;
assign const_buffer[3] = 8'h08;
assign const_buffer[4] = 8'h10;
assign const_buffer[5] = 8'h20;
assign const_buffer[6] = 8'h40;
assign const_buffer[7] = 8'h80;
assign const_buffer[8] = 8'h1b;
assign const_buffer[9] = 8'h36;

always @(posedge clk or posedge rst) begin
    if(rst)
        cstate <= AddRoundKey_first;
    else
        cstate <= nstate;
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        round_counter <= 0;
        rom_counter <= 0;
        const_counter <= 0;  
        KeyExpansion_counter <= 0;               
        done <= 0;       
    end
    else begin
        case(cstate)
            AddRoundKey_first:begin
                round_counter <= 0;
                const_counter <= 0;
                done <= 0;
                ciphertext <= plaintext ^ key;
                key_buffer <= key;
            end
            AddRoundKey_normal:begin       
                round_counter <= round_counter + 1;
                ciphertext <= ciphertext ^ key_buffer;
            end            
            SubBytes:begin
                if(round_counter == 10)
                    done <= 1;
                else begin 
                    case(rom_counter)
                        0: rom_addr <= ciphertext[127:120];
                        1: rom_addr <= ciphertext[119:112];
                        2: rom_addr <= ciphertext[111:104];
                        3: rom_addr <= ciphertext[103:96];
                        4: rom_addr <= ciphertext[95:88];
                        5: rom_addr <= ciphertext[87:80];
                        6: rom_addr <= ciphertext[79:72];
                        7: rom_addr <= ciphertext[71:64];
                        8: rom_addr <= ciphertext[63:56];
                        9: rom_addr <= ciphertext[55:48];
                        10: rom_addr <= ciphertext[47:40];
                        11: rom_addr <= ciphertext[39:32];
                        12: rom_addr <= ciphertext[31:24];
                        13: rom_addr <= ciphertext[23:16];
                        14: rom_addr <= ciphertext[15:8];
                        15: rom_addr <= ciphertext[7:0]; 
                        16: rom_addr <= ciphertext[7:0];
                        17: rom_addr <= ciphertext[7:0];                                       
                    endcase
                    if(rom_counter > 1)begin
                        case(rom_counter)
                            2: ciphertext[127:120] <= rom_data;
                            3: ciphertext[119:112] <= rom_data;
                            4: ciphertext[111:104] <= rom_data;
                            5: ciphertext[103:96] <= rom_data;
                            6: ciphertext[95:88] <= rom_data;
                            7: ciphertext[87:80] <= rom_data;
                            8: ciphertext[79:72] <= rom_data;
                            9: ciphertext[71:64] <= rom_data;
                            10: ciphertext[63:56] <= rom_data;
                            11: ciphertext[55:48] <= rom_data;
                            12: ciphertext[47:40] <= rom_data;
                            13: ciphertext[39:32] <= rom_data;
                            14: ciphertext[31:24] <= rom_data;
                            15: ciphertext[23:16] <= rom_data;
                            16: ciphertext[15:8] <= rom_data;
                            17: ciphertext[7:0] <= rom_data;                
                        endcase                   
                    end
                    if(rom_counter == 17)
                        rom_counter <= 0;
                    else
                        rom_counter <= rom_counter + 1;
                end
            end   
            ShiftRows:begin
                // fixed
                ciphertext[127:120] <= ciphertext[127:120];
                ciphertext[95:88] <= ciphertext[95:88];
                ciphertext[63:56] <= ciphertext[63:56];
                ciphertext[31:24] <= ciphertext[31:24];
                // left rotate 1
                ciphertext[119:112] <= ciphertext[87:80];
                ciphertext[87:80] <= ciphertext[55:48]; 
                ciphertext[55:48] <= ciphertext[23:16]; 
                ciphertext[23:16] <= ciphertext[119:112];
                // left rotate 2
                ciphertext[111:104] <= ciphertext[47:40];
                ciphertext[79:72] <= ciphertext[15:8]; 
                ciphertext[47:40] <= ciphertext[111:104];
                ciphertext[15:8] <= ciphertext[79:72];
                // left rotate 3
                ciphertext[103:96] <= ciphertext[7:0];
                ciphertext[71:64] <= ciphertext[103:96];
                ciphertext[39:32] <= ciphertext[71:64];
                ciphertext[7:0] <= ciphertext[39:32];      
            end   
            MixColumns:begin
                ciphertext[127:120] <= temp1[0][0] ^ temp1[1][0] ^ temp1[2][0] ^ temp1[3][0];
                ciphertext[95:88] <= temp1[0][1] ^ temp1[1][1] ^ temp1[2][1] ^ temp1[3][1];
                ciphertext[63:56] <= temp1[0][2] ^ temp1[1][2] ^ temp1[2][2] ^ temp1[3][2];
                ciphertext[31:24] <= temp1[0][3] ^ temp1[1][3] ^ temp1[2][3] ^ temp1[3][3];

                ciphertext[119:112] <= temp2[0][0] ^ temp2[1][0] ^ temp2[2][0] ^ temp2[3][0];
                ciphertext[87:80] <= temp2[0][1] ^ temp2[1][1] ^ temp2[2][1] ^ temp2[3][1];
                ciphertext[55:48] <= temp2[0][2] ^ temp2[1][2] ^ temp2[2][2] ^ temp2[3][2];                                                                                 
                ciphertext[23:16] <= temp2[0][3] ^ temp2[1][3] ^ temp2[2][3] ^ temp2[3][3];   
                
                ciphertext[111:104] <= temp3[0][0] ^ temp3[1][0] ^ temp3[2][0] ^ temp3[3][0];
                ciphertext[79:72] <= temp3[0][1] ^ temp3[1][1] ^ temp3[2][1] ^ temp3[3][1];
                ciphertext[47:40] <= temp3[0][2] ^ temp3[1][2] ^ temp3[2][2] ^ temp3[3][2];                                                                                 
                ciphertext[15:8] <= temp3[0][3] ^ temp3[1][3] ^ temp3[2][3] ^ temp3[3][3];

                ciphertext[103:96] <= temp4[0][0] ^ temp4[1][0] ^ temp4[2][0] ^ temp4[3][0];
                ciphertext[71:64] <= temp4[0][1] ^ temp4[1][1] ^ temp4[2][1] ^ temp4[3][1];
                ciphertext[39:32] <= temp4[0][2] ^ temp4[1][2] ^ temp4[2][2] ^ temp4[3][2];                                                                            
                ciphertext[7:0] <= temp4[0][3] ^ temp4[1][3] ^ temp4[2][3] ^ temp4[3][3];  
            end   
            KeyExpansion:begin
                if(KeyExpansion_counter == 1 && rom_counter != 5)
                    KeyExpansion_counter <= KeyExpansion_counter;
                else if(KeyExpansion_counter == 6)
                    KeyExpansion_counter <= 0;
                else
                    KeyExpansion_counter <= KeyExpansion_counter + 1;

                case(KeyExpansion_counter)
                    0:begin
                        key_ex[31:24] <= key_buffer[23:16];
                        key_ex[23:16] <= key_buffer[15:8];
                        key_ex[15:8] <= key_buffer[7:0];
                        key_ex[7:0] <= key_buffer[31:24];                        
                    end
                    1:begin
                        case(rom_counter)
                            0: rom_addr <= key_ex[31:24];
                            1: rom_addr <= key_ex[23:16];
                            2: rom_addr <= key_ex[15:8];
                            3: rom_addr <= key_ex[7:0];
                            4: rom_addr <= key_ex[7:0];
                            5: rom_addr <= key_ex[7:0];               
                        endcase
                        if(rom_counter > 1)
                        case(rom_counter)
                                2: key_ex[31:24] <= rom_data;
                                3: key_ex[23:16] <= rom_data;
                                4: key_ex[15:8] <= rom_data;
                                5: key_ex[7:0] <= rom_data;        
                            endcase
                        if(rom_counter == 5)
                            rom_counter <= 0;
                        else
                            rom_counter <= rom_counter + 1;                            
                    end
                    2:begin
                        key_ex[31:24] <= key_ex[31:24] ^ const_buffer[const_counter];
                        const_counter <= const_counter + 1;                          
                    end
                    3:begin
                        key_buffer[127:96] <= key_buffer[127:96] ^ key_ex;                           
                    end
                    4:begin
                        key_buffer[95:64] <= key_buffer[95:64] ^ key_buffer[127:96];      
                    end
                    5:begin
                        key_buffer[63:32] <= key_buffer[63:32] ^ key_buffer[95:64];     
                    end
                    6:begin
                        key_buffer[31:0] <= key_buffer[31:0] ^ key_buffer[63:32];    
                    end                                      
                endcase                
            end                                 
        endcase
    end     
end

always @(*) begin
    case(cstate)
        AddRoundKey_first:begin
            nstate = SubBytes;
        end
        AddRoundKey_normal:begin
            nstate = SubBytes;
        end
        SubBytes:begin
            if(done)
                nstate = AddRoundKey_first;
            else begin
                if(rom_counter == 17)
                    nstate = ShiftRows;
                else
                    nstate = SubBytes;
            end
        end   
        ShiftRows:begin
            if(round_counter == 9)
                nstate = KeyExpansion;
            else
                nstate = MixColumns;
        end   
        MixColumns:begin
            nstate = KeyExpansion;
        end   
        KeyExpansion:begin
            if(KeyExpansion_counter == 6)
                nstate = AddRoundKey_normal;
            else
                nstate = KeyExpansion;
        end
    endcase
end

always @(*) begin
    // 2*ciphertext[127:120] + 3*ciphertext[119:112] + 1*ciphertext[111:104] + 1*ciphertext[103:96]
    temp1[0][0] = ciphertext[127] ? (ciphertext[127:120] << 1) ^ 8'b00011011 : ciphertext[127:120] << 1;
    temp1[1][0] = ciphertext[119] ? ((ciphertext[119:112] << 1) ^ 8'b00011011) ^ ciphertext[119:112] : (ciphertext[119:112] << 1) ^ ciphertext[119:112];
    temp1[2][0] = ciphertext[111:104];
    temp1[3][0] = ciphertext[103:96];

    // 2*ciphertext[95:88] + 3*ciphertext[87:80] + 1*ciphertext[79:72] + 1*ciphertext[71:64]
    temp1[0][1] = ciphertext[95] ? (ciphertext[95:88] << 1) ^ 8'b00011011 : ciphertext[95:88] << 1;
    temp1[1][1] = ciphertext[87] ? ((ciphertext[87:80] << 1) ^ 8'b00011011) ^ ciphertext[87:80] : (ciphertext[87:80] << 1) ^ ciphertext[87:80];
    temp1[2][1] = ciphertext[79:72];
    temp1[3][1] = ciphertext[71:64];     

    // 2*ciphertext[63:56] + 3*ciphertext[55:48] + 1*ciphertext[47:40] + 1*ciphertext[39:32]
    temp1[0][2] = ciphertext[63] ? (ciphertext[63:56] << 1) ^ 8'b00011011 : ciphertext[63:56] << 1;
    temp1[1][2] = ciphertext[55] ? ((ciphertext[55:48] << 1) ^ 8'b00011011) ^ ciphertext[55:48] : (ciphertext[55:48] << 1) ^ ciphertext[55:48];
    temp1[2][2] = ciphertext[47:40];
    temp1[3][2] = ciphertext[39:32];
    
    // 2*ciphertext[31:24] + 3*ciphertext[23:16] + 1*ciphertext[15:8] + 1*ciphertext[7:0]
    temp1[0][3] = ciphertext[31] ? (ciphertext[31:24] << 1) ^ 8'b00011011 : ciphertext[31:24] << 1;
    temp1[1][3] = ciphertext[23] ? ((ciphertext[23:16] << 1) ^ 8'b00011011) ^ ciphertext[23:16] : (ciphertext[23:16] << 1) ^ ciphertext[23:16];
    temp1[2][3] = ciphertext[15:8];
    temp1[3][3] = ciphertext[7:0];  
end

always @(*) begin
    // 1*ciphertext[127:120] + 2*ciphertext[119:112] + 3*ciphertext[111:104] + 1*ciphertext[103:96]
    temp2[0][0] = ciphertext[127:120];
    temp2[1][0] = ciphertext[119] ? (ciphertext[119:112] << 1) ^ 8'b00011011 : ciphertext[119:112] << 1;
    temp2[2][0] = ciphertext[111] ? ((ciphertext[111:104] << 1) ^ 8'b00011011) ^ ciphertext[111:104] : (ciphertext[111:104] << 1) ^ ciphertext[111:104];
    temp2[3][0] = ciphertext[103:96];

    // 1*ciphertext[95:88] + 2*ciphertext[87:80] + 3*ciphertext[79:72] + 1*ciphertext[71:64]
    temp2[0][1] = ciphertext[95:88];
    temp2[1][1] = ciphertext[87] ? (ciphertext[87:80] << 1) ^ 8'b00011011 : ciphertext[87:80] << 1;
    temp2[2][1] = ciphertext[79] ? ((ciphertext[79:72] << 1) ^ 8'b00011011) ^ ciphertext[79:72] : (ciphertext[79:72] << 1) ^ ciphertext[79:72];
    temp2[3][1] = ciphertext[71:64];     

    // 1*ciphertext[63:56] + 2*ciphertext[55:48] + 3*ciphertext[47:40] + 1*ciphertext[39:32]
    temp2[0][2] = ciphertext[63:56];
    temp2[1][2] = ciphertext[55] ? (ciphertext[55:48] << 1) ^ 8'b00011011 : ciphertext[55:48] << 1;
    temp2[2][2] = ciphertext[47] ? ((ciphertext[47:40] << 1) ^ 8'b00011011) ^ ciphertext[47:40] : (ciphertext[47:40] << 1) ^ ciphertext[47:40];
    temp2[3][2] = ciphertext[39:32];
    
    // 1*ciphertext[31:24] + 2*ciphertext[23:16] + 3*ciphertext[15:8] + 1*ciphertext[7:0]
    temp2[0][3] = ciphertext[31:24];
    temp2[1][3] = ciphertext[23] ? (ciphertext[23:16] << 1) ^ 8'b00011011 : ciphertext[23:16] << 1;
    temp2[2][3] = ciphertext[15] ? ((ciphertext[15:8] << 1) ^ 8'b00011011) ^ ciphertext[15:8] : (ciphertext[15:8] << 1) ^ ciphertext[15:8];
    temp2[3][3] = ciphertext[7:0];
end

always @(*) begin
    // 1*ciphertext[127:120] + 1*ciphertext[119:112] + 2*ciphertext[111:104] + 3*ciphertext[103:96]
    temp3[0][0] = ciphertext[127:120];
    temp3[1][0] = ciphertext[119:112];
    temp3[2][0] = ciphertext[111] ? (ciphertext[111:104] << 1) ^ 8'b00011011 : ciphertext[111:104] << 1;
    temp3[3][0] = ciphertext[103] ? ((ciphertext[103:96] << 1) ^ 8'b00011011) ^ ciphertext[103:96] : (ciphertext[103:96] << 1) ^ ciphertext[103:96];

    // 1*ciphertext[95:88] + 1*ciphertext[87:80] + 2*ciphertext[79:72] + 3*ciphertext[71:64]
    temp3[0][1] = ciphertext[95:88];
    temp3[1][1] = ciphertext[87:80];
    temp3[2][1] = ciphertext[79] ? (ciphertext[79:72] << 1) ^ 8'b00011011 : ciphertext[79:72] << 1;
    temp3[3][1] = ciphertext[71] ? ((ciphertext[71:64] << 1) ^ 8'b00011011) ^ ciphertext[71:64] : (ciphertext[71:64] << 1) ^ ciphertext[71:64];    

    // 1*ciphertext[63:56] + 1*ciphertext[55:48] + 2*ciphertext[47:40] + 3*ciphertext[39:32]
    temp3[0][2] = ciphertext[63:56];
    temp3[1][2] = ciphertext[55:48];
    temp3[2][2] = ciphertext[47] ? (ciphertext[47:40] << 1) ^ 8'b00011011 : ciphertext[47:40] << 1;
    temp3[3][2] = ciphertext[39] ? ((ciphertext[39:32] << 1) ^ 8'b00011011) ^ ciphertext[39:32] : (ciphertext[39:32] << 1) ^ ciphertext[39:32];   
    
    // 1*ciphertext[31:24] + 1*ciphertext[23:16] + 2*ciphertext[15:8] + 3*ciphertext[7:0]
    temp3[0][3] = ciphertext[31:24];
    temp3[1][3] = ciphertext[23:16];
    temp3[2][3] = ciphertext[15] ? (ciphertext[15:8] << 1) ^ 8'b00011011 : ciphertext[15:8] << 1;
    temp3[3][3] = ciphertext[7] ? ((ciphertext[7:0] << 1) ^ 8'b00011011) ^ ciphertext[7:0] : (ciphertext[7:0] << 1) ^ ciphertext[7:0]; 
end

always @(*) begin
    // 3*ciphertext[127:120] + 1*ciphertext[119:112] + 1*ciphertext[111:104] + 2*ciphertext[103:96]
    temp4[0][0] = ciphertext[127] ? ((ciphertext[127:120] << 1) ^ 8'b00011011) ^ ciphertext[127:120] : (ciphertext[127:120] << 1) ^ ciphertext[127:120];
    temp4[1][0] = ciphertext[119:112];
    temp4[2][0] = ciphertext[111:104];
    temp4[3][0] = ciphertext[103] ? (ciphertext[103:96] << 1) ^ 8'b00011011 : ciphertext[103:96] << 1;

    // 3*ciphertext[95:88] + 1*ciphertext[87:80] + 1*ciphertext[79:72] + 2*ciphertext[71:64]
    temp4[0][1] = ciphertext[95] ? ((ciphertext[95:88] << 1) ^ 8'b00011011) ^ ciphertext[95:88] : (ciphertext[95:88] << 1) ^ ciphertext[95:88];
    temp4[1][1] = ciphertext[87:80];
    temp4[2][1] = ciphertext[79:72];
    temp4[3][1] = ciphertext[71] ? (ciphertext[71:64] << 1) ^ 8'b00011011 : ciphertext[71:64] << 1;   

    // 3*ciphertext[63:56] + 1*ciphertext[55:48] + 1*ciphertext[47:40] + 2*ciphertext[39:32]
    temp4[0][2] = ciphertext[63] ? ((ciphertext[63:56] << 1) ^ 8'b00011011) ^ ciphertext[63:56] : (ciphertext[63:56] << 1) ^ ciphertext[63:56];
    temp4[1][2] = ciphertext[55:48];
    temp4[2][2] = ciphertext[47:40];
    temp4[3][2] = ciphertext[39] ? (ciphertext[39:32] << 1) ^ 8'b00011011 : ciphertext[39:32] << 1;   
    
    // 3*ciphertext[31:24] + 1*ciphertext[23:16] + 1*ciphertext[15:8] + 2*ciphertext[7:0]
    temp4[0][3] = ciphertext[31] ? ((ciphertext[31:24] << 1) ^ 8'b00011011) ^ ciphertext[31:24] : (ciphertext[31:24] << 1) ^ ciphertext[31:24];
    temp4[1][3] = ciphertext[23:16];
    temp4[2][3] = ciphertext[15:8];
    temp4[3][3] = ciphertext[7] ? (ciphertext[7:0] << 1) ^ 8'b00011011 : ciphertext[7:0] << 1;  
end

endmodule