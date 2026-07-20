    addi x1, x0, 85
    sw   x1, 128(x0)
    lw   x2, 128(x0)
done:
    jal  x0, done
