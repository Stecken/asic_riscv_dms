# Long-loop integrated FSM stress program.
# Each iteration exercises R/I ALU paths, all implemented memory widths and
# every branch comparator; the loop itself repeatedly traverses the FSM.
    addi  x1,  x0, 1
    addi  x2,  x0, 33
    addi  x3,  x0, 0
    addi  x4,  x0, 128
    addi  x5,  x0, 90
    addi  x6,  x0, 1
    addi  x15, x0, 0
    lui   x20, 0x12345
    auipc x21, 0x1

stress_loop:
    add   x3,  x3,  x5
    sub   x5,  x5,  x6
    and   x7,  x3,  x5
    or    x8,  x7,  x3
    xor   x9,  x8,  x5
    sll   x10, x9,  x6
    srl   x11, x10, x6
    sra   x12, x10, x6
    slt   x13, x5,  x3
    sltu  x14, x5,  x3
    addi  x15, x15, 1
    andi  x16, x3,  0xff
    ori   x17, x16,  0x100
    xori  x18, x17, -1
    slli  x19, x18, 1
    srli  x22, x19, 1
    srai  x23, x19, 1
    slti  x24, x5,  0
    sltiu x25, x5,  0

    sw    x3,  0(x4)
    lw    x26, 0(x4)
    sb    x5,  1(x4)
    lb    x27, 1(x4)
    lbu   x28, 1(x4)
    sh    x3,  2(x4)
    lh    x29, 2(x4)
    lhu   x30, 2(x4)

    # BEQ is deliberately not taken; JAL skips its failure arm.
    beq   x1, x0, fail_beq
    jal   x0, after_beq
fail_beq:
    addi  x31, x0, 99
after_beq:

    # The other five comparator forms are deliberately taken.
    bne   x1, x0, after_bne
    addi  x31, x0, 99
after_bne:
    blt   x6, x2, after_blt
    addi  x31, x0, 99
after_blt:
    bge   x2, x1, after_bge
    addi  x31, x0, 99
after_bge:
    bltu  x1, x2, after_bltu
    addi  x31, x0, 99
after_bltu:
    bgeu  x2, x1, after_bgeu
    addi  x31, x0, 99
after_bgeu:

    addi  x4, x4, 4
    addi  x1, x1, 1
    bne   x1, x2, stress_loop

    # Verify JAL target/link after the long loop.
    auipc x20, 0
    jal   x21, after_jump
    addi  x31, x0, 99
after_jump:
    sub   x22, x21, x20
    addi  x31, x0, 1
finished:
    jal   x0, finished
