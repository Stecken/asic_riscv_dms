`timescale 1ns/1ps
`default_nettype none

// Long-running architectural stress test. It checks state coverage and
// externally visible behavior without reading DUT register/memory arrays.
module tb_core_stress;
    reg clk;
    reg rst;
    wire [31:0] debug_pc;
    wire [3:0]  debug_state;
    wire [4:0]  debug_rd;
    wire        debug_reg_write;
    wire [31:0] debug_writeback;
    wire        debug_mem_write;
    wire [31:0] debug_mem_address;
    wire [31:0] debug_mem_write_data;

    reg [31:0] register_model [0:31];
    integer state_counts [0:11];
    integer errors;
    integer cycles;
    integer store_count;
    integer i;
    reg saw_failure_write;
    reg [1023:0] wave_path;

    riscv_top #(
        .MEMORY_INIT_FILE  (`PROGRAM_HEX),
        .MEMORY_INIT_WORDS (`PROGRAM_WORDS)
    ) dut (
        .clk                 (clk),
        .rst                 (rst),
        .debug_pc            (debug_pc),
        .debug_state         (debug_state),
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
            state_counts[debug_state] = state_counts[debug_state] + 1;
            if (debug_reg_write && (debug_rd != 5'd0)) begin
                register_model[debug_rd] <= debug_writeback;
                if ((debug_rd == 5'd31) && (debug_writeback == 32'd99))
                    saw_failure_write = 1'b1;
            end
            if (debug_mem_write) begin
                if (debug_mem_address !== (32'd128 + ((store_count / 3) * 4) + (store_count % 3))) begin
                    $error("store address sequence: count=%0d addr=%h expected=%h",
                           store_count, debug_mem_address,
                           32'd128 + ((store_count / 3) * 4) + (store_count % 3));
                    errors = errors + 1;
                end
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

    task require_state_count;
        input [3:0] state_value;
        input integer minimum;
        begin
            if (state_counts[state_value] < minimum) begin
                $error("state %0d count=%0d expected at least %0d",
                       state_value, state_counts[state_value], minimum);
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
        saw_failure_write = 1'b0;
        for (i = 0; i < 32; i = i + 1)
            register_model[i] = 32'b0;
        for (i = 0; i < 12; i = i + 1)
            state_counts[i] = 0;

        if (!$value$plusargs("wave=%s", wave_path))
            wave_path = "core_stress.vcd";
        $dumpfile(wave_path);
        $dumpvars(0, tb_core_stress);

        repeat (2) @(posedge clk);
        #1 rst = 1'b0;
        while ((register_model[31] != 32'd1) && (cycles < 50000)) begin
            @(posedge clk);
            #1;
            cycles = cycles + 1;
        end

        if (cycles >= 50000)
            $fatal(1, "stress core timeout after %0d cycles at pc=%h state=%0d",
                   cycles, debug_pc, debug_state);

        check_register(5'd0,  32'h00000000);
        check_register(5'd1,  32'd33);
        check_register(5'd2,  32'd33);
        check_register(5'd4,  32'd256);
        check_register(5'd5,  32'd58);
        check_register(5'd6,  32'd1);
        check_register(5'd15, 32'd32);
        check_register(5'd22, 32'd8);
        check_register(5'd27, 32'd58);
        check_register(5'd28, 32'd58);
        check_register(5'd31, 32'd1);

        if (register_model[26] !== register_model[3]) begin
            $error("LW mismatch: x26=%h x3=%h", register_model[26], register_model[3]);
            errors = errors + 1;
        end
        if (register_model[29][15:0] !== register_model[3][15:0] ||
            register_model[30][15:0] !== register_model[3][15:0]) begin
            $error("halfword mismatch: x29=%h x30=%h x3=%h",
                   register_model[29], register_model[30], register_model[3]);
            errors = errors + 1;
        end
        if (saw_failure_write) begin
            $error("a branch took an unexpected failure path");
            errors = errors + 1;
        end
        if (store_count != 96) begin
            $error("store count=%0d expected 96", store_count);
            errors = errors + 1;
        end

        // Every state must be visited; thresholds prove the long loop actually
        // traversed the corresponding paths repeatedly, not just once.
        for (i = 0; i < 12; i = i + 1)
            require_state_count(i[3:0], 1);
        require_state_count(4'd2, 300);  // EX_R
        require_state_count(4'd3, 250);  // EX_I
        require_state_count(4'd4, 250);  // EX_MEM
        require_state_count(4'd5, 150);  // MEM_RD
        require_state_count(4'd6, 90);   // MEM_WR
        require_state_count(4'd9, 200);  // EX_B
        require_state_count(4'd10, 30);  // EX_J
        require_state_count(4'd11, 30);  // WB_J

        if (errors != 0)
            $fatal(1, "tb_core_stress failed with %0d errors", errors);
        $display("PASS tb_core_stress (%0d cycles, %0d stores)", cycles, store_count);
        $display("FSM counts IF=%0d ID=%0d EX_R=%0d EX_I=%0d EX_MEM=%0d MEM_RD=%0d MEM_WR=%0d WB_ALU=%0d WB_MEM=%0d EX_B=%0d EX_J=%0d WB_J=%0d",
                 state_counts[0], state_counts[1], state_counts[2], state_counts[3],
                 state_counts[4], state_counts[5], state_counts[6], state_counts[7],
                 state_counts[8], state_counts[9], state_counts[10], state_counts[11]);
        $finish;
    end
endmodule

`default_nettype wire
