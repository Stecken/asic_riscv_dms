`timescale 1ns/1ps
`default_nettype none

module tb_register_file;
    reg         clk;
    reg         we;
    reg  [4:0]  rs1;
    reg  [4:0]  rs2;
    reg  [4:0]  rd;
    reg  [31:0] wd;
    wire [31:0] rd1;
    wire [31:0] rd2;
    integer errors;

    register_file dut (
        .clk(clk), .we(we), .rs1(rs1), .rs2(rs2), .rd(rd), .wd(wd),
        .rd1(rd1), .rd2(rd2)
    );

    always #5 clk = ~clk;

    task write_register;
        input [4:0] address;
        input [31:0] value;
        begin
            rd = address;
            wd = value;
            we = 1'b1;
            @(posedge clk);
            #1;
            we = 1'b0;
        end
    endtask

    task expect_reads;
        input [4:0] address_a;
        input [31:0] expected_a;
        input [4:0] address_b;
        input [31:0] expected_b;
        begin
            rs1 = address_a;
            rs2 = address_b;
            #1;
            if (rd1 !== expected_a) begin
                $error("read port A x%0d: got %h, expected %h", address_a, rd1, expected_a);
                errors = errors + 1;
            end
            if (rd2 !== expected_b) begin
                $error("read port B x%0d: got %h, expected %h", address_b, rd2, expected_b);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        we = 1'b0;
        rs1 = 5'd0;
        rs2 = 5'd0;
        rd = 5'd0;
        wd = 32'b0;
        errors = 0;

        expect_reads(5'd0, 32'd0, 5'd1, 32'd0);
        write_register(5'd1, 32'h12345678);
        write_register(5'd2, 32'hdeadbeef);
        expect_reads(5'd1, 32'h12345678, 5'd2, 32'hdeadbeef);
        expect_reads(5'd2, 32'hdeadbeef, 5'd1, 32'h12345678);
        write_register(5'd0, 32'hffffffff);
        expect_reads(5'd0, 32'd0, 5'd1, 32'h12345678);
        repeat (2) @(posedge clk);
        #1;
        expect_reads(5'd1, 32'h12345678, 5'd2, 32'hdeadbeef);

        if (errors != 0) begin
            $fatal(1, "tb_register_file failed with %0d errors", errors);
        end
        $display("PASS tb_register_file");
        $finish;
    end
endmodule

`default_nettype wire
