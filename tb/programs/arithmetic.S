    addi x1, x0, -16
    addi x2, x0, 2
    add  x3, x1, x2
    sub  x4, x2, x1
    sll  x5, x2, x2
    srl  x6, x5, x2
    sra  x7, x1, x2
    slt  x8, x1, x2
    sltu x9, x1, x2
done:
    jal x0, done
