module datapath (
    input         clk,
    input         rst,
    // Sinais de controle
    input         pc_write,
    input         ir_write,
    input         reg_write,
    input         mem_write,
    input  [1:0]  pc_src,
    input  [1:0]  alu_src_a,
    input  [1:0]  alu_src_b,
    input  [1:0]  result_src,
    input  [3:0]  alu_ctrl,
    // Saídas para controle
    output [6:0]  opcode,
    output [2:0]  funct3,
    output        funct7_5,
    output        zero
);

    // Program Counter
    reg  [31:0] pc, pc_next;

    // Registradores intermediários
    reg  [31:0] ir;       // Instruction Register
    reg  [31:0] mdr;      // Memory Data Register
    reg  [31:0] a, b;     // Registradores A e B
    reg  [31:0] alu_out;  // Saída da ALU registrada

    // Fios internos
    wire [31:0] mem_rd;
    wire [31:0] rd1, rd2;
    wire [31:0] alu_result;
    wire [31:0] src_a, src_b;
    wire [31:0] imm_ext;
    wire [31:0] result;

    // Campos da instrução
    wire [4:0] rs1  = ir[19:15];
    wire [4:0] rs2  = ir[24:20];
    wire [4:0] rd_w = ir[11:7];

    assign opcode   = ir[6:0];
    assign funct3   = ir[14:12];
    assign funct7_5 = ir[30];

    // Extensão de sinal do imediato
    wire [31:0] imm_i = {{20{ir[31]}}, ir[31:20]};
    wire [31:0] imm_s = {{20{ir[31]}}, ir[31:25], ir[11:7]};
    wire [31:0] imm_b = {{19{ir[31]}}, ir[31], ir[7], ir[30:25], ir[11:8], 1'b0};
    wire [31:0] imm_j = {{11{ir[31]}}, ir[31], ir[19:12], ir[20], ir[30:21], 1'b0};
    wire [31:0] imm_u = {ir[31:12], 12'b0};

    assign imm_ext = (opcode == 7'b0100011) ? imm_s :
                     (opcode == 7'b1100011) ? imm_b :
                     (opcode == 7'b1101111) ? imm_j :
                     (opcode == 7'b0110111 ||
                      opcode == 7'b0010111) ? imm_u :
                                              imm_i;

    // Memória
    memory mem (
        .clk  (clk),
        .we   (mem_write),
        .addr (pc),
        .wd   (b),
        .rd   (mem_rd)
    );

    // Banco de registradores
    register_file rf (
        .clk  (clk),
        .we   (reg_write),
        .rs1  (rs1),
        .rs2  (rs2),
        .rd   (rd_w),
        .wd   (result),
        .rd1  (rd1),
        .rd2  (rd2)
    );

    // ALU
    alu alu_inst (
        .a        (src_a),
        .b        (src_b),
        .alu_ctrl (alu_ctrl),
        .result   (alu_result),
        .zero     (zero)
    );

    // MUX fonte A da ALU
    assign src_a = (alu_src_a == 2'b00) ? pc  :
                   (alu_src_a == 2'b01) ? a   : 32'b0;

    // MUX fonte B da ALU
    assign src_b = (alu_src_b == 2'b00) ? b       :
                   (alu_src_b == 2'b01) ? 32'd4   :
                   (alu_src_b == 2'b10) ? imm_ext : 32'b0;

    // MUX resultado final
    assign result = (result_src == 2'b00) ? alu_out :
                    (result_src == 2'b01) ? mdr     :
                    (result_src == 2'b10) ? alu_result : 32'b0;

    // MUX próximo PC
    always @(*) begin
        case (pc_src)
            2'b00: pc_next = alu_result;
            2'b01: pc_next = alu_out;
            2'b10: pc_next = {alu_result[31:1], 1'b0};
            default: pc_next = pc + 4;
        endcase
    end

    // Registradores intermediários e PC
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc      <= 32'b0;
            ir      <= 32'b0;
            mdr     <= 32'b0;
            a       <= 32'b0;
            b       <= 32'b0;
            alu_out <= 32'b0;
        end else begin
            if (pc_write) pc  <= pc_next;
            if (ir_write) ir  <= mem_rd;
            mdr     <= mem_rd;
            a       <= rd1;
            b       <= rd2;
            alu_out <= alu_result;
        end
    end

endmodule