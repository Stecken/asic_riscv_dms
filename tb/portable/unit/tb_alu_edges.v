`timescale 1ns/1ps
`default_nettype none

// Boundary-oriented ALU testbench.  The existing tb_alu checks representative
// operations; this one targets shift masking and signedness boundaries.
module tb_alu_edges;
    reg  [31:0] a;
    reg  [31:0] b;
    reg  [3:0]  alu_ctrl;
    wire [31:0] result;
    wire        zero;
    integer errors;

    localparam [3:0] ADD  = 4'b0000;
    localparam [3:0] SUB  = 4'b0001;
    localparam [3:0] SLL  = 4'b0101;
    localparam [3:0] SRL  = 4'b0110;
    localparam [3:0] SRA  = 4'b0111;
    localparam [3:0] SLT  = 4'b1000;
    localparam [3:0] SLTU = 4'b1001;

    alu dut (.a(a), .b(b), .alu_ctrl(alu_ctrl), .result(result), .zero(zero));

    task check;
        input [3:0]  control_value;
        input [31:0] a_value;
        input [31:0] b_value;
        input [31:0] expected;
        begin
            alu_ctrl = control_value;
            a = a_value;
            b = b_value;
            #1;
            if (result !== expected) begin
                $error("ctrl=%b a=%h b=%h: got %h expected %h",
                       control_value, a_value, b_value, result, expected);
                errors = errors + 1;
            end
            if (zero !== (expected == 32'b0)) begin
                $error("zero mismatch ctrl=%b result=%h", control_value, result);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;

        // RISC-V uses only b[4:0]; 0, 1, 31 and values that wrap are critical.
        check(SLL, 32'h00000001, 32'd0,  32'h00000001);
        check(SLL, 32'h00000001, 32'd1,  32'h00000002);
        check(SLL, 32'h00000001, 32'd31, 32'h80000000);
        check(SLL, 32'h00000001, 32'd32, 32'h00000001);
        check(SLL, 32'h00000001, 32'd63, 32'h80000000);
        check(SRL, 32'h80000000, 32'd0,  32'h80000000);
        check(SRL, 32'h80000000, 32'd31, 32'h00000001);
        check(SRL, 32'h80000000, 32'd32, 32'h80000000);
        check(SRA, 32'h80000000, 32'd0,  32'h80000000);
        check(SRA, 32'h80000000, 32'd31, 32'hffffffff);
        check(SRA, 32'h80000000, 32'd32, 32'h80000000);

        // Signed and unsigned ordering at both sign boundaries.
        check(SLT,  32'h80000000, 32'h7fffffff, 32'd1);
        check(SLT,  32'h7fffffff, 32'h80000000, 32'd0);
        check(SLT,  32'h80000000, 32'h80000000, 32'd0);
        check(SLTU, 32'h00000000, 32'hffffffff, 32'd1);
        check(SLTU, 32'hffffffff, 32'h00000000, 32'd0);
        check(SLTU, 32'hffffffff, 32'hffffffff, 32'd0);

        // Natural 32-bit wrap and zero-result flag.
        check(ADD, 32'hffffffff, 32'd1, 32'h00000000);
        check(SUB, 32'h00000000, 32'd1, 32'hffffffff);
        check(4'b1111, 32'h12345678, 32'h87654321, 32'h00000000);

        if (errors != 0)
            $fatal(1, "tb_alu_edges failed with %0d errors", errors);
        $display("PASS tb_alu_edges");
        $finish;
    end
endmodule

`default_nettype wire
