`timescale 1ns/1ps
`default_nettype none

// Exhaustive controller campaign. It checks the complete state path and the
// control contract for every implemented instruction class repeatedly.
module tb_control_stress;
    reg clk;
    reg rst;
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg       funct7_5;
    reg       branch_taken;
    wire pc_write, ir_write, reg_write, mem_write, addr_src;
    wire [1:0] pc_src, alu_src_a, alu_src_b, result_src;
    wire [3:0] alu_ctrl;
    wire [3:0] state_debug;
    integer errors;
    integer rounds;

    localparam [3:0] ST_IF     = 4'd0;
    localparam [3:0] ST_ID     = 4'd1;
    localparam [3:0] ST_EX_R   = 4'd2;
    localparam [3:0] ST_EX_I   = 4'd3;
    localparam [3:0] ST_EX_MEM = 4'd4;
    localparam [3:0] ST_MEM_RD = 4'd5;
    localparam [3:0] ST_MEM_WR = 4'd6;
    localparam [3:0] ST_WB_ALU = 4'd7;
    localparam [3:0] ST_WB_MEM = 4'd8;
    localparam [3:0] ST_EX_B   = 4'd9;
    localparam [3:0] ST_EX_J   = 4'd10;
    localparam [3:0] ST_WB_J   = 4'd11;

    localparam [6:0] OP_R      = 7'b0110011;
    localparam [6:0] OP_I      = 7'b0010011;
    localparam [6:0] OP_LOAD   = 7'b0000011;
    localparam [6:0] OP_STORE  = 7'b0100011;
    localparam [6:0] OP_BRANCH = 7'b1100011;
    localparam [6:0] OP_JAL    = 7'b1101111;
    localparam [6:0] OP_LUI    = 7'b0110111;
    localparam [6:0] OP_AUIPC  = 7'b0010111;
    localparam [6:0] OP_JALR   = 7'b1100111;

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

    control dut (
        .clk(clk), .rst(rst), .opcode(opcode), .funct3(funct3),
        .funct7_5(funct7_5), .branch_taken(branch_taken),
        .pc_write(pc_write), .ir_write(ir_write), .reg_write(reg_write),
        .mem_write(mem_write), .addr_src(addr_src), .pc_src(pc_src),
        .alu_src_a(alu_src_a), .alu_src_b(alu_src_b),
        .result_src(result_src), .alu_ctrl(alu_ctrl), .state_debug(state_debug)
    );

    always #5 clk = ~clk;

    task fail;
        input [1023:0] message;
        begin
            $error("%s (state=%0d opcode=%b)", message, state_debug, opcode);
            errors = errors + 1;
        end
    endtask

    task expect_state;
        input [3:0] expected;
        begin
            if (state_debug !== expected) begin
                $error("state got %0d expected %0d", state_debug, expected);
                errors = errors + 1;
            end
        end
    endtask

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task start_instruction;
        input [6:0] op;
        input [2:0] f3;
        input       f7;
        begin
            opcode = op;
            funct3 = f3;
            funct7_5 = f7;
            branch_taken = 1'b0;
            rst = 1'b1;
            #1;
            expect_state(ST_IF);
            if (!pc_write || !ir_write || reg_write || mem_write)
                fail("IF controls mismatch after reset");
            rst = 1'b0;
        end
    endtask

    task expect_id;
        input       is_lui;
        begin
            expect_state(ST_ID);
            if (pc_write || ir_write || reg_write || mem_write || addr_src ||
                alu_src_b !== 2'b10 || alu_src_a !== (is_lui ? 2'b11 : 2'b10))
                fail("ID controls mismatch");
        end
    endtask

    task exercise_r;
        input [2:0] f3;
        input       f7;
        input [3:0] expected_alu;
        begin
            start_instruction(OP_R, f3, f7);
            tick(); expect_id(1'b0);
            tick();
            expect_state(ST_EX_R);
            if (alu_src_a !== 2'b01 || alu_src_b !== 2'b00 ||
                alu_ctrl !== expected_alu)
                fail("EX_R controls/decode mismatch");
            tick();
            expect_state(ST_WB_ALU);
            if (!reg_write || result_src !== 2'b00 || pc_write || mem_write)
                fail("R writeback controls mismatch");
            tick(); expect_state(ST_IF);
        end
    endtask

    task exercise_i;
        input [2:0] f3;
        input       f7;
        input [3:0] expected_alu;
        begin
            start_instruction(OP_I, f3, f7);
            tick(); expect_id(1'b0);
            tick();
            expect_state(ST_EX_I);
            if (alu_src_a !== 2'b01 || alu_src_b !== 2'b10 ||
                alu_ctrl !== expected_alu)
                fail("EX_I controls/decode mismatch");
            tick();
            expect_state(ST_WB_ALU);
            if (!reg_write || result_src !== 2'b00 || pc_write || mem_write)
                fail("I writeback controls mismatch");
            tick(); expect_state(ST_IF);
        end
    endtask

    task exercise_load;
        begin
            start_instruction(OP_LOAD, 3'b010, 1'b0);
            tick(); expect_id(1'b0);
            tick(); expect_state(ST_EX_MEM);
            if (alu_src_a !== 2'b01 || alu_src_b !== 2'b10 ||
                alu_ctrl !== ALU_ADD)
                fail("load address-execute controls mismatch");
            tick(); expect_state(ST_MEM_RD);
            if (!addr_src || mem_write || reg_write)
                fail("MEM_RD controls mismatch");
            tick(); expect_state(ST_WB_MEM);
            if (!reg_write || result_src !== 2'b01 || mem_write)
                fail("load writeback controls mismatch");
            tick(); expect_state(ST_IF);
        end
    endtask

    task exercise_store;
        begin
            start_instruction(OP_STORE, 3'b010, 1'b0);
            tick(); expect_id(1'b0);
            tick(); expect_state(ST_EX_MEM);
            if (alu_src_a !== 2'b01 || alu_src_b !== 2'b10 ||
                alu_ctrl !== ALU_ADD)
                fail("store address-execute controls mismatch");
            tick(); expect_state(ST_MEM_WR);
            if (!addr_src || !mem_write || reg_write)
                fail("MEM_WR controls mismatch");
            tick(); expect_state(ST_IF);
        end
    endtask

    task exercise_branch;
        input [2:0] f3;
        input       taken;
        begin
            start_instruction(OP_BRANCH, f3, 1'b0);
            branch_taken = taken;
            tick(); expect_id(1'b0);
            tick(); expect_state(ST_EX_B);
            if (pc_src !== 2'b01 || pc_write !== taken || reg_write || mem_write)
                fail("branch controls/taken mismatch");
            tick(); expect_state(ST_IF);
        end
    endtask

    task exercise_jump;
        input [6:0] op;
        input [1:0] expected_a;
        input [1:0] expected_pc_src;
        begin
            start_instruction(op, 3'b000, 1'b0);
            tick(); expect_id(1'b0);
            tick(); expect_state(ST_EX_J);
            if (alu_src_a !== expected_a || alu_src_b !== 2'b10 ||
                alu_ctrl !== ALU_ADD)
                fail("EX_J controls mismatch");
            tick(); expect_state(ST_WB_J);
            if (!reg_write || !pc_write || result_src !== 2'b10 ||
                pc_src !== expected_pc_src)
                fail("WB_J controls mismatch");
            tick(); expect_state(ST_IF);
        end
    endtask

    task exercise_u;
        input [6:0] op;
        input       is_lui;
        begin
            start_instruction(op, 3'b000, 1'b0);
            tick(); expect_id(is_lui);
            tick(); expect_state(ST_WB_ALU);
            if (!reg_write || result_src !== 2'b00 || pc_write || mem_write)
                fail("U writeback controls mismatch");
            tick(); expect_state(ST_IF);
        end
    endtask

    task exercise_invalid;
        begin
            start_instruction(7'b1111111, 3'b111, 1'b1);
            tick(); expect_id(1'b0);
            tick(); expect_state(ST_IF);
            if (!pc_write || !ir_write || reg_write || mem_write)
                fail("invalid opcode did not return to fetch IF");
        end
    endtask

    task reset_from;
        input [1:0] kind;
        begin
            // kind 0: EX_MEM, 1: MEM_RD, 2: EX_B, 3: EX_J, 4: WB_ALU.
            start_instruction(OP_LOAD, 3'b010, 1'b0);
            tick(); // ID
            case (kind)
                0: tick(); // EX_MEM
                1: begin tick(); tick(); end // EX_MEM -> MEM_RD
                2: begin opcode = OP_BRANCH; tick(); end // EX_B
                3: begin opcode = OP_JAL; tick(); end // EX_J
                default: begin opcode = OP_R; tick(); tick(); end // WB_ALU
            endcase
            rst = 1'b1;
            #1;
            expect_state(ST_IF);
            if (!pc_write || !ir_write || reg_write || mem_write)
                fail("asynchronous reset did not restore IF controls");
            rst = 1'b0;
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b0;
        opcode = OP_R;
        funct3 = 3'b000;
        funct7_5 = 1'b0;
        branch_taken = 1'b0;
        errors = 0;
        rounds = 0;

        // Repeat the full transition matrix to expose state retention and
        // decode/control hazards that only appear after long campaigns.
        repeat (20) begin
            exercise_r(3'b000, 1'b0, ALU_ADD);
            exercise_r(3'b000, 1'b1, ALU_SUB);
            exercise_r(3'b001, 1'b0, ALU_SLL);
            exercise_r(3'b010, 1'b0, ALU_SLT);
            exercise_r(3'b011, 1'b0, ALU_SLTU);
            exercise_r(3'b100, 1'b0, ALU_XOR);
            exercise_r(3'b101, 1'b0, ALU_SRL);
            exercise_r(3'b101, 1'b1, ALU_SRA);
            exercise_r(3'b110, 1'b0, ALU_OR);
            exercise_r(3'b111, 1'b0, ALU_AND);

            exercise_i(3'b000, 1'b0, ALU_ADD);
            exercise_i(3'b001, 1'b0, ALU_SLL);
            exercise_i(3'b010, 1'b0, ALU_SLT);
            exercise_i(3'b011, 1'b0, ALU_SLTU);
            exercise_i(3'b100, 1'b0, ALU_XOR);
            exercise_i(3'b101, 1'b0, ALU_SRL);
            exercise_i(3'b101, 1'b1, ALU_SRA);
            exercise_i(3'b110, 1'b0, ALU_OR);
            exercise_i(3'b111, 1'b0, ALU_AND);

            exercise_load();
            exercise_store();
            exercise_branch(3'b000, 1'b0);
            exercise_branch(3'b000, 1'b1);
            exercise_branch(3'b001, 1'b0);
            exercise_branch(3'b001, 1'b1);
            exercise_branch(3'b100, 1'b0);
            exercise_branch(3'b100, 1'b1);
            exercise_branch(3'b101, 1'b0);
            exercise_branch(3'b101, 1'b1);
            exercise_branch(3'b110, 1'b0);
            exercise_branch(3'b110, 1'b1);
            exercise_branch(3'b111, 1'b0);
            exercise_branch(3'b111, 1'b1);
            exercise_jump(OP_JAL, 2'b10, 2'b01);
            exercise_jump(OP_JALR, 2'b01, 2'b10);
            exercise_u(OP_LUI, 1'b1);
            exercise_u(OP_AUIPC, 1'b0);
            exercise_invalid();
            rounds = rounds + 1;
        end

        reset_from(0);
        reset_from(1);
        reset_from(2);
        reset_from(3);
        reset_from(4);

        if (errors != 0)
            $fatal(1, "tb_control_stress failed with %0d errors after %0d rounds", errors, rounds);
        $display("PASS tb_control_stress (%0d matrix rounds)", rounds);
        $finish;
    end
endmodule

`default_nettype wire
