`timescale 1ns/1ps
`default_nettype none

// Read/write data memory. Byte addresses 0x000..0x3ff select words 0..255.
module dmem (
    input  wire        clk,
    input  wire        we,
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire [31:0] addr,
    /* verilator lint_on UNUSEDSIGNAL */
    input  wire [31:0] wd,
    output wire [31:0] rd
);

    reg [31:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            mem[i] = 32'b0;
        end
    end

    assign rd = mem[addr[9:2]];

    always @(posedge clk) begin
        if (we) begin
            mem[addr[9:2]] <= wd;
        end
    end

endmodule

`default_nettype wire
