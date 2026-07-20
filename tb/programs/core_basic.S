# Integrated smoke program for the implemented RV32I subset.
    addi  x1,  x0, 5
    addi  x2,  x0, 3
    add   x3,  x1, x2
    sub   x4,  x1, x2
    and   x5,  x1, x2
    or    x6,  x1, x2
    xor   x7,  x1, x2
    sll   x8,  x2, x2
    srl   x9,  x8, x2
    addi  x10, x0, -8
    sra   x11, x10, x2
    slt   x12, x10, x0
    sltu  x13, x10, x0
    sw    x3, 128(x0)
    lw    x14, 128(x0)
    beq   x14, x3, equal
    addi  x15, x0, 99
equal:
    bne   x14, x3, not_equal
    addi  x16, x0, 42
not_equal:
    lui   x17, 0x12345
    jal   x18, after_jump
    addi  x19, x0, 99
after_jump:
    addi  x20, x0, 77
    addi  x31, x0, 1
done:
    jal   x0, done
