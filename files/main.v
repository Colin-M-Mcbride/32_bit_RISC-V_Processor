// ============================================================================
// RISC-V RV32IM Processor - Complete Top Module
// ============================================================================
// This is the main module that connects all components together
// Designed for FPGA implementation with external I/O


module main (
    // Clock and Reset
    input wire clk,
    input wire reset,
    
    // External I/O (for FPGA board peripherals)
    input wire [31:0] gpio_in,      // Switches, buttons, etc.
    output wire [31:0] gpio_out,    // LEDs, 7-segment, etc.
    
    // UART (optional, for serial communication)
    input wire uart_rx,
    output wire uart_tx,
    
    // Debug signals (connect to LEDs/probes)
    output wire [31:0] debug_pc,
    output wire [31:0] debug_instruction,
    output wire [3:0] debug_state,
    output wire debug_reg_write
);

    // ========================================================================
    // Internal Signals - Core Pipeline
    // ========================================================================
    
    // FSM State
    wire [1:0] current_state;
    
    // Program Counter
    wire [31:0] pc;
    wire [31:0] next_pc;
    wire pc_write;
    wire [31:0] branch_target;
    wire [31:0] jump_target;
    wire take_branch;
    wire take_jump;
    
    // Instruction Memory Interface
    wire [31:0] instruction;
    wire [31:0] imem_addr;
    
    // Decoded Instruction Fields
    wire [6:0] opcode;
    wire [4:0] rd, rs1, rs2;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [31:0] immediate;
    
    // Register File Signals
    wire [31:0] rs1_data, rs2_data;
    wire [31:0] rd_data;
    wire reg_write_enable;
    
    // ALU Signals
    wire [31:0] alu_a, alu_b;
    wire [3:0] alu_op;
    wire [31:0] alu_result;
    wire alu_zero;
    wire alu_less_than;
    
    // Memory Signals
    wire [31:0] mem_addr;
    wire [31:0] mem_write_data;
    wire [31:0] mem_read_data;
    wire mem_read_enable;
    wire mem_write_enable;
    wire [1:0] mem_size;  // 00=byte, 01=half, 10=word
    wire mem_unsigned;
    
    // Control Signals
    wire alu_src;         // 0=rs2, 1=immediate
    wire mem_to_reg;      // 0=ALU result, 1=memory
    wire branch;
    wire jump;
    wire jal;
    wire jalr;
    
    // Pipeline registers (between stages)
    wire [31:0] execute_result;
    wire [31:0] writeback_data;
    
    // ========================================================================
    // Debug Outputs
    // ========================================================================
    assign debug_pc = pc;
    assign debug_instruction = instruction;
    assign debug_state = {2'b0, current_state};
    assign debug_reg_write = reg_write_enable;
    
    // ========================================================================
    // Module Instantiations
    // ========================================================================
    

    // 1. PROGRAM COUNTER
    program_counter pc_unit (
        .clk(clk),
        .reset(reset),
        .pc_write(pc_write),
        .next_pc(next_pc),
        .branch_target(branch_target),
        .jump_target(jump_target),
        .take_branch(take_branch),
        .take_jump(take_jump),
        .pc(pc)
    );
    
    // 2. INSTRUCTION MEMORY
    instruction_memory imem (
        .clk(clk),
        .addr(imem_addr),
        .instruction(instruction)
    );
    
    // 3. INSTRUCTION DECODER
    instruction_decoder decoder (
        .instruction(instruction),
        .opcode(opcode),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .funct3(funct3),
        .funct7(funct7),
        .immediate(immediate)
    );
    
    // 4. REGISTER FILE
    registerFile regfile (
        .clk(clk),
        .reset(reset),
        .read_addr1(rs1),
        .read_addr2(rs2),
        .write_addr(rd),
        .write_data(rd_data),
        .write_enable(reg_write_enable),
        .read_data1(rs1_data),
        .read_data2(rs2_data)
    );
    
    // 5. IMMEDIATE GENERATOR
    immediate_generator imm_gen (
        .instruction(instruction),
        .immediate(immediate)
    );
    
    // 6. CONTROL UNIT (FSM + Control Signals)
    control_unit control (
        .clk(clk),
        .reset(reset),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .alu_zero(alu_zero),
        .alu_less_than(alu_less_than),
        // Outputs
        .state(current_state),
        .pc_write(pc_write),
        .reg_write(reg_write_enable),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .mem_read(mem_read_enable),
        .mem_write(mem_write_enable),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .jump(jump),
        .take_branch(take_branch),
        .take_jump(take_jump)
    );
    
    // 7. ALU
    alu alu_unit (
        .a(alu_a),
        .b(alu_b),
        .op(alu_op),
        .result(alu_result),
        .zero(alu_zero),
        .less_than(alu_less_than)
    );
    
    // 8. DATA MEMORY
    data_memory dmem (
        .clk(clk),
        .addr(mem_addr),
        .write_data(mem_write_data),
        .read_enable(mem_read_enable),
        .write_enable(mem_write_enable),
        .size(mem_size),
        .unsigned_op(mem_unsigned),
        .read_data(mem_read_data)
    );
    
    // 9. BRANCH UNIT
    branch_unit branch_calc (
        .pc(pc),
        .rs1_data(rs1_data),
        .immediate(immediate),
        .branch_target(branch_target),
        .jump_target(jump_target)
    );
    
    // 10. FORWARDING/HAZARD UNIT (Optional - for pipelining optimization)
    // hazard_unit hazard (
    //     .rs1(rs1),
    //     .rs2(rs2),
    //     .execute_rd(execute_rd),
    //     .memory_rd(memory_rd),
    //     .stall(stall),
    //     .forward_a(forward_a),
    //     .forward_b(forward_b)
    // );
    
    // 11. MEMORY-MAPPED I/O CONTROLLER
    mmio_controller mmio (
        .clk(clk),
        .reset(reset),
        .mem_addr(mem_addr),
        .mem_write_data(mem_write_data),
        .mem_read_enable(mem_read_enable),
        .mem_write_enable(mem_write_enable),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );
    
    // ========================================================================
    // Datapath Connections
    // ========================================================================
    
    // ALU Input Muxing
    assign alu_a = rs1_data;
    assign alu_b = alu_src ? immediate : rs2_data;
    
    // Memory Interface
    assign mem_addr = alu_result;
    assign mem_write_data = rs2_data;
    assign mem_size = funct3[1:0];
    assign mem_unsigned = funct3[2];
    
    // Writeback Muxing
    assign rd_data = mem_to_reg ? mem_read_data : 
                     (jal || jalr) ? (pc + 4) : 
                     alu_result;
    
    // Instruction Memory Address
    assign imem_addr = pc;
    


// ============================================================================
// MODULE LIST & DESCRIPTIONS
// ============================================================================
/*

MODULE CHECKLIST - What You Need to Build:
===========================================

CORE MODULES (Required):
-------------------------
✅ 1. riscv_top (above)
   - Main integration module
   - Connects all components
   - Handles top-level I/O

□ 2. program_counter
   - Holds current PC value
   - Calculates PC+4
   - Handles branches/jumps
   - Inputs: clk, reset, next_pc, branch_target, jump_target, take_branch, take_jump
   - Outputs: pc

□ 3. instruction_memory
   - Stores program instructions
   - Read-only memory (ROM)
   - Word-aligned access
   - Inputs: clk, addr[31:0]
   - Outputs: instruction[31:0]

□ 4. instruction_decoder
   - Extracts instruction fields
   - Purely combinational
   - Inputs: instruction[31:0]
   - Outputs: opcode, rd, rs1, rs2, funct3, funct7

□ 5. immediate_generator
   - Generates immediate values
   - Handles all 6 instruction formats (I, S, B, U, J)
   - Sign-extends appropriately
   - Inputs: instruction[31:0]
   - Outputs: immediate[31:0]

□ 6. register_file
   - 32 x 32-bit registers
   - x0 hardwired to 0
   - 2 read ports, 1 write port
   - Inputs: clk, reset, read_addr1, read_addr2, write_addr, write_data, write_enable
   - Outputs: read_data1, read_data2

✅ 7. alu (You already have this!)
   - Arithmetic and logic operations
   - 10+ operations: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU, MUL
   - Inputs: a[31:0], b[31:0], op[3:0]
   - Outputs: result[31:0], zero, less_than

□ 8. control_unit
   - FSM (4 states: FETCH, DECODE, EXECUTE, WRITEBACK)
   - Generates all control signals
   - Handles instruction decoding
   - Inputs: clk, reset, opcode, funct3, funct7, alu_zero, alu_less_than
   - Outputs: state, pc_write, reg_write, alu_src, alu_op, mem_read, mem_write, 
              mem_to_reg, branch, jump, take_branch, take_jump

□ 9. data_memory
   - Read/Write memory for loads/stores
   - Byte/halfword/word access
   - Sign extension for loads
   - Inputs: clk, addr, write_data, read_enable, write_enable, size, unsigned_op
   - Outputs: read_data[31:0]

□ 10. branch_unit
    - Calculates branch/jump targets
    - PC + immediate for branches
    - PC + immediate for JAL
    - rs1 + immediate for JALR
    - Inputs: pc, rs1_data, immediate
    - Outputs: branch_target, jump_target


OPTIONAL MODULES (Enhancements):
---------------------------------
□ 11. mmio_controller
    - Memory-mapped I/O
    - Interfaces with GPIO, UART, etc.
    - Maps memory addresses to peripherals
    - Inputs: mem_addr, mem_write_data, mem_read_enable, mem_write_enable, gpio_in, uart_rx
    - Outputs: mem_read_data, gpio_out, uart_tx

□ 12. hazard_unit (for pipelined version)
    - Detects data hazards
    - Generates stall/forward signals
    - Only needed if you pipeline

□ 13. csr_unit (Control and Status Registers)
    - For interrupts/exceptions
    - Machine-mode CSRs
    - Advanced feature


INSTRUCTION SUPPORT CHECKLIST:
-------------------------------
R-TYPE (10 instructions):
  □ ADD, SUB, AND, OR, XOR
  □ SLL, SRL, SRA
  □ SLT, SLTU

I-TYPE Arithmetic (10 instructions):
  □ ADDI, ANDI, ORI, XORI
  □ SLLI, SRLI, SRAI
  □ SLTI, SLTIU
  □ LUI, AUIPC (technically U-type)

I-TYPE Load (5 instructions):
  □ LB, LH, LW
  □ LBU, LHU

S-TYPE Store (3 instructions):
  □ SB, SH, SW

B-TYPE Branch (6 instructions):
  □ BEQ, BNE
  □ BLT, BGE
  □ BLTU, BGEU

J-TYPE Jump (2 instructions):
  □ JAL, JALR

M-EXTENSION (8 instructions - optional):
  □ MUL, MULH, MULHSU, MULHU
  □ DIV, DIVU, REM, REMU


DEVELOPMENT ORDER RECOMMENDATION:
----------------------------------
Phase 1: Basic Infrastructure
  1. program_counter
  2. instruction_memory
  3. instruction_decoder
  4. register_file
  5. control_unit (basic FSM only)

Phase 2: R-Type Support
  6. alu (you have this!)
  7. Complete control_unit for R-type
  8. Test R-type instructions

Phase 3: I-Type Arithmetic
  9. immediate_generator (I-type only)
  10. Update control_unit for I-type
  11. Test arithmetic I-type

Phase 4: Memory Operations
  12. data_memory
  13. immediate_generator (add S-type)
  14. Update control_unit for loads/stores
  15. Test LW/SW

Phase 5: Branches & Jumps
  16. branch_unit
  17. immediate_generator (add B-type, J-type)
  18. Update control_unit for branches/jumps
  19. Test branch/jump instructions

Phase 6: I/O & Peripherals
  20. mmio_controller
  21. Connect to FPGA board peripherals

Phase 7: M-Extension (bonus)
  22. Add MUL/DIV to ALU
  23. Update control_unit for M-type
  24. Test multiplication/division


TESTING STRATEGY:
-----------------
For each phase:
1. Write simple assembly test programs
2. Hand-assemble to machine code
3. Load into instruction memory
4. Simulate with testbench
5. Verify register values
6. Test on FPGA board

Good test programs:
- Fibonacci sequence
- Bubble sort
- LED blinker patterns
- UART echo
- Calculator

/*
/*
	/* 
	--------------------------------
	ALU TEST
	Hey guess it works
	--------------------------------
	*/
	/*
	module main (SW, LEDR);
    input [17:0] SW;    // toggle switches
    output [17:0] LEDR; // red LEDs


	
	Arithmetic_Unit (
    .A (SW[9:6]),
    .B (5'b00101),
    .ALU_Control (SW[3:0]),
    .ALU_Result (LEDR [6:0]),
    .Zero (LEDR[9])
	);
*/
	/* 
	--------------------------------
	Registers test
	Works
	--------------------------------
/*

    //-------------------------------------
    // Clock and Control Signals
    //-------------------------------------
    wire clk = MAX10_CLK1_50;
    wire reset = ~KEY[0];         // Press KEY[0] to reset
    wire reg_write = ~KEY[1];     // Press KEY[1] to write
    
    //-------------------------------------
    // Register File Connections
    //-------------------------------------
    wire [4:0] rs1_addr = SW[4:0];      // Lower 5 switches = read address 1
    wire [4:0] rs2_addr = 5'd1;         // Always read x1 on port 2
    wire [4:0] rd_addr = SW[9:5];       // Upper 5 switches = write address
    
    // Test data - increment on each write
    reg [31:0] write_counter;
    
    always @(posedge clk) begin
        if (reset)
            write_counter <= 32'd0;
        else if (reg_write)
            write_counter <= write_counter + 1;
    end
    
    // Register file outputs
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    
    //-------------------------------------
    // Instantiate Register File
    //-------------------------------------
    RegisterFile regfile(
        .clk(clk),
        .reset(reset),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .rd_data(write_counter),
        .reg_write(reg_write),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );
    
    //-------------------------------------
    // Display on LEDs
    //-------------------------------------
    assign LEDR[9:5] = rd_addr;   // Show write address
    assign LEDR[4:0] = rs1_addr;  // Show read address
    
    //-------------------------------------
    // Display on 7-Segment (lower 24 bits of rs1_data)
    //-------------------------------------
    seg7Decoder hex0(.i_bin(rs1_data[3:0]),   .o_HEX(HEX0));
    seg7Decoder hex1(.i_bin(rs1_data[7:4]),   .o_HEX(HEX1));
    seg7Decoder hex2(.i_bin(rs1_data[11:8]),  .o_HEX(HEX2));
    seg7Decoder hex4(.i_bin(rs1_data[15:12]), .o_HEX(HEX4));
    seg7Decoder hex5(.i_bin(rs1_data[19:16]), .o_HEX(HEX5));

*/

	 
endmodule

`default_nettype wire
