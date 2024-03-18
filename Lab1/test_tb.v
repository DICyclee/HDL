/////////////////////////////////////////////////////////////////////
// ---------------------- IVCAD 2024 Spring ---------------------- //
// ---------------------- Editor : 	David    ----------------------//
// ---------------------- Date : 2024.01    ---------------------- //
// ----------------------      test_tb      ---------------------- // 
/////////////////////////////////////////////////////////////////////
`timescale 1ns/10ps

`ifdef T1
	`include "test1.v"
`endif

`ifdef T2
	`include "test2.v"
`endif

module test_tb;

// Module Instantiations 
`ifdef T1
	reg  [2:0] in1,  in2;
	wire [2:0] out1, out2, out3, out4;
	test1 t0(.out1(out1), .out2(out2), .out3(out3), .out4(out4), .in1(in1), .in2(in2));
`endif

`ifdef T2
	reg  [7:0]  in1 , in2;
	wire [8:0]  out1;
	wire [8:0]  out2;
	wire [15:0] out3;
	wire [7:0]  out4;
	wire [7:0]  out5;
	wire [15:0] out6;

	test2 t0(.out1(out1), 
	         .out2(out2), 
			 .out3(out3), 
			 .out4(out4), 
			 .out5(out5), 
			 .out6(out6), 
			 .in1(in1), 
			 .in2(in2)
			 );
`endif


// input pattern
initial begin
	`ifdef T1
		   in1 = 3'b100; in2 = 3'b001;  
	  #10  in1 = 3'b010; in2 = 3'b010;  
	  #10  in1 = 3'b001; in2 = 3'b100;  
	  #10  in1 = 3'b000; in2 = 3'b111;
	  #10  sim_end;
	  $stop;
	`endif

	`ifdef T2
		   in1 = 20;  in2 = 10;
	  #10  in1 = 40;  in2 = 30; 
	  #10  in1 = 80;  in2 = 50;
	  #10  in1 = 160; in2 = 70;
	  #10  sim_end;
	  $stop;
	`endif
end


// print result
initial begin
	`ifdef P1
		$monitor($time,"ns  in1=%b , in2=%b, out1=%b , out2=%b, out3=%b, out4=%b ",in1,in2,out1,out2,out3,out4);
	`endif

	`ifdef P2
		$monitor($time,"ns  in1=%d , in2=%d , out1=%d , out2=%d, out3=%d, out4=%d , out5=%d, out6=%d",in1,in2,out1,out2,out3,out4,out5,out6);
	`endif
end


// print result on terminal
task sim_end;
	begin
		$display("\n");
		$display("\n");
		$display("        ****************************               ");
		$display("        **                        **       |\__||  ");
		$display("        **  Congratulations !!    **      / O.O  | ");
		$display("        **                        **    /_____   | ");
		$display("        **  No Syntax Error!!     **   /^ ^ ^ \\  |");
		$display("        **                        **  |^ ^ ^ ^ |w| ");
		$display("        ****************************   \\m___m__|_|");
		$display("\n");
	end
endtask



endmodule
