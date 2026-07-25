module control (
    input      clk,
    input      rst,
    input      [6:0] opcode,
    input      [2:0] funct3,
    input      funct7_5,
    input      branch_taken,
    output reg pc_write,
    output reg ir_write,
    output reg reg_write,
    output reg mem_write,
    output reg addr_src,
    output reg [1:0] pc_src,
    output reg [1:0] alu_src_a,
    output reg [1:0] alu_src_b,
    output reg [1:0] result_src,
    output reg [3:0] alu_ctrl
);

    // Estados da FSM
    localparam IF  = 4'd0;  // Instruction Fetch
    localparam ID  = 4'd1;  // Instruction Decode
    localparam EX_R   = 4'd2;  // Execute tipo R
    localparam EX_I   = 4'd3;  // Execute tipo I
    localparam EX_MEM = 4'd4;  // Execute Load/Store
    localparam MEM_RD = 4'd5;  // Memory Read
    localparam MEM_WR = 4'd6;  // Memory Write
    localparam WB_R   = 4'd7;  // Write Back tipo R/I
    localparam WB_MEM = 4'd8;  // Write Back Load
    localparam EX_B   = 4'd9;  // Execute Branch
    localparam EX_J   = 4'd10; // Execute Jump
    localparam WB_J   = 4'd11; // Write Back Jump

    // Opcodes do RISC-V
    localparam OP_R   = 7'b0110011; // tipo R
    localparam OP_I   = 7'b0010011; // tipo I
    localparam OP_L   = 7'b0000011; // Load
    localparam OP_S   = 7'b0100011; // Store
    localparam OP_B   = 7'b1100011; // Branch
    localparam OP_JAL = 7'b1101111; // JAL
    localparam OP_LUI = 7'b0110111; // LUI

    reg [3:0] state, next_state;

    // Registrador de estado
    always @(posedge clk or posedge rst) begin
        if (rst) state <= IF;
        else     state <= next_state;
    end

    // Lógica do próximo estado
    always @(*) begin
        case (state)
            IF: next_state = ID;

            ID: case (opcode)
                    OP_R:   next_state = EX_R;
                    OP_I:   next_state = EX_I;
                    OP_L:   next_state = EX_MEM;
                    OP_S:   next_state = EX_MEM;
                    OP_B:   next_state = EX_B;
                    OP_JAL: next_state = EX_J;
                    OP_LUI: next_state = WB_R;
                    default: next_state = IF;
                endcase

            EX_R:   next_state = WB_R;
            EX_I:   next_state = WB_R;
            EX_MEM: next_state = (opcode == OP_L) ? MEM_RD : MEM_WR;
            MEM_RD: next_state = WB_MEM;
            MEM_WR: next_state = IF;
            WB_R:   next_state = IF;
            WB_MEM: next_state = IF;
            EX_B:   next_state = IF;
            EX_J:   next_state = WB_J;
            WB_J:   next_state = IF;
            default: next_state = IF;
        endcase
    end

    // Lógica de saída — sinais de controle
    always @(*) begin
        // Valores padrão
        pc_write   = 0;
        ir_write   = 0;
        reg_write  = 0;
        mem_write  = 0;
        addr_src   = 0;
        pc_src     = 2'b00;
        alu_src_a  = 2'b00;
        alu_src_b  = 2'b00;
        result_src = 2'b00;
        alu_ctrl   = 4'b0000;

        case (state)
            IF: begin
                ir_write  = 1;
                pc_write  = 1;
                alu_src_a = 2'b00; // PC
                alu_src_b = 2'b01; // +4
                alu_ctrl  = 4'b0000; // ADD
                pc_src    = 2'b00;
            end

            ID: begin
                alu_src_a = 2'b00; // PC
                alu_src_b = 2'b10; // imediato
                alu_ctrl  = 4'b0000; // ADD
            end

            EX_R: begin
                alu_src_a = 2'b01; // registrador A
                alu_src_b = 2'b00; // registrador B
                case ({funct7_5, funct3})
                    4'b0000: alu_ctrl = 4'b0000; // ADD
                    4'b1000: alu_ctrl = 4'b0001; // SUB
                    4'b0111: alu_ctrl = 4'b0010; // AND
                    4'b0110: alu_ctrl = 4'b0011; // OR
                    4'b0100: alu_ctrl = 4'b0100; // XOR
                    4'b0010: alu_ctrl = 4'b1000; // SLT
                    4'b0011: alu_ctrl = 4'b1001; // SLTU
                    default: alu_ctrl = 4'b0000;
                endcase
            end

            EX_I: begin
                alu_src_a = 2'b01; // registrador A
                alu_src_b = 2'b10; // imediato
                case (funct3)
                    3'b000: alu_ctrl = 4'b0000; // ADDI
                    3'b111: alu_ctrl = 4'b0010; // ANDI
                    3'b110: alu_ctrl = 4'b0011; // ORI
                    3'b100: alu_ctrl = 4'b0100; // XORI
                    3'b010: alu_ctrl = 4'b1000; // SLTI
                    default: alu_ctrl = 4'b0000;
                endcase
            end

            EX_MEM: begin
                alu_src_a = 2'b01; // registrador A
                alu_src_b = 2'b10; // imediato
                alu_ctrl  = 4'b0000; // ADD — calcula endereço
            end

            MEM_RD: begin
                addr_src   = 1;
                result_src = 2'b01; // MDR
            end

            MEM_WR: begin
                addr_src  = 1;
                mem_write = 1;
            end

            WB_R: begin
                reg_write  = 1;
                result_src = 2'b00; // alu_out
            end

            WB_MEM: begin
                reg_write  = 1;
                result_src = 2'b01; // MDR
            end

            EX_B: begin
                pc_src    = 2'b01;
                pc_write  = branch_taken;
            end

            EX_J: begin
                alu_src_a = 2'b00; // PC
                alu_src_b = 2'b10; // imediato
                alu_ctrl  = 4'b0000; // ADD
            end

            WB_J: begin
                reg_write  = 1;
                result_src = 2'b10; // PC+4 já salvo
                pc_write   = 1;
                pc_src     = 2'b01; // alu_out
            end
        endcase
    end

endmodule
