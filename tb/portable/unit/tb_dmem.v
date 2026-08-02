`timescale 1ns/1ps
`default_nettype none

module tb_dmem;
    reg        clk;
    reg        we;
    reg  [2:0] funct3;
    reg  [31:0] addr;
    reg  [31:0] wd;
    wire [31:0] rd;
    integer errors;

    dmem dut (.clk(clk), .we(we), .funct3(funct3), .addr(addr), .wd(wd), .rd(rd));
    always #5 clk = ~clk;

    task do_write;
        input [31:0] address;
        input [31:0] data;
        input [2:0]  f3;
        begin
            addr   = address;
            wd     = data;
            funct3 = f3;
            we     = 1'b1;
            @(posedge clk);
            #1;
            we = 1'b0;
        end
    endtask

    task expect_read;
        input [31:0] address;
        input [2:0]  f3;
        input [31:0] expected;
        begin
            addr   = address;
            funct3 = f3;
            #1;
            if (rd !== expected) begin
                $error("dmem[%h] funct3=%b: got %h, expected %h",
                       address, f3, rd, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk    = 1'b0;
        we     = 1'b0;
        funct3 = 3'b010;
        addr   = 32'b0;
        wd     = 32'b0;
        errors = 0;

        // ── SW / LW ──────────────────────────────────────────────
        do_write(32'd128, 32'hcafef00d, 3'b010);   // SW
        expect_read(32'd128, 3'b010, 32'hcafef00d); // LW
        expect_read(32'd132, 3'b010, 32'd0);         // LW vizinho não afetado

        // ── SH / LH / LHU ────────────────────────────────────────
        // SH na metade baixa (addr[1]=0)
        do_write(32'd200, 32'h0000aabb, 3'b001);
        expect_read(32'd200, 3'b001, 32'hffffaabb); // LH  — sinal de aabb[15]=1
        expect_read(32'd200, 3'b101, 32'h0000aabb); // LHU — sem extensão de sinal

        // SH na metade alta (addr[1]=1, addr=202)
        do_write(32'd202, 32'h00001234, 3'b001);
        expect_read(32'd202, 3'b001, 32'h00001234); // LH  — 1234[15]=0, sem extensão
        expect_read(32'd202, 3'b101, 32'h00001234); // LHU — igual

        // ── SB / LB / LBU ────────────────────────────────────────
        // Escreve 0xFF no byte 0 (addr[1:0]=00)
        do_write(32'd300, 32'h000000ff, 3'b000);
        expect_read(32'd300, 3'b000, 32'hffffffff); // LB  — 0xFF com sinal = -1
        expect_read(32'd300, 3'b100, 32'h000000ff); // LBU — 0xFF sem sinal = 255

        // Escreve 0x42 no byte 1 (addr[1:0]=01)
        do_write(32'd301, 32'h00000042, 3'b000);
        expect_read(32'd301, 3'b000, 32'h00000042); // LB  — 0x42[7]=0, sem extensão
        expect_read(32'd301, 3'b100, 32'h00000042); // LBU

        // Escreve 0x80 no byte 2 (addr[1:0]=10)
        do_write(32'd302, 32'h00000080, 3'b000);
        expect_read(32'd302, 3'b000, 32'hffffff80); // LB  — 0x80 com sinal = -128
        expect_read(32'd302, 3'b100, 32'h00000080); // LBU — 128

        // Escreve 0x7f no byte 3 (addr[1:0]=11)
        do_write(32'd303, 32'h0000007f, 3'b000);
        expect_read(32'd303, 3'b000, 32'h0000007f); // LB  — 0x7F = 127
        expect_read(32'd303, 3'b100, 32'h0000007f); // LBU

        // ── Bytes independentes dentro da mesma palavra ───────────
        // Verifica que escrever em byte 1 não apagou byte 0
        expect_read(32'd300, 3'b100, 32'h000000ff); // byte 0 ainda é 0xFF

        if (errors != 0) begin
            $fatal(1, "tb_dmem failed with %0d errors", errors);
        end
        $display("PASS tb_dmem");
        $finish;
    end
endmodule

`default_nettype wire
