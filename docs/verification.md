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

A suíte unitária inclui os testbenches básicos e os testes adicionais de borda descritos abaixo.

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
JAL com link/alvo corretos. O firmware `core_adversarial` fornece um testbench
integrado independente para os caminhos adicionais descritos abaixo.

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

## Cobertura adversarial adicional

Além do smoke test `core_basic`, o alvo `make test-adversarial` compila
`tb/portable/tb_core_adversarial.v` com `core_adversarial.S`. O testbench verifica
somente writes arquiteturais pelas portas `RISCV_DEBUG` e os três stores observados
na interface, sem acessar arrays internos do DUT. Ele cobre `ANDI/ORI/XORI`,
`SLLI/SRLI/SRAI`, `SLTI/SLTIU`, `AUIPC` em PC não zero, `LB/LBU/LH/LHU`,
`SB/SH`, os caminhos tomado e não tomado dos seis branches, `JAL`/link e
preservação de `x0`.

`tb_alu_edges` cobre quantidades de shift 0, 1, 31, 32 e 63, limites signed e
unsigned, wrap e controle inválido. `tb_dmem_edges` cobre os quatro bytes e
as duas metades da palavra, incluindo preservação dos lanes não selecionados.
O alvo `make test` executa esses testes junto com a suíte existente.

## Campanha pesada da FSM

A campanha `make test-unit` inclui `tb_control_stress`, que repete 20 vezes a
matriz completa de transições da FSM: R, I, loads, stores, os seis branches
com `branch_taken=0/1`, JAL/JALR, LUI/AUIPC e opcode inválido. Também aplica
reset assíncrono em `EX_MEM`, `MEM_RD`, `EX_B`, `EX_J` e `WB_ALU`.

`make test-stress` executa `core_stress.S` através do processador completo. O
programa repete 32 iterações com ALU R/I, todas as larguras de memória e todos
os comparadores de branch. O checker observa apenas debug arquitetural, valida
96 stores e exige que todos os 12 estados sejam visitados repetidamente.
