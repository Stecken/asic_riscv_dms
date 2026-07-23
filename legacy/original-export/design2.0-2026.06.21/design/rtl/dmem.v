module dmem (
    input         clk,
    input         we,
    input  [31:0] addr,
    input  [31:0] wd,
    output [31:0] rd
);
    reg [31:0] mem [0:255];
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'b0;
    end
    assign rd = mem[addr[9:2]];
    always @(posedge clk) begin
        if (we)
            mem[addr[9:2]] <= wd;
    end
endmodule
