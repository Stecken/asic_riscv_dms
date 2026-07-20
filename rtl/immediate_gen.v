`timescale 1ns/1ps
`default_nettype none

module immediate_gen (
    input  wire [31:0] instruction,
    output reg  [31:0] immediate
);

    wire [6:0] opcode = instruction[6:0];

    localparam [6:0] OP_LOAD   = 7'b0000011;
    localparam [6:0] OP_IMM    = 7'b0010011;
    localparam [6:0] OP_AUIPC  = 7'b0010111;
    localparam [6:0] OP_STORE  = 7'b0100011;
    localparam [6:0] OP_BRANCH = 7'b1100011;
    localparam [6:0] OP_JAL    = 7'b1101111;
    localparam [6:0] OP_LUI    = 7'b0110111;

    always @(*) begin
        case (opcode)
            OP_STORE: begin
                immediate = {{20{instruction[31]}}, instruction[31:25],
                             instruction[11:7]};
            end
            OP_BRANCH: begin
                immediate = {{19{instruction[31]}}, instruction[31],
                             instruction[7], instruction[30:25],
                             instruction[11:8], 1'b0};
            end
            OP_JAL: begin
                immediate = {{11{instruction[31]}}, instruction[31],
                             instruction[19:12], instruction[20],
                             instruction[30:21], 1'b0};
            end
            OP_LUI, OP_AUIPC: begin
                immediate = {instruction[31:12], 12'b0};
            end
            OP_LOAD, OP_IMM: begin
                immediate = {{20{instruction[31]}}, instruction[31:20]};
            end
            default: begin
                immediate = 32'b0;
            end
        endcase
    end

endmodule

`default_nettype wire
