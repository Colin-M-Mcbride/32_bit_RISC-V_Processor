`default_nettype none


module BranchUnit (
    input [31:0] PC,              // Current program counter
    input [31:0] rs1_data,        // Register rs1 value (for JALR)
    input [31:0] immediate,       // Immediate value from instruction
    
    output [31:0] branch_target,  // Branch target: PC + imm
    output [31:0] jump_target,    // JAL target: PC + imm
    output [31:0] jalr_target     // JALR target: (rs1 + imm) & ~1
);

    // Branch and JAL: PC + immediate
    // (Both use PC-relative addressing)
    assign branch_target = PC + immediate;
    assign jump_target   = PC + immediate;
    
    // JALR: (rs1 + immediate) with LSB cleared
    // LSB must be cleared to ensure alignment
    assign jalr_target = (rs1_data + immediate) & 32'hFFFFFFFE;

endmodule

`default_nettype wire