# Síntese e esquemas

## Síntese

`make synth` executa `scripts/run_synthesis.ys` com somente `rtl/files.f` e top
`riscv_top`. O fluxo faz `hierarchy -check`, `proc`, otimizações, processamento
de FSM/memória, `check`, netlist, JSON e `stat`.

A definição `RISCV_DEBUG` é ativada para expor comportamento observável no top.
Isso é necessário porque a interface original tinha apenas entradas e todo o
circuito fechado era removido corretamente pelo Yosys. Os taps são passivos e
mantêm a mesma lógica funcional.

Saídas:

- `build/synth/riscv_top_netlist.v`;
- `build/synth/riscv_top.json`;
- `build/logs/yosys-synth.log`;
- `reports/synthesis-stat.txt`;
- `reports/synthesis-warnings.txt`.

Na validação de 2026-07-19 com Yosys 0.33, `check` encontrou zero problemas, o
relatório teve 1.404 células na hierarquia e nenhum warning. Esse número é uma
referência funcional, não uma meta de área: `memory` transforma os arrays em
células genéricas e não executa mapeamento para uma tecnologia ASIC/FPGA.

## Esquemas

```bash
make schematic MODULE=alu
make schematic MODULE=control
make schematic MODULE=riscv_top
```

Cada comando faz o módulo escolhido ser o top temporário e gera `.dot` e `.svg`
em `build/schematic/`. O esquema de `riscv_top` preserva hierarquia e mostra
datapath, controle e taps; use os esquemas individuais para lógica detalhada.
Os SVGs de `alu` e `riscv_top` foram renderizados e inspecionados na validação.

Não use esses netlists como fonte. Mapeamento de células, constraints de clock,
timing, PPA e fluxo físico estão fora desta baseline e exigem decisão explícita
de tecnologia.
