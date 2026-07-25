# Verificação

## Contrato

Todos os testes são self-checking: sucesso exige comparações automáticas e uma
falha termina com `$fatal(1, ...)`. Os logs ficam em `build/logs/` e o exit
status é preservado através dos pipelines com `pipefail`.

## Testes unitários

`make test-unit` compila cada top separadamente:

- `tb_alu`: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU, zero,
  negativos e wrap natural em 32 bits.
- `tb_register_file`: duas leituras, escrita, preservação, x0 e tentativa de
  escrita em x0.
- `tb_imem`: leitura, estado inicial e semântica word-addressed da memória de instruções.
- `tb_dmem`: estado inicial, escrita síncrona, leitura e semântica word-addressed da memória de dados.
- `tb_immediate_gen`: formatos I, S, B, U, J e default sem imediato.
- `tb_branch_comp`: BEQ, BNE, BLT, BGE, BLTU, BGEU e diferenças signed/unsigned.
- `tb_control`: SRA, writeback R, caminho LW/`addr_src` e branch tomado/não tomado.

São sete testbenches unitários. A execução atual no devcontainer passou em todos
eles.

O teste integrado executa SW/LW na DMEM enquanto o fetch continua vindo da
IMEM. `make test-legacy` repete uma verificação de isolamento nas duas formas do
export antigo.

## Teste integrado

`make test-core TEST=core_basic`:

1. valida que todos os `.hex` correspondem aos `.S`;
2. compila a árvore oficial com `RISCV_DEBUG`;
3. carrega o programa pelo parâmetro `MEMORY_INIT_FILE`;
4. observa writes arquiteturais por portas de debug estáveis;
5. verifica registradores, store em endereço 128 e timeout;
6. grava `build/logs/test-core-core_basic.log`.

O programa cobre operações R, ADDI, negativos, LW/SW, os seis branches, LUI e
JAL com link/alvo corretos. Os demais programas Assembly são vetores preparados,
ainda não têm testbenches integrados independentes.

Na validação atual, `core_basic` terminou em 152 ciclos e o testbench confirmou
todos os registradores esperados e o store de `8` para o endereço `128`.

## Programas

`scripts/assemble_test_program.py` é um assembler de teste mínimo. Suporta os
mnemonics documentados em `docs/isa-status.md`, labels, `.word`, `nop` e `j`.
Ele valida registradores, ranges de imediatos e alinhamento de branch/jump.

```bash
make programs        # regenera os .hex versionados
make programs-check  # somente verifica determinismo
```

Uma GNU RISC-V toolchain e testes oficiais de ISA ficam para uma fase posterior,
quando houver maior cobertura e traps/assinatura formalizada.
