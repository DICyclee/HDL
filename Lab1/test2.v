/////////////////////////////////////////////////////////////////////
// ---------------------- IVCAD 2024 Spring ---------------------- //
// ---------------------- Editor : 	David   -----------------------//
// ---------------------- Date : 2024.01    ---------------------- //
// ----------------------      test2        ---------------------- //
// -------------------- Arithmetic operator -----------------------//
/////////////////////////////////////////////////////////////////////
module test2(out1,
             out2,
             out3,
             out4,
             out5,
             out6,
             out7,
             in1, 
             in2);
            
input  [7:0]  in1, in2;
output [8:0]  out1;
output [8:0]  out2;
output [15:0] out3;
output [7:0]  out4;
output [7:0]  out5;
output [7:0]  out6;
output [15:0] out7;

assign out1 = in1 + in2;    // plus
assign out2 = in1 - in2;    // minus
assign out3 = in1 * in2;    // multiply
assign out4 = in1 / in2;    // divided
assign out5 = in1 % in2;    // modulo
assign out6 = -in1;         // Unary Minus
assign out7 = in1 ** 2;     // power

endmodule