`timescale 1ns/1ps
`default_nettype none

module tb_branch_comp;
    reg [31:0] a;
    reg [31:0] b;
    reg [2:0] funct3;
    wire taken;
    integer errors;

    branch_comp dut (.a(a), .b(b), .funct3(funct3), .taken(taken));

    task check;
        input [31:0] test_a;
        input [31:0] test_b;
        input [2:0] test_funct3;
        input expected;
        begin
            a = test_a;
            b = test_b;
            funct3 = test_funct3;
            #1;
            if (taken !== expected) begin
                $error("a=%h b=%h funct3=%b: got %b, expected %b",
                       a, b, funct3, taken, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        check(32'd5, 32'd5, 3'b000, 1'b1);
        check(32'd5, 32'd10, 3'b000, 1'b0);
        check(32'd5, 32'd10, 3'b001, 1'b1);
        check(32'd5, 32'd5, 3'b001, 1'b0);
        check(32'd5, 32'd10, 3'b100, 1'b1);
        check(32'd10, 32'd5, 3'b100, 1'b0);
        check(32'd10, 32'd5, 3'b101, 1'b1);
        check(32'd5, 32'd10, 3'b101, 1'b0);
        check(32'hffffffff, 32'd1, 3'b100, 1'b1);
        check(32'hffffffff, 32'd1, 3'b110, 1'b0);
        check(32'd1, 32'hffffffff, 3'b110, 1'b1);
        check(32'hffffffff, 32'd1, 3'b111, 1'b1);
        check(32'd1, 32'hffffffff, 3'b111, 1'b0);
        check(32'd0, 32'd0, 3'b010, 1'b0);

        if (errors != 0) begin
            $fatal(1, "tb_branch_comp failed with %0d errors", errors);
        end
        $display("PASS tb_branch_comp");
        $finish;
    end
endmodule

`default_nettype wire
