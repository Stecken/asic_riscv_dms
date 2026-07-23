# Fonte RTL oficial e toolchain de laboratório

## Contexto

O export original misturava uma versão monolítica compilável, uma árvore modular
quebrada, tops vazios, logs e artefatos de uma ferramenta cloud.

## Decisão

`rtl/` e `rtl/files.f` são a única fonte oficial; `riscv_top` é o top. O export
fica em `legacy/`, excluído dos comandos normais e validado apenas pelo alvo
separado `test-legacy`. Ubuntu 24.04 com
Icarus, Verilator, Yosys e Graphviz define a baseline reproduzível.

## Alternativas consideradas

- Manter `hdl.v`: rejeitado por concorrer com módulos e dificultar revisão.
- Regenerar tudo em SystemVerilog: rejeitado por não ser necessário.
- Apagar o export: rejeitado para preservar proveniência e divergências.

## Consequências

Toda fonte é explícita e verificável; arquivos antigos continuam consultáveis,
mas não podem entrar acidentalmente no build. O assembler mínimo evita uma
toolchain RISC-V pesada na fase inicial.

## Impacto nos testes

CI, Codespaces e desenvolvimento local chamam `make ci`. Programas `.hex` são
checados contra Assembly antes da simulação.

## Impacto na síntese

Yosys lê somente o manifesto e sintetiza `riscv_top` com taps `RISCV_DEBUG` para
manter observabilidade do top originalmente fechado.
