module testbench();
    reg clk, rst;
    integer errors;
    top dut(.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; errors = 0; #20; rst = 0;

        dut.riscv.dp.imem_inst.mem[0]  = 32'h00F00093; // addi x1, x0, 15
        dut.riscv.dp.imem_inst.mem[1]  = 32'h0060F113; // andi x2, x1, 6  → 6
        dut.riscv.dp.imem_inst.mem[2]  = 32'h0080E193; // ori  x3, x1, 8  → 15
        dut.riscv.dp.imem_inst.mem[3]  = 32'h0060C213; // xori x4, x1, 6  → 9
        dut.riscv.dp.imem_inst.mem[4]  = 32'h00300293; // addi x5, x0, 3
        dut.riscv.dp.imem_inst.mem[5]  = 32'h0012A333; // slt  x6, x5, x1 → 1
        dut.riscv.dp.imem_inst.mem[6]  = 32'h00129463; // bne  x5, x1, +8 → pula
        dut.riscv.dp.imem_inst.mem[7]  = 32'h06300393; // addi x7, x0, 99 → NÃO executa
        dut.riscv.dp.imem_inst.mem[8]  = 32'h06300393; // addi x7, x0, 99 → NÃO executa
        dut.riscv.dp.imem_inst.mem[9]  = 32'h02A00413; // addi x8, x0, 42
        dut.riscv.dp.imem_inst.mem[10] = 32'h004004EF; // jal  x9, +4     → pula
        dut.riscv.dp.imem_inst.mem[11] = 32'h03700513; // addi x10, x0, 55 → NÃO executa
        dut.riscv.dp.imem_inst.mem[12] = 32'h04D00513; // addi x10, x0, 77

        #800;
        $display("=== Teste de Instruções ===");
        $display("x1  = %0d (esperado 15)", dut.riscv.dp.rf.regs[1]);
        $display("x2  = %0d (esperado 6)",  dut.riscv.dp.rf.regs[2]);
        $display("x3  = %0d (esperado 15)", dut.riscv.dp.rf.regs[3]);
        $display("x4  = %0d (esperado 9)",  dut.riscv.dp.rf.regs[4]);
        $display("x5  = %0d (esperado 3)",  dut.riscv.dp.rf.regs[5]);
        $display("x6  = %0d (esperado 1)",  dut.riscv.dp.rf.regs[6]);
        $display("x7  = %0d (esperado 0)",  dut.riscv.dp.rf.regs[7]);
        $display("x8  = %0d (esperado 42)", dut.riscv.dp.rf.regs[8]);
        $display("x9  = %0d (esperado 44)", dut.riscv.dp.rf.regs[9]);
        $display("x10 = %0d (esperado 77)", dut.riscv.dp.rf.regs[10]);
        $display("==========================");

        if (dut.riscv.dp.rf.regs[1] !== 32'd15) errors = errors + 1;
        if (dut.riscv.dp.rf.regs[2] !== 32'd6) errors = errors + 1;
        if (dut.riscv.dp.rf.regs[3] !== 32'd15) errors = errors + 1;
        if (dut.riscv.dp.rf.regs[4] !== 32'd9) errors = errors + 1;
        if (dut.riscv.dp.rf.regs[5] !== 32'd3) errors = errors + 1;
        if (dut.riscv.dp.rf.regs[6] !== 32'd1) errors = errors + 1;
        if (dut.riscv.dp.rf.regs[7] !== 32'd0) errors = errors + 1;
        if (dut.riscv.dp.rf.regs[8] !== 32'd42) errors = errors + 1;
        if (dut.riscv.dp.rf.regs[9] !== 32'd44) errors = errors + 1;
        if (dut.riscv.dp.rf.regs[10] !== 32'd77) errors = errors + 1;

        if (errors != 0)
            $fatal(1, "testbench legacy falhou com %0d erros", errors);
        $display("PASS testbench legacy");
        #1000 $finish;
    end

    initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);
    end
endmodule
