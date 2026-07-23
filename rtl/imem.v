`timescale 1ns/1ps
`default_nettype none

// Read-only instruction memory. Byte addresses 0x000..0x3ff select words 0..255.
module imem #(
    parameter INIT_FILE = "",
    parameter integer INIT_WORDS = 0
) (
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire [31:0] addr,
    /* verilator lint_on UNUSEDSIGNAL */
    output wire [31:0] rd
);

    reg [31:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            mem[i] = 32'b0;
        end
        if ((INIT_FILE != "") && (INIT_WORDS > 0)) begin
            $readmemh(INIT_FILE, mem, 0, INIT_WORDS - 1);
        end
    end

    assign rd = mem[addr[9:2]];

endmodule

`default_nettype wire
