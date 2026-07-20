`timescale 1ns/1ps
`default_nettype none

module tb_control;
    reg clk;
    reg rst;
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg funct7_5;
    reg zero;
    wire pc_write;
    wire ir_write;
    wire reg_write;
    wire mem_write;
    wire addr_src;
    wire [1:0] pc_src;
    wire [1:0] alu_src_a;
    wire [1:0] alu_src_b;
    wire [1:0] result_src;
    wire [3:0] alu_ctrl;
    wire [3:0] state_debug;
    integer errors;

    control dut (
        .clk(clk), .rst(rst), .opcode(opcode), .funct3(funct3),
        .funct7_5(funct7_5), .zero(zero), .pc_write(pc_write),
        .ir_write(ir_write), .reg_write(reg_write), .mem_write(mem_write),
        .addr_src(addr_src), .pc_src(pc_src), .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b), .result_src(result_src), .alu_ctrl(alu_ctrl),
        .state_debug(state_debug)
    );

    always #5 clk = ~clk;

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task expect_state;
        input [3:0] expected;
        begin
            if (state_debug !== expected) begin
                $error("state: got %0d, expected %0d", state_debug, expected);
                errors = errors + 1;
            end
        end
    endtask

    task reset_control;
        begin
            rst = 1'b1;
            #1;
            expect_state(4'd0);
            if (!pc_write || !ir_write) begin
                $error("fetch controls not asserted after reset");
                errors = errors + 1;
            end
            tick();
            rst = 1'b0;
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b0;
        opcode = 7'b0110011;
        funct3 = 3'b101;
        funct7_5 = 1'b1;
        zero = 1'b0;
        errors = 0;

        reset_control();
        tick(); expect_state(4'd1);
        tick(); expect_state(4'd2);
        if (alu_ctrl !== 4'b0111) begin
            $error("SRA decode mismatch: %b", alu_ctrl);
            errors = errors + 1;
        end
        tick(); expect_state(4'd7);
        if (!reg_write) begin
            $error("R-type writeback missing");
            errors = errors + 1;
        end

        opcode = 7'b0000011;
        reset_control();
        tick(); expect_state(4'd1);
        tick(); expect_state(4'd4);
        tick(); expect_state(4'd5);
        if (!addr_src) begin
            $error("load did not select ALUOut as memory address");
            errors = errors + 1;
        end
        tick(); expect_state(4'd8);
        if (!reg_write || result_src != 2'b01) begin
            $error("load writeback controls mismatch");
            errors = errors + 1;
        end

        opcode = 7'b1100011;
        funct3 = 3'b000;
        zero = 1'b1;
        reset_control();
        tick(); expect_state(4'd1);
        tick(); expect_state(4'd9);
        if (!pc_write || pc_src != 2'b01) begin
            $error("taken BEQ controls mismatch");
            errors = errors + 1;
        end

        if (errors != 0) begin
            $fatal(1, "tb_control failed with %0d errors", errors);
        end
        $display("PASS tb_control");
        $finish;
    end
endmodule

`default_nettype wire
