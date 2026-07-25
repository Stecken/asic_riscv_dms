`timescale 1ns/1ps
`default_nettype none

module riscv_top #(
    parameter MEMORY_INIT_FILE = "",
    parameter integer MEMORY_INIT_WORDS = 0
) (
    input wire clk,
    input wire rst
`ifdef RISCV_DEBUG
    , output wire [31:0] debug_pc
    , output wire [31:0] debug_old_pc
    , output wire [31:0] debug_instruction
    , output wire [3:0]  debug_state
    , output wire [6:0]  debug_opcode
    , output wire [2:0]  debug_funct3
    , output wire        debug_funct7_5
    , output wire [4:0]  debug_rs1
    , output wire [4:0]  debug_rs2
    , output wire [4:0]  debug_rd
    , output wire [31:0] debug_operand_a
    , output wire [31:0] debug_operand_b
    , output wire [31:0] debug_immediate
    , output wire [31:0] debug_alu_a
    , output wire [31:0] debug_alu_b
    , output wire [3:0]  debug_alu_control
    , output wire [31:0] debug_alu_result
    , output wire        debug_zero
    , output wire        debug_reg_write
    , output wire [31:0] debug_writeback
    , output wire        debug_mem_write
    , output wire [31:0] debug_mem_address
    , output wire [31:0] debug_mem_read_data
    , output wire [31:0] debug_mem_write_data
    , output wire [1:0]  debug_pc_src
    , output wire [1:0]  debug_alu_src_a
    , output wire [1:0]  debug_alu_src_b
    , output wire [1:0]  debug_result_src
    , output wire [31:0] debug_alu_out
    , output wire [31:0] debug_mdr
`endif
);

    wire       pc_write;
    wire       ir_write;
    wire       reg_write;
    wire       mem_write;
    wire       addr_src;
    wire [1:0] pc_src;
    wire [1:0] alu_src_a;
    wire [1:0] alu_src_b;
    wire [1:0] result_src;
    wire [3:0] alu_ctrl;
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire       funct7_5;
    wire       branch_taken;

    datapath #(
        .MEMORY_INIT_FILE  (MEMORY_INIT_FILE),
        .MEMORY_INIT_WORDS (MEMORY_INIT_WORDS)
    ) dp (
        .clk        (clk),
        .rst        (rst),
        .pc_write   (pc_write),
        .ir_write   (ir_write),
        .reg_write  (reg_write),
        .mem_write  (mem_write),
        .addr_src   (addr_src),
        .pc_src     (pc_src),
        .alu_src_a  (alu_src_a),
        .alu_src_b  (alu_src_b),
        .result_src (result_src),
        .alu_ctrl   (alu_ctrl),
        .opcode     (opcode),
        .funct3     (funct3),
        .funct7_5   (funct7_5),
        .branch_taken (branch_taken)
`ifdef RISCV_DEBUG
        , .debug_pc             (debug_pc)
        , .debug_old_pc         (debug_old_pc)
        , .debug_instruction    (debug_instruction)
        , .debug_rs1            (debug_rs1)
        , .debug_rs2            (debug_rs2)
        , .debug_rd             (debug_rd)
        , .debug_operand_a      (debug_operand_a)
        , .debug_operand_b      (debug_operand_b)
        , .debug_immediate      (debug_immediate)
        , .debug_alu_a          (debug_alu_a)
        , .debug_alu_b          (debug_alu_b)
        , .debug_alu_result     (debug_alu_result)
        , .debug_zero           (debug_zero)
        , .debug_alu_out        (debug_alu_out)
        , .debug_mdr            (debug_mdr)
        , .debug_writeback      (debug_writeback)
        , .debug_mem_address    (debug_mem_address)
        , .debug_mem_read_data  (debug_mem_read_data)
        , .debug_mem_write_data (debug_mem_write_data)
`endif
    );

    control control_inst (
        .clk        (clk),
        .rst        (rst),
        .opcode     (opcode),
        .funct3     (funct3),
        .funct7_5   (funct7_5),
        .branch_taken (branch_taken),
        .pc_write   (pc_write),
        .ir_write   (ir_write),
        .reg_write  (reg_write),
        .mem_write  (mem_write),
        .addr_src   (addr_src),
        .pc_src     (pc_src),
        .alu_src_a  (alu_src_a),
        .alu_src_b  (alu_src_b),
        .result_src (result_src),
        .alu_ctrl   (alu_ctrl)
`ifdef RISCV_DEBUG
        , .state_debug (debug_state)
`endif
    );

`ifdef RISCV_DEBUG
    assign debug_opcode     = opcode;
    assign debug_funct3     = funct3;
    assign debug_funct7_5   = funct7_5;
    assign debug_alu_control = alu_ctrl;
    assign debug_reg_write  = reg_write;
    assign debug_mem_write  = mem_write;
    assign debug_pc_src     = pc_src;
    assign debug_alu_src_a  = alu_src_a;
    assign debug_alu_src_b  = alu_src_b;
    assign debug_result_src = result_src;
`endif

endmodule

`default_nettype wire
