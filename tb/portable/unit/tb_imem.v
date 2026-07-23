`timescale 1ns/1ps
`default_nettype none

module tb_imem;
    reg  [31:0] addr;
    wire [31:0] rd;
    integer errors;

    imem dut (.addr(addr), .rd(rd));

    task expect_read;
        input [31:0] address;
        input [31:0] expected;
        begin
            addr = address;
            #1;
            if (rd !== expected) begin
                $error("imem[%h]: got %h, expected %h", address, rd, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        addr = 32'b0;
        errors = 0;

        dut.mem[32] = 32'h12345678;
        expect_read(32'd128, 32'h12345678);
        expect_read(32'd130, 32'h12345678); // low two address bits are ignored
        expect_read(32'd132, 32'd0);

        if (errors != 0) begin
            $fatal(1, "tb_imem failed with %0d errors", errors);
        end
        $display("PASS tb_imem");
        $finish;
    end
endmodule

`default_nettype wire
