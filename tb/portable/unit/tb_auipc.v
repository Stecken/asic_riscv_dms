`timescale 1ns/1ps
`default_nettype none

module tb_auipc;

    reg clk;
    reg rst;

    integer i;
    integer errors;

    localparam [3:0] ST_WB_ALU = 4'd7;

    riscv_top dut (
        .clk(clk),
        .rst(rst)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("build/sim/tb_auipc.vcd");
        $dumpvars(0, tb_auipc);
    end

    task run_test;

        input [31:0] instruction;
        input integer instruction_index;
        input [4:0] rd;
        input [31:0] expected;

        begin

            for (i = 0; i < 256; i = i + 1)
                dut.dp.imem_inst.mem[i] = 32'h00000013;

            for (i = 1; i < 32; i = i + 1)
                dut.dp.rf.regs[i] = 32'b0;

            dut.dp.imem_inst.mem[instruction_index] = instruction;

            rst = 1'b1;

            repeat (2)
                @(posedge clk);

            rst = 1'b0;

            wait (dut.debug_state == ST_WB_ALU &&
                  dut.debug_reg_write);

            @(posedge clk);
            #1;

            if (dut.dp.rf.regs[rd] !== expected) begin
                $error("AUIPC falhou: x%0d = %h esperado %h",
                       rd,
                       dut.dp.rf.regs[rd],
                       expected);
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

        // auipc x1,0x12345
        run_test(
            32'h12345097,
            0,
            5'd1,
            32'h12345000
        );

        // auipc x0,0xABCDE
        run_test(
            32'hABCDE017,
            0,
            5'd0,
            32'h00000000
        );

        // auipc x2,0xFFFFF
        run_test(
            32'hFFFFF117,
            0,
            5'd2,
            32'hFFFFF000
        );

        if (errors == 0)
            $display("PASS tb_auipc");
        else
            $fatal(1, "tb_auipc falhou (%0d erros)", errors);

        $finish;

    end

endmodule

`default_nettype wire