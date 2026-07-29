`timescale 1ns/1ps
`default_nettype none

module tb_jalr;

    reg clk;
    reg rst;

    integer i;
    integer errors;

    localparam [3:0] ST_WB_J = 4'd11;

    riscv_top dut (
        .clk(clk),
        .rst(rst)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("build/sim/tb_jalr.vcd");
        $dumpvars(0, tb_jalr);
    end

    task run_test;

        input [31:0] instruction;
        input [31:0] rs1_value;
        input [31:0] expected_pc;
        input [31:0] expected_link;

        begin

            for (i = 0; i < 256; i = i + 1)
                dut.dp.imem_inst.mem[i] = 32'h00000013;

            for (i = 1; i < 32; i = i + 1)
                dut.dp.rf.regs[i] = 32'b0;

            dut.dp.imem_inst.mem[0] = instruction;

            rst = 1'b1;

            repeat (2)
                @(posedge clk);

            rst = 1'b0;

            dut.dp.rf.regs[2] = rs1_value;

            wait (dut.debug_state == ST_WB_J &&
                  dut.debug_reg_write);

            @(posedge clk);
            #1;

            if (dut.dp.rf.regs[1] !== expected_link) begin
                $error("x1 = %h esperado %h",
                       dut.dp.rf.regs[1],
                       expected_link);
                errors = errors + 1;
            end

            if (dut.dp.rf.regs[2] !== rs1_value) begin
                $error("x2 = %h esperado %h",
                       dut.dp.rf.regs[2],
                       rs1_value);
                errors = errors + 1;
            end

            if (dut.dp.pc !== expected_pc) begin
                $error("PC = %h esperado %h",
                       dut.dp.pc,
                       expected_pc);
                errors = errors + 1;
            end

            if (dut.dp.rf.regs[0] !== 32'h00000000) begin
                $error("x0 foi alterado");
                errors = errors + 1;
            end

        end

    endtask

    initial begin

        errors = 0;

        // jalr x1,0(x2)
        run_test(
            32'h000100E7,
            32'h00000020,
            32'h00000020,
            32'h00000004
        );

        // jalr x1,8(x2)
        run_test(
            32'h008100E7,
            32'h00000100,
            32'h00000108,
            32'h00000004
        );

        // odd address
        run_test(
            32'h000100E7,
            32'h00000021,
            32'h00000020,
            32'h00000004
        );

        if (errors == 0)
            $display("PASS tb_jalr");
        else
            $fatal(1, "tb_jalr falhou (%0d erros)", errors);

        $finish;

    end

endmodule

`default_nettype wire