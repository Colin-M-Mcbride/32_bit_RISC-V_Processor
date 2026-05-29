`default_nettype none


module ProgramCounter (
    input MainClock,
    input reset,              // Clear counter (renamed from ClearCounter)
    input PCWrite,            // Enable PC update
    input [1:0] PCSrc,        // Source select: 00=PC+4, 01=branch, 10=jump, 11=jalr
    input [31:0] branch_target,   // Branch target address
    input [31:0] jump_target,     // Jump target address (JAL)
    input [31:0] jalr_target,     // JALR target from ALU
    output reg [31:0] PC          // Program Counter (32-bit for RISC-V)
);

    // Internal signal for next PC value
    reg [31:0] next_pc;
    
    // Combinational logic for next PC calculation
    always @(*) begin
        case (PCSrc)
            2'b00:   next_pc = PC + 4;           // Normal: PC = PC + 4
            2'b01:   next_pc = branch_target;    // Branch taken
            2'b10:   next_pc = jump_target;      // JAL
            2'b11:   next_pc = jalr_target;      // JALR
            default: next_pc = PC + 4;
        endcase
    end
    
    // Sequential logic for PC register (same structure as your original!)
    always @(posedge MainClock) begin
        if (reset)
            PC <= 32'b0;              // Reset to address 0
        else if (PCWrite)
            PC <= next_pc;            // Update PC when enabled
        // else: hold current value
    end

endmodule

`default_nettype wire