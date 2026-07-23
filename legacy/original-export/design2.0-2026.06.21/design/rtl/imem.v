module imem #(
    parameter INIT_FILE = "",
    parameter integer INIT_WORDS = 0
) (
    input  [31:0] addr,
    output [31:0] rd
);
    reg [31:0] mem [0:255];
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'b0;
        if ((INIT_FILE != "") && (INIT_WORDS > 0))
            $readmemh(INIT_FILE, mem, 0, INIT_WORDS - 1);
    end
    assign rd = mem[addr[9:2]];
endmodule
