`timescale 1ns/1ps
`default_nettype none

// Read/write data memory with byte and halfword access.
// Byte addresses 0x000..0x3ff select words 0..255.
// funct3 matches RISC-V load/store encoding:
//   000=byte(signed)  001=half(signed)  010=word
//   100=byte(unsigned) 101=half(unsigned)
module dmem (
    input  wire        clk,
    input  wire        we,
    input  wire [2:0]  funct3,
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire [31:0] addr,
    /* verilator lint_on UNUSEDSIGNAL */
    input  wire [31:0] wd,
    output reg  [31:0] rd
);

    reg [31:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            mem[i] = 32'b0;
        end
    end

    // Extract byte/halfword from the raw word using addr[1:0]
    wire [31:0] raw      = mem[addr[9:2]];
    wire [7:0]  byte_out = (addr[1:0] == 2'd0) ? raw[7:0]   :
                           (addr[1:0] == 2'd1) ? raw[15:8]  :
                           (addr[1:0] == 2'd2) ? raw[23:16] : raw[31:24];
    wire [15:0] half_out = addr[1] ? raw[31:16] : raw[15:0];

    // Read: sign-extend or zero-extend according to funct3
    always @(*) begin
        case (funct3)
            3'b000: rd = {{24{byte_out[7]}}, byte_out};  // LB
            3'b001: rd = {{16{half_out[15]}}, half_out}; // LH
            3'b010: rd = raw;                             // LW
            3'b100: rd = {24'b0, byte_out};              // LBU
            3'b101: rd = {16'b0, half_out};              // LHU
            default: rd = raw;
        endcase
    end

    // Write: update only the target bytes in the word
    always @(posedge clk) begin
        if (we) begin
            case (funct3[1:0])
                2'b10: mem[addr[9:2]] <= wd;
                2'b01: begin
                    if (addr[1])
                        mem[addr[9:2]][31:16] <= wd[15:0];
                    else
                        mem[addr[9:2]][15:0]  <= wd[15:0];
                end
                2'b00: begin
                    case (addr[1:0])
                        2'd0: mem[addr[9:2]][7:0]   <= wd[7:0];
                        2'd1: mem[addr[9:2]][15:8]  <= wd[7:0];
                        2'd2: mem[addr[9:2]][23:16] <= wd[7:0];
                        2'd3: mem[addr[9:2]][31:24] <= wd[7:0];
                    endcase
                end
                default: mem[addr[9:2]] <= wd;
            endcase
        end
    end

endmodule

`default_nettype wire
