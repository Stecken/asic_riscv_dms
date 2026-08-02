`timescale 1ns/1ps
`default_nettype none

// Integrated bug-finding test: checks architectural writes only through the
// stable RISCV_DEBUG interface, never by peeking into DUT register arrays.
module tb_core_adversarial;
    reg clk;
    reg rst;
    wire [31:0] debug_pc;
    wire [3:0]  debug_state;
    wire [31:0] debug_instruction;
    wire [4:0]  debug_rd;
    wire        debug_reg_write;
    wire [31:0] debug_writeback;
    wire        debug_mem_write;
    wire [31:0] debug_mem_address;
    wire [31:0] debug_mem_write_data;

    reg [31:0] register_model [0:31];
    integer errors;
    integer cycles;
    integer store_count;
    integer i;
    reg [1023:0] wave_path;

    riscv_top #(
        .MEMORY_INIT_FILE  (`PROGRAM_HEX),
        .MEMORY_INIT_WORDS (`PROGRAM_WORDS)
    ) dut (
        .clk                 (clk),
        .rst                 (rst),
        .debug_pc            (debug_pc),
        .debug_state         (debug_state),
        .debug_instruction   (debug_instruction),
        .debug_rd            (debug_rd),
        .debug_reg_write     (debug_reg_write),
        .debug_writeback     (debug_writeback),
        .debug_mem_write     (debug_mem_write),
        .debug_mem_address   (debug_mem_address),
        .debug_mem_write_data(debug_mem_write_data)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!rst) begin
            if (debug_reg_write && (debug_rd != 5'd0))
                register_model[debug_rd] <= debug_writeback;

            if (debug_mem_write) begin
                case (store_count)
                    0: begin
                        if (debug_mem_address !== 32'd128 ||
                            debug_mem_write_data !== 32'h11223344) begin
                            $error("SW mismatch: addr=%h data=%h",
                                   debug_mem_address, debug_mem_write_data);
                            errors = errors + 1;
                        end
                    end
                    1: begin
                        if (debug_mem_address !== 32'd129 ||
                            debug_mem_write_data !== 32'h000000ff) begin
                            $error("SB mismatch: addr=%h data=%h",
                                   debug_mem_address, debug_mem_write_data);
                            errors = errors + 1;
                        end
                    end
                    2: begin
                        if (debug_mem_address !== 32'd130 ||
                            debug_mem_write_data !== 32'h00000055) begin
                            $error("SH mismatch: addr=%h data=%h",
                                   debug_mem_address, debug_mem_write_data);
                            errors = errors + 1;
                        end
                    end
                    default: begin
                        $error("unexpected extra store: addr=%h data=%h",
                               debug_mem_address, debug_mem_write_data);
                        errors = errors + 1;
                    end
                endcase
                store_count = store_count + 1;
            end
        end
    end

    task check_register;
        input [4:0] address;
        input [31:0] expected;
        begin
            if (register_model[address] !== expected) begin
                $error("x%0d: got %h expected %h", address,
                       register_model[address], expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        errors = 0;
        cycles = 0;
        store_count = 0;
        for (i = 0; i < 32; i = i + 1)
            register_model[i] = 32'b0;

        if (!$value$plusargs("wave=%s", wave_path))
            wave_path = "core_adversarial.vcd";
        $dumpfile(wave_path);
        $dumpvars(0, tb_core_adversarial);

        repeat (2) @(posedge clk);
        #1 rst = 1'b0;

        while ((register_model[31] != 32'd1) && (cycles < 1000)) begin
            @(posedge clk);
            #1;
            cycles = cycles + 1;
        end

        if (cycles >= 1000)
            $fatal(1, "adversarial core timeout: pc=%h state=%0d instruction=%h",
                   debug_pc, debug_state, debug_instruction);

        check_register(5'd0,  32'h00000000);
        check_register(5'd1,  32'h000000ec);
        check_register(5'd2,  32'h00000008);
        check_register(5'd3,  32'h00000055);
        check_register(5'd4,  32'hffffffaa);
        check_register(5'd5,  32'h80000000);
        check_register(5'd6,  32'h00000001);
        check_register(5'd7,  32'hffffffff);
        check_register(5'd8,  32'h00000001);
        check_register(5'd9,  32'h00000000);
        check_register(5'd10, 32'h80000000);
        check_register(5'd11, 32'h00001028);
        check_register(5'd12, 32'h11223344);
        check_register(5'd13, 32'h00000044);
        check_register(5'd14, 32'h00000033);
        check_register(5'd15, 32'h00001122);
        check_register(5'd16, 32'h00001122);
        check_register(5'd17, 32'hffffff44);
        check_register(5'd18, 32'h0055ff44);
        check_register(5'd19, 32'h000000ff);
        check_register(5'd20, 32'h00000001);
        check_register(5'd21, 32'h00000001);
        check_register(5'd22, 32'h00000001);
        check_register(5'd23, 32'h00000001);
        check_register(5'd24, 32'h00000001);
        check_register(5'd25, 32'h00000002);
        check_register(5'd26, 32'h00000001);
        check_register(5'd27, 32'hffffffff);
        check_register(5'd28, 32'h00000001);
        check_register(5'd29, 32'h00000001);
        check_register(5'd30, 32'h00000001);
        check_register(5'd31, 32'h00000001);

        if (store_count != 3) begin
            $error("store count: got %0d expected 3", store_count);
            errors = errors + 1;
        end
        if (errors != 0)
            $fatal(1, "tb_core_adversarial failed with %0d errors", errors);
        $display("PASS tb_core_adversarial (%0d cycles)", cycles);
        $finish;
    end
endmodule

`default_nettype wire
