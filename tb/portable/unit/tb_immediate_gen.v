`timescale 1ns/1ps
`default_nettype none

module tb_immediate_gen;
    reg  [31:0] instruction;
    wire [31:0] immediate;
    integer errors;

    immediate_gen dut (.instruction(instruction), .immediate(immediate));

    task check;
        input [31:0] instruction_value;
        input [31:0] expected;
        begin
            instruction = instruction_value;
            #1;
            if (immediate !== expected) begin
                $error("immediate for %h: got %h, expected %h",
                       instruction_value, immediate, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        check(32'hfff00093, 32'hffffffff); // addi x1,x0,-1 (I)
        check(32'h000100e7, 32'h00000000); // jalr x1,0(x2) (I)
        check(32'hffc100e7, 32'hfffffffc); // jalr x1,-4(x2) (I) sign-extended
        check(32'hfe302e23, 32'hfffffffc); // sw x3,-4(x0) (S)
        check(32'h00208463, 32'h00000008); // beq x1,x2,+8 (B)
        check(32'h008000ef, 32'h00000008); // jal x1,+8 (J)
        check(32'h123450b7, 32'h12345000); // lui x1,0x12345 (U)
        check(32'h12345117, 32'h12345000); // auipc x2,0x12345 (U)
        check(32'h00000033, 32'h00000000); // R type has no immediate

        if (errors != 0) begin
            $fatal(1, "tb_immediate_gen failed with %0d errors", errors);
        end
        $display("PASS tb_immediate_gen");
        $finish;
    end
endmodule

`default_nettype wire
