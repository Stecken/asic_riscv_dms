`timescale 1ns/1ps
`default_nettype none

module control (
    input  wire       clk,
    input  wire       rst,
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire       funct7_5,
    input  wire       branch_taken,
    output reg        pc_write,
    output reg        ir_write,
    output reg        reg_write,
    output reg        mem_write,
    output reg        addr_src,
    output reg  [1:0] pc_src,
    output reg  [1:0] alu_src_a,
    output reg  [1:0] alu_src_b,
    output reg  [1:0] result_src,
    output reg  [3:0] alu_ctrl
`ifdef RISCV_DEBUG
    , output wire [3:0] state_debug
`endif
);

    localparam [3:0] ST_IF      = 4'd0;
    localparam [3:0] ST_ID      = 4'd1;
    localparam [3:0] ST_EX_R    = 4'd2;
    localparam [3:0] ST_EX_I    = 4'd3;
    localparam [3:0] ST_EX_MEM  = 4'd4;
    localparam [3:0] ST_MEM_RD  = 4'd5;
    localparam [3:0] ST_MEM_WR  = 4'd6;
    localparam [3:0] ST_WB_ALU  = 4'd7;
    localparam [3:0] ST_WB_MEM  = 4'd8;
    localparam [3:0] ST_EX_B    = 4'd9;
    localparam [3:0] ST_EX_J    = 4'd10;
    localparam [3:0] ST_WB_J    = 4'd11;

    localparam [6:0] OP_R      = 7'b0110011;
    localparam [6:0] OP_I      = 7'b0010011;
    localparam [6:0] OP_LOAD   = 7'b0000011;
    localparam [6:0] OP_STORE  = 7'b0100011;
    localparam [6:0] OP_BRANCH = 7'b1100011;
    localparam [6:0] OP_JAL    = 7'b1101111;
    localparam [6:0] OP_LUI    = 7'b0110111;
    localparam [6:0] OP_AUIPC  = 7'b0010111;

    localparam [3:0] ALU_ADD  = 4'b0000;
    localparam [3:0] ALU_SUB  = 4'b0001;
    localparam [3:0] ALU_AND  = 4'b0010;
    localparam [3:0] ALU_OR   = 4'b0011;
    localparam [3:0] ALU_XOR  = 4'b0100;
    localparam [3:0] ALU_SLL  = 4'b0101;
    localparam [3:0] ALU_SRL  = 4'b0110;
    localparam [3:0] ALU_SRA  = 4'b0111;
    localparam [3:0] ALU_SLT  = 4'b1000;
    localparam [3:0] ALU_SLTU = 4'b1001;

    reg [3:0] state;
    reg [3:0] next_state;

`ifdef RISCV_DEBUG
    assign state_debug = state;
`endif

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= ST_IF;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case (state)
            ST_IF: next_state = ST_ID;
            ST_ID: begin
                case (opcode)
                    OP_R:      next_state = ST_EX_R;
                    OP_I:      next_state = ST_EX_I;
                    OP_LOAD,
                    OP_STORE:  next_state = ST_EX_MEM;
                    OP_BRANCH: next_state = ST_EX_B;
                    OP_JAL:    next_state = ST_EX_J;
                    OP_LUI,
                    OP_AUIPC:  next_state = ST_WB_ALU;
                    default:   next_state = ST_IF;
                endcase
            end
            ST_EX_R,
            ST_EX_I:   next_state = ST_WB_ALU;
            ST_EX_MEM: next_state = (opcode == OP_LOAD) ? ST_MEM_RD : ST_MEM_WR;
            ST_MEM_RD: next_state = ST_WB_MEM;
            ST_EX_J:   next_state = ST_WB_J;
            default:   next_state = ST_IF;
        endcase
    end

    always @(*) begin
        pc_write   = 1'b0;
        ir_write   = 1'b0;
        reg_write  = 1'b0;
        mem_write  = 1'b0;
        addr_src   = 1'b0;
        pc_src     = 2'b00;
        alu_src_a  = 2'b00;
        alu_src_b  = 2'b00;
        result_src = 2'b00;
        alu_ctrl   = ALU_ADD;

        case (state)
            ST_IF: begin
                ir_write  = 1'b1;
                pc_write  = 1'b1;
                alu_src_a = 2'b00; // current PC
                alu_src_b = 2'b01; // constant 4
            end
            ST_ID: begin
                alu_src_a = (opcode == OP_LUI) ? 2'b11 : 2'b10; // zero or instruction PC
                alu_src_b = 2'b10; // decoded immediate
            end
            ST_EX_R: begin
                alu_src_a = 2'b01;
                alu_src_b = 2'b00;
                case (funct3)
                    3'b000: alu_ctrl = funct7_5 ? ALU_SUB : ALU_ADD;
                    3'b001: alu_ctrl = ALU_SLL;
                    3'b010: alu_ctrl = ALU_SLT;
                    3'b011: alu_ctrl = ALU_SLTU;
                    3'b100: alu_ctrl = ALU_XOR;
                    3'b101: alu_ctrl = funct7_5 ? ALU_SRA : ALU_SRL;
                    3'b110: alu_ctrl = ALU_OR;
                    3'b111: alu_ctrl = ALU_AND;
                    default: alu_ctrl = ALU_ADD;
                endcase
            end
            ST_EX_I: begin
                alu_src_a = 2'b01;
                alu_src_b = 2'b10;
                case (funct3)
                    3'b000: alu_ctrl = ALU_ADD;
                    3'b001: alu_ctrl = ALU_SLL;
                    3'b010: alu_ctrl = ALU_SLT;
                    3'b011: alu_ctrl = ALU_SLTU;
                    3'b100: alu_ctrl = ALU_XOR;
                    3'b101: alu_ctrl = funct7_5 ? ALU_SRA : ALU_SRL;
                    3'b110: alu_ctrl = ALU_OR;
                    3'b111: alu_ctrl = ALU_AND;
                    default: alu_ctrl = ALU_ADD;
                endcase
            end
            ST_EX_MEM: begin
                alu_src_a = 2'b01;
                alu_src_b = 2'b10;
                alu_ctrl  = ALU_ADD;
            end
            ST_MEM_RD: begin
                addr_src = 1'b1;
            end
            ST_MEM_WR: begin
                addr_src  = 1'b1;
                mem_write = 1'b1;
            end
            ST_WB_ALU: begin
                reg_write  = 1'b1;
                result_src = 2'b00;
            end
            ST_WB_MEM: begin
                reg_write  = 1'b1;
                result_src = 2'b01;
            end
            ST_EX_B: begin
                pc_src   = 2'b01;
                pc_write = branch_taken;
            end
            ST_EX_J: begin
                alu_src_a = 2'b10;
                alu_src_b = 2'b10;
                alu_ctrl  = ALU_ADD;
            end
            ST_WB_J: begin
                reg_write  = 1'b1;
                result_src = 2'b10; // instruction PC + 4
                pc_write   = 1'b1;
                pc_src     = 2'b01; // target saved in ALUOut
            end
            default: begin
            end
        endcase
    end

endmodule

`default_nettype wire
