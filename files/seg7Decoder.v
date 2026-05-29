
`default_nettype none

module seg7Decoder (
	input [3:0] i_bin,
	output reg [7:0] o_HEX
);

	always @(*) begin
		
		// required to not infer latches
		o_HEX = 8'b11111111;
	
		case(i_bin)
			4'd0: o_HEX = 8'b11000000;
			4'd1: o_HEX = 8'b11111001;
			4'd2: o_HEX = 8'b10100100;
			4'd3: o_HEX = 8'b10110000;
			4'd4: o_HEX = 8'b10011001;
			4'd5: o_HEX = 8'b10010010;
			4'd6: o_HEX = 8'b10000010;
			4'd7: o_HEX = 8'b11111000;
			4'd8: o_HEX = 8'b10000000;
			4'd9: o_HEX = 8'b10011000;
			4'd10: o_HEX = 8'b10001000;
			4'd11: o_HEX = 8'b10000011;
			4'd12: o_HEX = 8'b11000110;
			4'd13: o_HEX = 8'b10100001;
			4'd14: o_HEX = 8'b10000110;
			4'd15: o_HEX = 8'b10001110;
			
		endcase
		
	end

endmodule

`default_nettype wire
