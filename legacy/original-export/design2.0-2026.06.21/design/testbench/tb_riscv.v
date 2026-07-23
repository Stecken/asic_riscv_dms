`timescale 1ns/1ps

module tb_riscv;

    reg  clk;
    reg  rst;
    integer errors;

    // Instancia o processador
    riscv_top dut (
        .clk (clk),
        .rst (rst)
    );

    // Clock — período de 10ns
    always #5 clk = ~clk;

    // Programa de teste em memória
    initial begin
        // Inicializa
        clk = 0;
        rst = 1;
        errors = 0;
        #20;
        rst = 0;

        // Carrega programa na memória
        // addi x1, x0, 5   → x1 = 5
        dut.dp.imem_inst.mem[0] = 32'h00500093;
        // addi x2, x0, 3   → x2 = 3
        dut.dp.imem_inst.mem[1] = 32'h00300113;
        // add  x3, x1, x2  → x3 = 8
        dut.dp.imem_inst.mem[2] = 32'h002081B3;
        // sw   x3, 0(x0)   → salva x3 na memória[0]
        dut.dp.imem_inst.mem[3] = 32'h00302023;
        // lw   x4, 0(x0)   → x4 = memória[0]
        dut.dp.imem_inst.mem[4] = 32'h00002203;
        // beq  x3, x4, -4  → se x3==x4 volta 1 instrução
        dut.dp.imem_inst.mem[5] = 32'hFE418CE3;
        // jal  x0, 0       → loop infinito
        dut.dp.imem_inst.mem[6] = 32'h0000006F;

        // Roda por 500ns
        #500;

        // Verifica resultados
        $display("=== Resultado dos Registradores ===");
        $display("x1 = %0d (esperado: 5)",  dut.dp.rf.regs[1]);
        $display("x2 = %0d (esperado: 3)",  dut.dp.rf.regs[2]);
        $display("x3 = %0d (esperado: 8)",  dut.dp.rf.regs[3]);
        $display("x4 = %0d (esperado: 8)",  dut.dp.rf.regs[4]);
        $display("===================================");

        if (dut.dp.rf.regs[1] !== 32'd5) errors = errors + 1;
        if (dut.dp.rf.regs[2] !== 32'd3) errors = errors + 1;
        if (dut.dp.rf.regs[3] !== 32'd8) errors = errors + 1;
        if (dut.dp.rf.regs[4] !== 32'd8) errors = errors + 1;
        if (dut.dp.dmem_inst.mem[0] !== 32'd8) errors = errors + 1;
        if (dut.dp.imem_inst.mem[0] !== 32'h00500093) errors = errors + 1;

        if (errors != 0)
            $fatal(1, "tb_riscv falhou com %0d erros", errors);
        $display("PASS tb_riscv: IMEM e DMEM isoladas");

        $finish;
    end

    // Monitor — mostra estado a cada ciclo
    initial begin
        $monitor("t=%0t | PC=%0d | estado=%0d | x1=%0d x2=%0d x3=%0d",
            $time,
            dut.dp.pc,
            dut.ctrl.state,
            dut.dp.rf.regs[1],
            dut.dp.rf.regs[2],
            dut.dp.rf.regs[3]
        );
    end

endmodule
