// ============ ALU ============
module alu (
    input  [31:0] a, b,
    input  [3:0]  alu_ctrl,
    output reg [31:0] result,
    output zero
);
    assign zero = (result == 32'b0);
    always @(*) begin
        case (alu_ctrl)
            4'b0000: result = a + b;
            4'b0001: result = a - b;
            4'b0010: result = a & b;
            4'b0011: result = a | b;
            4'b0100: result = a ^ b;
            4'b0101: result = a << b[4:0];
            4'b0110: result = a >> b[4:0];
            4'b0111: result = $signed(a) >>> b[4:0];
            4'b1000: result = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
            4'b1001: result = (a < b) ? 32'b1 : 32'b0;
            default: result = 32'b0;
        endcase
    end
endmodule

// ============ REGISTER FILE ============
module register_file (
    input         clk, we,
    input  [4:0]  rs1, rs2, rd,
    input  [31:0] wd,
    output [31:0] rd1, rd2
);
    reg [31:0] regs [0:31];
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'b0;
    end
    assign rd1 = (rs1 == 5'b0) ? 32'b0 : regs[rs1];
    assign rd2 = (rs2 == 5'b0) ? 32'b0 : regs[rs2];
    always @(posedge clk) begin
        if (we && rd != 5'b0)
            regs[rd] <= wd;
    end
endmodule

// ============ INSTRUCTION MEMORY ============
module imem #(
    parameter INIT_FILE = "",
    parameter integer INIT_WORDS = 0
) (
    input  [31:0] addr,
    output [31:0] rd
);
    reg [31:0] mem [0:255];
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'b0;
        if ((INIT_FILE != "") && (INIT_WORDS > 0))
            $readmemh(INIT_FILE, mem, 0, INIT_WORDS - 1);
    end
    assign rd = mem[addr[9:2]];
endmodule

// ============ DATA MEMORY ============
module dmem (
    input         clk, we,
    input  [31:0] addr, wd,
    output [31:0] rd
);
    reg [31:0] mem [0:255];
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'b0;
    end
    assign rd = mem[addr[9:2]];
    always @(posedge clk) begin
        if (we) mem[addr[9:2]] <= wd;
    end
endmodule

// ============ DATAPATH ============
module datapath #(
    parameter MEMORY_INIT_FILE = "",
    parameter integer MEMORY_INIT_WORDS = 0
) (
    input         clk, rst,
    input         pc_write, ir_write, reg_write, mem_write, addr_src,
    input  [1:0]  pc_src, alu_src_a, alu_src_b, result_src,
    input  [3:0]  alu_ctrl,
    output [6:0]  opcode,
    output [2:0]  funct3,
    output        funct7_5,
    output        zero
);
    reg  [31:0] pc, pc_next;
    reg  [31:0] ir, mdr, a, b, alu_out;
    wire [31:0] mem_rd, imem_rd, dmem_rd;
    wire [31:0] rd1, rd2, alu_result, src_a, src_b, imm_ext, result;

    wire [4:0] rs1  = ir[19:15];
    wire [4:0] rs2  = ir[24:20];
    wire [4:0] rd_w = ir[11:7];

    assign opcode   = ir[6:0];
    assign funct3   = ir[14:12];
    assign funct7_5 = ir[30];

    wire [31:0] imm_i = {{20{ir[31]}}, ir[31:20]};
    wire [31:0] imm_s = {{20{ir[31]}}, ir[31:25], ir[11:7]};
    wire [31:0] imm_b = {{19{ir[31]}}, ir[31], ir[7], ir[30:25], ir[11:8], 1'b0};
    wire [31:0] imm_j = {{11{ir[31]}}, ir[31], ir[19:12], ir[20], ir[30:21], 1'b0};
    wire [31:0] imm_u = {ir[31:12], 12'b0};

    assign imm_ext = (opcode == 7'b0100011) ? imm_s :
                     (opcode == 7'b1100011) ? imm_b :
                     (opcode == 7'b1101111) ? imm_j :
                     (opcode == 7'b0110111 || opcode == 7'b0010111) ? imm_u : imm_i;

    wire [31:0] mem_addr = (addr_src) ? alu_out : pc;
	imem #(
        .INIT_FILE(MEMORY_INIT_FILE),
        .INIT_WORDS(MEMORY_INIT_WORDS)
    ) imem_inst (.addr(mem_addr), .rd(imem_rd));
	dmem dmem_inst (.clk(clk), .we(mem_write & addr_src), .addr(mem_addr), .wd(b), .rd(dmem_rd));
    assign mem_rd = addr_src ? dmem_rd : imem_rd;
	
	register_file rf (.clk(clk), .we(reg_write), .rs1(rs1), .rs2(rs2), .rd(rd_w), .wd(result), .rd1(rd1), .rd2(rd2));
	
	alu alu_inst (.a(src_a), .b(src_b), .alu_ctrl(alu_ctrl), .result(alu_result), .zero(zero));
    
    assign src_a  = (alu_src_a == 2'b00) ? pc : a;
    assign src_b  = (alu_src_b == 2'b00) ? b :
                    (alu_src_b == 2'b01) ? 32'd4 : imm_ext;
    assign result = (result_src == 2'b00) ? alu_out :
                    (result_src == 2'b01) ? mdr :
                    (result_src == 2'b10) ? alu_result : pc;

    always @(*) begin
        case (pc_src)
            2'b00: pc_next = alu_result;
            2'b01: pc_next = alu_out;
            2'b10: pc_next = {alu_result[31:1], 1'b0};
            default: pc_next = pc + 4;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 0; ir <= 0; mdr <= 0; a <= 0; b <= 0; alu_out <= 0;
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

// ============ CONTROL ============
module control (
    input      clk, rst,
    input      [6:0] opcode,
    input      [2:0] funct3,
    input      funct7_5, zero,
    output reg pc_write, ir_write, reg_write, mem_write, addr_src,
    output reg [1:0] pc_src, alu_src_a, alu_src_b, result_src,
    output reg [3:0] alu_ctrl
);
    localparam IF=0, ID=1, EX_R=2, EX_I=3, EX_MEM=4, MEM_RD=5,
               MEM_WR=6, WB_R=7, WB_MEM=8, EX_B=9, EX_J=10, WB_J=11;
    localparam OP_R=7'b0110011, OP_I=7'b0010011, OP_L=7'b0000011,
               OP_S=7'b0100011, OP_B=7'b1100011, OP_JAL=7'b1101111, OP_LUI=7'b0110111;

    reg [3:0] state, next_state;

    always @(posedge clk or posedge rst) begin
        if (rst) state <= IF;
        else     state <= next_state;
    end

    always @(*) begin
        case (state)
            IF:     next_state = ID;
            ID:     case (opcode)
                        OP_R: next_state = EX_R;   OP_I: next_state = EX_I;
                        OP_L: next_state = EX_MEM; OP_S: next_state = EX_MEM;
                        OP_B: next_state = EX_B;   OP_JAL: next_state = EX_J;
                        OP_LUI: next_state = WB_R; default: next_state = IF;
                    endcase
            EX_R:   next_state = WB_R;
            EX_I:   next_state = WB_R;
            EX_MEM: next_state = (opcode == OP_L) ? MEM_RD : MEM_WR;
            MEM_RD: next_state = WB_MEM;
            MEM_WR: next_state = IF;
            WB_R:   next_state = IF;
            WB_MEM: next_state = IF;
            EX_B:   next_state = IF;
            EX_J:   next_state = WB_J;
            WB_J:   next_state = IF;
            default: next_state = IF;
        endcase
    end

    always @(*) begin
        pc_write=0; ir_write=0; reg_write=0; mem_write=0; addr_src=0;
        pc_src=0; alu_src_a=0; alu_src_b=0; result_src=0; alu_ctrl=0;
        case (state)
            IF:     begin ir_write=1; pc_write=1; alu_src_b=2'b01; end
            ID:     begin alu_src_b=2'b10; end
            EX_R:   begin alu_src_a=2'b01;
                        case ({funct7_5, funct3})
                            4'b0000: alu_ctrl=4'b0000; 4'b1000: alu_ctrl=4'b0001;
                            4'b0111: alu_ctrl=4'b0010; 4'b0110: alu_ctrl=4'b0011;
                            4'b0100: alu_ctrl=4'b0100; 4'b0010: alu_ctrl=4'b1000;
                            default: alu_ctrl=4'b0000;
                        endcase
                    end
            EX_I:   begin alu_src_a=2'b01; alu_src_b=2'b10;
                        case (funct3)
                            3'b000: alu_ctrl=4'b0000; 3'b111: alu_ctrl=4'b0010;
                            3'b110: alu_ctrl=4'b0011; 3'b100: alu_ctrl=4'b0100;
                            default: alu_ctrl=4'b0000;
                        endcase
                    end
            EX_MEM: begin alu_src_a=2'b01; alu_src_b=2'b10; end
            MEM_RD: begin result_src=2'b01; addr_src=1; end
            MEM_WR: begin mem_write=1; addr_src=1; end
            WB_R:   begin reg_write=1; end
            WB_MEM: begin reg_write=1; result_src=2'b01; end
            EX_B:   begin alu_src_a=2'b01; alu_ctrl=4'b0001; pc_src=2'b01;
                        pc_write=(funct3==3'b000) ? zero : ~zero;
                    end
            EX_J:   begin alu_src_b=2'b10; end
            WB_J:   begin reg_write=1; result_src=2'b11; pc_write=1; pc_src=2'b01; end
        endcase
    end
endmodule

// ============ RISC-V TOP ============
module riscv_top #(
    parameter MEMORY_INIT_FILE = "",
    parameter integer MEMORY_INIT_WORDS = 0
) (
    input clk, rst
);
    wire pc_write, ir_write, reg_write, mem_write;
    wire [1:0] pc_src, alu_src_a, alu_src_b, result_src;
    wire [3:0] alu_ctrl;
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire funct7_5, zero;
    wire addr_src;

    datapath #(
        .MEMORY_INIT_FILE(MEMORY_INIT_FILE),
        .MEMORY_INIT_WORDS(MEMORY_INIT_WORDS)
    ) dp (.clk(clk), .rst(rst), .pc_write(pc_write), .ir_write(ir_write),
        .reg_write(reg_write), .mem_write(mem_write), .pc_src(pc_src),
        .alu_src_a(alu_src_a), .alu_src_b(alu_src_b), .result_src(result_src),
        .alu_ctrl(alu_ctrl), .opcode(opcode), .funct3(funct3),
        .funct7_5(funct7_5), .addr_src(addr_src), .zero(zero));

    control ctrl (.clk(clk), .rst(rst), .opcode(opcode), .funct3(funct3),
        .funct7_5(funct7_5), .zero(zero), .pc_write(pc_write), .ir_write(ir_write),
        .reg_write(reg_write), .mem_write(mem_write), .pc_src(pc_src),
        .alu_src_a(alu_src_a), .alu_src_b(alu_src_b), .result_src(result_src),
        .alu_ctrl(alu_ctrl), .addr_src(addr_src));
endmodule

// ============ TOP WRAPPER ============
module top (
    input clk, rst
);
    riscv_top riscv (.clk(clk), .rst(rst));
endmodule
