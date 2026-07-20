    addi x1, x0, 1
    addi x2, x0, 1
    beq  x1, x2, equal
    addi x3, x0, 99
equal:
    bne  x1, x0, different
    addi x4, x0, 99
different:
    addi x5, x0, 5
done:
    jal x0, done
