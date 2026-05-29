`default_nettype none


module ImmediateGenerator (
    input [31:0] instruction,
    output reg [31:0] immediate
);

    wire [6:0] opcode;
    assign opcode = instruction[6:0];
    
    // Immediate extraction is purely combinational
    always @(*) begin
        case (opcode)
            // I-type: ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
            // Also: Load instructions (LB, LH, LW, LBU, LHU)
            // Also: JALR
            7'b0010011, // I-type arithmetic
            7'b0000011, // Load instructions
            7'b1100111: // JALR
                begin
                    // Sign-extend 12-bit immediate
                    immediate = {{20{instruction[31]}}, instruction[31:20]};
                end
            
            // S-type: Store instructions (SB, SH, SW)
            7'b0100011:
                begin
                    // Sign-extend split immediate: [31:25] and [11:7]
                    immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
                end
            
            // B-type: Branch instructions (BEQ, BNE, BLT, BGE, BLTU, BGEU)
            7'b1100011:
                begin
                    // Sign-extend and reorder branch immediate
                    // Format: imm[12|10:5] | rs2 | rs1 | funct3 | imm[4:1|11] | opcode
                    immediate = {{19{instruction[31]}}, 
                                instruction[31],      // imm[12]
                                instruction[7],       // imm[11]
                                instruction[30:25],   // imm[10:5]
                                instruction[11:8],    // imm[4:1]
                                1'b0};                // imm[0] = 0 (always even)
                end
            
            // U-type: LUI, AUIPC
            7'b0110111, // LUI
            7'b0010111: // AUIPC
                begin
                    // Upper 20 bits, lower 12 bits = 0
                    immediate = {instruction[31:12], 12'b0};
                end
            
            // J-type: JAL
            7'b1101111:
                begin
                    // Sign-extend and reorder jump immediate
                    // Format: imm[20|10:1|11|19:12] | rd | opcode
                    immediate = {{11{instruction[31]}},
                                instruction[31],      // imm[20]
                                instruction[19:12],   // imm[19:12]
                                instruction[20],      // imm[11]
                                instruction[30:21],   // imm[10:1]
                                1'b0};                // imm[0] = 0 (always even)
                end
            
            // R-type and unknown: no immediate
            default:
                begin
                    immediate = 32'b0;
                end
        endcase
    end

endmodule

`default_nettype wire