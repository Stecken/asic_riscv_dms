`timescale 1ns/1ps
`default_nettype none

module tb_dmem;
    reg         clk;
    reg         we;
    reg  [31:0] addr;
    reg  [31:0] wd;
    wire [31:0] rd;
    integer errors;

    dmem dut (.clk(clk), .we(we), .addr(addr), .wd(wd), .rd(rd));
    always #5 clk = ~clk;

    task expect_read;
        input [31:0] address;
        input [31:0] expected;
        begin
            addr = address;
            #1;
            if (rd !== expected) begin
                $error("dmem[%h]: got %h, expected %h", address, rd, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        we = 1'b0;
        addr = 32'b0;
        wd = 32'b0;
        errors = 0;

        expect_read(32'd0, 32'd0);
        addr = 32'd128;
        wd = 32'hcafef00d;
        we = 1'b1;
        @(posedge clk);
        #1;
        we = 1'b0;
        expect_read(32'd128, 32'hcafef00d);
        expect_read(32'd132, 32'd0);
        expect_read(32'd130, 32'hcafef00d); // low two address bits are ignored

        if (errors != 0) begin
            $fatal(1, "tb_dmem failed with %0d errors", errors);
        end
        $display("PASS tb_dmem");
        $finish;
    end
endmodule

`default_nettype wire
