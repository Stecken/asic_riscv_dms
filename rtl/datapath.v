`timescale 1ns/1ps
`default_nettype none

module datapath #(
    parameter MEMORY_INIT_FILE = "",
    parameter integer MEMORY_INIT_WORDS = 0
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       pc_write,
    input  wire       ir_write,
    input  wire       reg_write,
    input  wire       mem_write,
    input  wire       addr_src,
    input  wire [1:0] pc_src,
    input  wire [1:0] alu_src_a,
    input  wire [1:0] alu_src_b,
    input  wire [1:0] result_src,
    input  wire [3:0] alu_ctrl,
    output wire [6:0] opcode,
    output wire [2:0] funct3,
    output wire       funct7_5,
    output wire       branch_taken
`ifdef RISCV_DEBUG
    , output wire [31:0] debug_pc
    , output wire [31:0] debug_old_pc
    , output wire [31:0] debug_instruction
    , output wire [4:0]  debug_rs1
    , output wire [4:0]  debug_rs2
    , output wire [4:0]  debug_rd
    , output wire [31:0] debug_operand_a
    , output wire [31:0] debug_operand_b
    , output wire [31:0] debug_immediate
    , output wire [31:0] debug_alu_a
    , output wire [31:0] debug_alu_b
    , output wire [31:0] debug_alu_result
    , output wire        debug_zero
    , output wire [31:0] debug_alu_out
    , output wire [31:0] debug_mdr
    , output wire [31:0] debug_writeback
    , output wire [31:0] debug_mem_address
    , output wire [31:0] debug_mem_read_data
    , output wire [31:0] debug_mem_write_data
`endif
);

    reg [31:0] pc;
    reg [31:0] old_pc;
    reg [31:0] ir;
    reg [31:0] mdr;
    reg [31:0] operand_a;
    reg [31:0] operand_b;
    reg [31:0] alu_out;

    wire [31:0] pc_next;
    wire [31:0] mem_address;
    wire [31:0] mem_read_data;
    wire [31:0] register_read_a;
    wire [31:0] register_read_b;
    wire [31:0] alu_result;
    /* verilator lint_off UNUSEDSIGNAL */
    wire        alu_zero;
    /* verilator lint_on UNUSEDSIGNAL */
    wire [31:0] alu_a;
    wire [31:0] alu_b;
    wire [31:0] immediate;
    wire [31:0] writeback_data;
    wire [4:0]  rs1;
    wire [4:0]  rs2;
    wire [4:0]  rd;
    wire        dmem_sel;
    wire [31:0] imem_rd;
    wire [31:0] dmem_rd;

    assign opcode   = ir[6:0];
    assign funct3   = ir[14:12];
    assign funct7_5 = ir[30];
    assign rs1      = ir[19:15];
    assign rs2      = ir[24:20];
    assign rd       = ir[11:7];

    immediate_gen immediate_gen_inst (
        .instruction (ir),
        .immediate   (immediate)
    );

    assign mem_address = addr_src ? alu_out : pc;

    // addr_src=0 fetches an instruction; addr_src=1 accesses data.
    assign dmem_sel = addr_src;

    imem #(
        .INIT_FILE  (MEMORY_INIT_FILE),
        .INIT_WORDS (MEMORY_INIT_WORDS)
    ) imem_inst (
        .addr (mem_address),
        .rd   (imem_rd)
    );

    dmem dmem_inst (
        .clk  (clk),
        .we   (mem_write & dmem_sel),
        .addr (mem_address),
        .wd   (operand_b),
        .rd   (dmem_rd)
    );

    assign mem_read_data = dmem_sel ? dmem_rd : imem_rd;

    register_file rf (
        .clk (clk),
        .we  (reg_write),
        .rs1 (rs1),
        .rs2 (rs2),
        .rd  (rd),
        .wd  (writeback_data),
        .rd1 (register_read_a),
        .rd2 (register_read_b)
    );

    branch_comp branch_comp_inst (
        .a      (operand_a),
        .b      (operand_b),
        .funct3 (funct3),
        .taken  (branch_taken)
    );

    assign alu_a = (alu_src_a == 2'b00) ? pc :
                   (alu_src_a == 2'b01) ? operand_a :
                   (alu_src_a == 2'b10) ? old_pc : 32'b0;

    assign alu_b = (alu_src_b == 2'b00) ? operand_b :
                   (alu_src_b == 2'b01) ? 32'd4 :
                   (alu_src_b == 2'b10) ? immediate : 32'b0;

    alu alu_inst (
        .a        (alu_a),
        .b        (alu_b),
        .alu_ctrl (alu_ctrl),
        .result   (alu_result),
        .zero     (alu_zero)
    );

    assign writeback_data = (result_src == 2'b00) ? alu_out :
                            (result_src == 2'b01) ? mdr :
                            (result_src == 2'b10) ? (old_pc + 32'd4) : 32'b0;

    assign pc_next = (pc_src == 2'b00) ? alu_result :
                     (pc_src == 2'b01) ? alu_out :
                     (pc_src == 2'b10) ? {alu_result[31:1], 1'b0} : (pc + 32'd4);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc        <= 32'b0;
            old_pc    <= 32'b0;
            ir        <= 32'b0;
            mdr       <= 32'b0;
            operand_a <= 32'b0;
            operand_b <= 32'b0;
            alu_out   <= 32'b0;
        end else begin
            if (pc_write) begin
                pc <= pc_next;
            end
            if (ir_write) begin
                old_pc <= pc;
                ir     <= mem_read_data;
            end
            mdr       <= mem_read_data;
            operand_a <= register_read_a;
            operand_b <= register_read_b;
            alu_out   <= alu_result;
        end
    end

`ifdef RISCV_DEBUG
    assign debug_pc             = pc;
    assign debug_old_pc         = old_pc;
    assign debug_instruction    = ir;
    assign debug_rs1            = rs1;
    assign debug_rs2            = rs2;
    assign debug_rd             = rd;
    assign debug_operand_a      = operand_a;
    assign debug_operand_b      = operand_b;
    assign debug_immediate      = immediate;
    assign debug_alu_a          = alu_a;
    assign debug_alu_b          = alu_b;
    assign debug_alu_result     = alu_result;
    assign debug_zero           = alu_zero;
    assign debug_alu_out        = alu_out;
    assign debug_mdr            = mdr;
    assign debug_writeback      = writeback_data;
    assign debug_mem_address    = mem_address;
    assign debug_mem_read_data  = mem_read_data;
    assign debug_mem_write_data = operand_b;
`endif

endmodule

`default_nettype wire
