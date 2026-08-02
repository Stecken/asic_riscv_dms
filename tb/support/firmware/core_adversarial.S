# Adversarial integrated program for implemented RV32I instructions.
# It deliberately targets signedness, immediate fields, lane preservation and
# both directions of every implemented conditional branch.
    addi  x1,  x0, -1
    andi  x2,  x1, 0xff
    ori   x3,  x0, 0x55
    xori  x4,  x3, -1
    slli  x5,  x2, 31
    srli  x6,  x5, 31
    srai  x7,  x5, 31
    slti  x8,  x1, 0
    sltiu x9,  x1, 0
    lui   x10, 0x80000
    auipc x11, 0x1

    lui   x12, 0x11223
    ori   x12, x12, 0x344
    sw    x12, 128(x0)
    lb    x13, 128(x0)
    lbu   x14, 129(x0)
    lh    x15, 130(x0)
    lhu   x16, 130(x0)
    sb    x2, 129(x0)
    lh    x17, 128(x0)
    sh    x3, 130(x0)
    lw    x18, 128(x0)
    lbu   x19, 129(x0)

    # BEQ taken.
    addi  x20, x0, 99
    addi  x21, x0, 1
    addi  x22, x0, 1
    beq   x21, x22, beq_taken
    jal   x0, beq_done
beq_taken:
    addi  x20, x0, 1
beq_done:

    # BNE not taken, then taken.
    addi  x23, x0, 99
    bne   x21, x22, bne_not_taken
    addi  x23, x0, 1
    jal   x0, bne_done
bne_not_taken:
    addi  x23, x0, 99
bne_done:
    addi  x24, x0, 99
    addi  x25, x0, 2
    bne   x21, x25, bne_taken
    jal   x0, bne_taken_done
bne_taken:
    addi  x24, x0, 1
bne_taken_done:

    # Signed BLT and BGE taken.
    addi  x26, x0, 99
    addi  x27, x0, -1
    blt   x27, x21, blt_taken
    jal   x0, blt_done
blt_taken:
    addi  x26, x0, 1
blt_done:
    addi  x28, x0, 99
    bge   x21, x27, bge_taken
    jal   x0, bge_done
bge_taken:
    addi  x28, x0, 1
bge_done:

    # Unsigned BLTU not taken and BGEU taken for 0xffffffff vs 1.
    addi  x29, x0, 99
    bltu  x27, x21, bltu_taken
    addi  x29, x0, 1
    jal   x0, bltu_done
bltu_taken:
    addi  x29, x0, 99
bltu_done:
    addi  x30, x0, 99
    bgeu  x27, x21, bgeu_taken
    jal   x0, bgeu_done
bgeu_taken:
    addi  x30, x0, 1
bgeu_done:

    # AUIPC followed by JAL makes the link check independent of absolute PC.
    auipc x31, 0
    jal   x1, jal_target
    addi  x2, x0, 99
jal_target:
    sub   x2, x1, x31
    addi  x31, x0, 1
finished:
    jal   x0, finished
