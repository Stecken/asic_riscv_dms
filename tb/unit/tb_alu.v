`timescale 1ns/1ps
`default_nettype none

module tb_alu;
    reg  [31:0] a;
    reg  [31:0] b;
    reg  [3:0]  alu_ctrl;
    wire [31:0] result;
    wire        zero;
    integer errors;

    alu dut (.a(a), .b(b), .alu_ctrl(alu_ctrl), .result(result), .zero(zero));

    task check;
        input [3:0] control_value;
        input [31:0] a_value;
        input [31:0] b_value;
        input [31:0] expected;
        begin
            alu_ctrl = control_value;
            a = a_value;
            b = b_value;
            #1;
            if (result !== expected) begin
                $error("ALU ctrl=%b a=%h b=%h: got %h, expected %h",
                       control_value, a_value, b_value, result, expected);
                errors = errors + 1;
            end
            if (zero !== (expected == 32'b0)) begin
                $error("zero flag mismatch for result %h", expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        check(4'b0000, 32'd5,        32'd3,  32'd8);
        check(4'b0000, 32'hffffffff, 32'd1,  32'd0);         // 32-bit wrap
        check(4'b0001, 32'd5,        32'd5,  32'd0);
        check(4'b0001, 32'd3,        32'd5,  32'hfffffffe);
        check(4'b0010, 32'hf0f0aa55, 32'h0ff00f0f, 32'h00f00a05);
        check(4'b0011, 32'hf0f00000, 32'h00000f0f, 32'hf0f00f0f);
        check(4'b0100, 32'haaaa5555, 32'hffff0000, 32'h55555555);
        check(4'b0101, 32'd3,        32'd4,  32'd48);
        check(4'b0110, 32'h80000000, 32'd4,  32'h08000000);
        check(4'b0111, 32'h80000000, 32'd4,  32'hf8000000);
        check(4'b1000, 32'hffffffff, 32'd1,  32'd1);         // -1 < 1
        check(4'b1000, 32'd1,        32'hffffffff, 32'd0);
        check(4'b1001, 32'hffffffff, 32'd1,  32'd0);
        check(4'b1001, 32'd1,        32'hffffffff, 32'd1);

        if (errors != 0) begin
            $fatal(1, "tb_alu failed with %0d errors", errors);
        end
        $display("PASS tb_alu");
        $finish;
    end
endmodule

`default_nettype wire
