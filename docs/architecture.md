# Arquitetura

## Escopo

CPU multiciclo de 32 bits, com banco de 32 registradores, IMEM somente de leitura
e DMEM de leitura/escrita. Cada memória possui 256 palavras de 32 bits (1 KiB
endereçável sem verificação de faixa). A leitura é combinacional e a escrita da
DMEM ocorre na borda de subida. Os dois bits menos significativos do endereço
são ignorados; acessos desalinhados não geram trap e atualmente aliasam a palavra.

O projeto não possui pipeline, cache, forwarding, interrupções, CSRs, unidade M
nem barramento externo. Não é uma implementação RV32I completa.

## Hierarquia oficial

```text
riscv_top
├── control
└── datapath
    ├── immediate_gen
    ├── alu
    ├── register_file
    ├── imem
    └── dmem
```

`rtl/files.f` é o manifesto determinístico. `legacy/` e qualquer netlist em
`build/` não participam de lint, simulação ou síntese normal.

## Clock e reset

- `clk`: lógica sequencial na borda de subida.
- `rst`: reset assíncrono, ativo em nível alto.
- Reset coloca PC, PC antigo, IR, MDR, operandos, ALUOut e estado da FSM em zero.
- O banco de registradores e as memórias usam inicialização a zero para este
  laboratório/fluxo de FPGA; não há interface de reset para esses arrays.

## Fluxo multiciclo

O fetch lê a instrução no PC atual, salva esse endereço em `old_pc` e incrementa
o PC em 4. `old_pc` é a base de branch/JAL/AUIPC e do link `PC+4`, evitando a
ambiguidade que existia no export original.

Estados da FSM:

| Valor | Estado | Papel |
| ---: | --- | --- |
| 0 | IF | Busca instrução e incrementa PC. |
| 1 | ID | Captura operandos e calcula imediato/alvo. |
| 2 | EX_R | Executa operação register-register. |
| 3 | EX_I | Executa operação com imediato. |
| 4 | EX_MEM | Calcula endereço efetivo. |
| 5 | MEM_RD | Captura leitura no MDR. |
| 6 | MEM_WR | Escreve palavra na DMEM. |
| 7 | WB_ALU | Escreve ALUOut no banco. |
| 8 | WB_MEM | Escreve MDR no banco. |
| 9 | EX_B | Compara BEQ/BNE e atualiza PC quando tomado. |
| 10 | EX_J | Recalcula/preserva alvo JAL. |
| 11 | WB_J | Escreve link e instala o alvo. |

## Interface de observação

Com `RISCV_DEBUG`, `riscv_top` expõe PC, instrução, estado, campos de decode,
operandos, sinais da ALU, writeback e barramento de memória. Esses taps não
alteram a lógica funcional. Simulação integrada, waveform e síntese de
laboratório usam essa definição; o build simples preserva a interface original
`clk`/`rst`.

Mudanças arquiteturais futuras exigem ADR em `docs/decisions/`.
