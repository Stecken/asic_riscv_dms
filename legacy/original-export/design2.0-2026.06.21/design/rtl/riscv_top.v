module riscv_top #(
    parameter MEMORY_INIT_FILE = "",
    parameter integer MEMORY_INIT_WORDS = 0
) (
    input  clk,
    input  rst
);

    // Fios entre controle e datapath
    wire        pc_write;
    wire        ir_write;
    wire        reg_write;
    wire        mem_write;
    wire        addr_src;
    wire [1:0]  pc_src;
    wire [1:0]  alu_src_a;
    wire [1:0]  alu_src_b;
    wire [1:0]  result_src;
    wire [3:0]  alu_ctrl;
    wire [6:0]  opcode;
    wire [2:0]  funct3;
    wire        funct7_5;
    wire        zero;

    // Instancia o Datapath
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
        .zero       (zero)
    );

    // Instancia o Controle
    control ctrl (
        .clk        (clk),
        .rst        (rst),
        .opcode     (opcode),
        .funct3     (funct3),
        .funct7_5   (funct7_5),
        .zero       (zero),
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
    );

endmodule
