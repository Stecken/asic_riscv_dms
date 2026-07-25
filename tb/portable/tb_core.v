`timescale 1ns/1ps
`default_nettype none

`ifndef PROGRAM_HEX
`define PROGRAM_HEX "firmware/core_basic.hex"
`endif
`ifndef PROGRAM_WORDS
`define PROGRAM_WORDS 25
`endif

module tb_core;
    reg clk;
    reg rst;
    wire [31:0] debug_pc;
    wire [31:0] debug_old_pc;
    wire [31:0] debug_instruction;
    wire [3:0] debug_state;
    wire [6:0] debug_opcode;
    wire [2:0] debug_funct3;
    wire debug_funct7_5;
    wire [4:0] debug_rs1;
    wire [4:0] debug_rs2;
    wire [4:0] debug_rd;
    wire [31:0] debug_operand_a;
    wire [31:0] debug_operand_b;
    wire [31:0] debug_immediate;
    wire [31:0] debug_alu_a;
    wire [31:0] debug_alu_b;
    wire [3:0] debug_alu_control;
    wire [31:0] debug_alu_result;
    wire debug_zero;
    wire debug_reg_write;
    wire [31:0] debug_writeback;
    wire debug_mem_write;
    wire [31:0] debug_mem_address;
    wire [31:0] debug_mem_read_data;
    wire [31:0] debug_mem_write_data;
    wire [1:0] debug_pc_src;
    wire [1:0] debug_alu_src_a;
    wire [1:0] debug_alu_src_b;
    wire [1:0] debug_result_src;
    wire [31:0] debug_alu_out;
    wire [31:0] debug_mdr;

    reg [31:0] register_model [0:31];
    reg saw_expected_store;
    integer cycles;
    integer errors;
    integer i;
    reg [1023:0] wave_path;

    riscv_top #(
        .MEMORY_INIT_FILE  (`PROGRAM_HEX),
        .MEMORY_INIT_WORDS (`PROGRAM_WORDS)
    ) dut (
        .clk(clk), .rst(rst), .debug_pc(debug_pc), .debug_old_pc(debug_old_pc),
        .debug_instruction(debug_instruction), .debug_state(debug_state),
        .debug_opcode(debug_opcode), .debug_funct3(debug_funct3),
        .debug_funct7_5(debug_funct7_5), .debug_rs1(debug_rs1),
        .debug_rs2(debug_rs2), .debug_rd(debug_rd),
        .debug_operand_a(debug_operand_a), .debug_operand_b(debug_operand_b),
        .debug_immediate(debug_immediate), .debug_alu_a(debug_alu_a),
        .debug_alu_b(debug_alu_b), .debug_alu_control(debug_alu_control),
        .debug_alu_result(debug_alu_result), .debug_zero(debug_zero),
        .debug_reg_write(debug_reg_write), .debug_writeback(debug_writeback),
        .debug_mem_write(debug_mem_write), .debug_mem_address(debug_mem_address),
        .debug_mem_read_data(debug_mem_read_data),
        .debug_mem_write_data(debug_mem_write_data), .debug_pc_src(debug_pc_src),
        .debug_alu_src_a(debug_alu_src_a), .debug_alu_src_b(debug_alu_src_b),
        .debug_result_src(debug_result_src), .debug_alu_out(debug_alu_out),
        .debug_mdr(debug_mdr)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!rst) begin
            if (debug_reg_write && (debug_rd != 5'd0)) begin
                register_model[debug_rd] <= debug_writeback;
            end
            if (debug_mem_write && debug_mem_address == 32'd128 &&
                debug_mem_write_data == 32'd8) begin
                saw_expected_store <= 1'b1;
            end
        end
    end

    task check_register;
        input [4:0] address;
        input [31:0] expected;
        begin
            if (register_model[address] !== expected) begin
                $error("x%0d: got %h, expected %h", address,
                       register_model[address], expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        cycles = 0;
        errors = 0;
        saw_expected_store = 1'b0;
        for (i = 0; i < 32; i = i + 1) begin
            register_model[i] = 32'b0;
        end

        if (!$value$plusargs("wave=%s", wave_path)) begin
            wave_path = "core_basic.vcd";
        end
        $dumpfile(wave_path);
        $dumpvars(0, tb_core);

        repeat (2) @(posedge clk);
        #1 rst = 1'b0;

        while ((register_model[31] != 32'd1) && (cycles < 300)) begin
            @(posedge clk);
            #1;
            cycles = cycles + 1;
        end

        if (cycles >= 300) begin
            $fatal(1, "core timeout after %0d cycles (pc=%h state=%0d instruction=%h)",
                   cycles, debug_pc, debug_state, debug_instruction);
        end

        check_register(5'd0,  32'd0);
        check_register(5'd1,  32'd5);
        check_register(5'd2,  32'd3);
        check_register(5'd3,  32'd8);
        check_register(5'd4,  32'd2);
        check_register(5'd5,  32'd1);
        check_register(5'd6,  32'd7);
        check_register(5'd7,  32'd6);
        check_register(5'd8,  32'd24);
        check_register(5'd9,  32'd3);
        check_register(5'd10, 32'hfffffff8);
        check_register(5'd11, 32'hffffffff);
        check_register(5'd12, 32'd1);
        check_register(5'd13, 32'd0);
        check_register(5'd14, 32'd8);
        check_register(5'd15, 32'd0);
        check_register(5'd16, 32'd42);
        check_register(5'd17, 32'h12345000);
        check_register(5'd18, 32'd84);
        check_register(5'd19, 32'd0);
        check_register(5'd20, 32'd77);
        check_register(5'd21, 32'd5);
        check_register(5'd22, 32'd10);
        check_register(5'd23, 32'hffffffff);
        check_register(5'd24, 32'd1);
        check_register(5'd25, 32'd1);
        check_register(5'd26, 32'd1);
        check_register(5'd27, 32'd1);
        check_register(5'd28, 32'd1);
        check_register(5'd29, 32'd1);
        check_register(5'd30, 32'd1);
        check_register(5'd31, 32'd1);
        if (!saw_expected_store) begin
            $error("expected SW of 8 to address 128 was not observed");
            errors = errors + 1;
        end

        if (errors != 0) begin
            $fatal(1, "tb_core failed with %0d errors", errors);
        end
        $display("PASS tb_core (%0d cycles, program=%s)", cycles, `PROGRAM_HEX);
        $finish;
    end
endmodule

`default_nettype wire
