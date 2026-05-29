
`default_nettype none

module ROM_Nx8
(
	input [$clog2(N)-1:0] address,
	output reg [7:0] data
);

	(* ramstyle = "logic" *) reg [7:0] rom [0:N-1];

	// Initialize memeory
	// Maximum 16 instructions
	initial begin
		rom[0] =8'h55;
		rom[0] =8'h12;
		rom[0] =8'h30;
		rom[0] =8'h28;
		rom[0] =8'h30;
		rom[0] =8'h40;
		rom[0] =8'h13;
		rom[0] =8'h30;
	end
	
	// Async combinational logic
	always @(*) begin
		data = rom[address];
	end

endmodule

`default_nettype wire
