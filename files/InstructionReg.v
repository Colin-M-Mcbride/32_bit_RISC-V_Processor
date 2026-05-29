
`default_nettype none

module InstructionReg #
(
	input MainClock,
	input ClearInstr,
	input LatchInstr,
	input EnableInstr,
	input [5:0] Data, 
	input [15:0] Instr,
	output reg [32:0] ToInstr,
	output [32:0] IB_BUS
);


//Instructions
//
	always @(posedge MainClock) begin
		if (ClearInstr)
			ToInstr <= {N{1'b0}};
		else begin
			if(LatchInstr)
				ToInstr <= Instr; //Load A into the ALU
		end	
	end

//Data
	always @(posedge MainClock) begin
		if (ClearInstr)
			ToInstr <= {N{1'b0}};
		else begin
			if(LatchInstr)
				ToInstr <= Data; //Load A into the ALU
		end	
	end

assign IB_BUS = (EnableInstr == 1'b1) ? Data : {N{1'bZ}}; //
	
endmodule

`default_nettype wire
