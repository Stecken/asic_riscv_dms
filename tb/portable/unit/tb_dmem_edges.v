`timescale 1ns/1ps
`default_nettype none

// Check that sub-word stores select the correct lane and preserve all others.
module tb_dmem_edges;
    reg        clk;
    reg        we;
    reg  [2:0] funct3;
    reg  [31:0] addr;
    reg  [31:0] wd;
    wire [31:0] rd;
    integer errors;

    dmem dut (.clk(clk), .we(we), .funct3(funct3), .addr(addr), .wd(wd), .rd(rd));
    always #5 clk = ~clk;

    task write_mem;
        input [31:0] address;
        input [31:0] data;
        input [2:0]  access;
        begin
            addr = address;
            wd = data;
            funct3 = access;
            we = 1'b1;
            @(posedge clk);
            #1;
            we = 1'b0;
        end
    endtask

    task check_read;
        input [31:0] address;
        input [2:0] access;
        input [31:0] expected;
        begin
            addr = address;
            funct3 = access;
            #1;
            if (rd !== expected) begin
                $error("addr=%h funct3=%b: got %h expected %h",
                       address, access, rd, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        we = 1'b0;
        funct3 = 3'b010;
        addr = 0;
        wd = 0;
        errors = 0;

        // Initial word is little-endian: A1 B2 C3 D4 by increasing address.
        write_mem(32'd400, 32'ha1b2c3d4, 3'b010);
        check_read(32'd400, 3'b010, 32'ha1b2c3d4);

        write_mem(32'd401, 32'h00000080, 3'b000);
        check_read(32'd400, 3'b010, 32'ha1b280d4);
        check_read(32'd401, 3'b000, 32'hffffff80);
        check_read(32'd401, 3'b100, 32'h00000080);

        write_mem(32'd402, 32'h0000007f, 3'b000);
        check_read(32'd400, 3'b010, 32'ha17f80d4);
        check_read(32'd402, 3'b000, 32'h0000007f);

        write_mem(32'd403, 32'h000000ff, 3'b000);
        check_read(32'd400, 3'b010, 32'hff7f80d4);
        check_read(32'd403, 3'b000, 32'hffffffff);
        check_read(32'd403, 3'b100, 32'h000000ff);

        // SH must preserve the opposite half and implement both lanes.
        write_mem(32'd400, 32'h00001234, 3'b001);
        check_read(32'd400, 3'b010, 32'hff7f1234);
        write_mem(32'd402, 32'h0000abcd, 3'b001);
        check_read(32'd400, 3'b010, 32'habcd1234);
        check_read(32'd402, 3'b001, 32'hffffabcd);
        check_read(32'd402, 3'b101, 32'h0000abcd);

        if (errors != 0)
            $fatal(1, "tb_dmem_edges failed with %0d errors", errors);
        $display("PASS tb_dmem_edges");
        $finish;
    end
endmodule

`default_nettype wire
