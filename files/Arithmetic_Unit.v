module Arithmetic_Unit (
    input [31:0] A,
    input [31:0] B,
    input [3:0] ALU_Control,
    output reg [31:0] ALU_Result,
    output Zero
);
   localparam ADD  = 4'b0000;
   localparam SUB  = 4'b0001;
   localparam AND  = 4'b0010;
   localparam OR   = 4'b0011;
   localparam XOR  = 4'b0100;
   localparam SLT  = 4'b0101; // Set less than
   localparam SLL  = 4'b0110; // Shift left logical
   localparam SRL  = 4'b0111; // Shift right logical
   localparam SRA  = 4'b1000; // Shift right arithmetic
	localparam STLU = 4'b1001; // Set Less Than Unsigned    
   always @(*) begin
       case(ALU_Control)
           ADD:  ALU_Result = A + B;
           SUB:  ALU_Result = A - B;
           AND:  ALU_Result = A & B;
           OR:   ALU_Result = A | B;
           XOR:  ALU_Result = A ^ B;
           SLT:  ALU_Result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
           SLL:  ALU_Result = A << B[4:0];
           SRL:  ALU_Result = A >> B[4:0];
           SRA:  ALU_Result = $signed(A) >>> B[4:0];
           STLU:  ALU_Result = (A < B) ? 1 : 0;  
           default: ALU_Result = 32'd0;
        endcase
    end
    
    assign Zero = (ALU_Result == 32'd0);
endmodule