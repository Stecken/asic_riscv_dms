# Auditoria inicial do export HDL

Data da inspeção: 2026-07-19. Escopo original:
`design2.0-2026.06.21/design/`, preservado sem edição em
`legacy/original-export/design2.0-2026.06.21/design/` após a auditoria.

Atualização de 2026-07-22: por solicitação explícita, a linha legacy passou a
incorporar IMEM/DMEM separadas tanto em `hdl.v` quanto na árvore modular. O Git
preserva o snapshot original anterior a essa integração.

## Resumo executivo

A árvore modular original não compilava: `rtl/memory.v` era uma cópia byte a
byte de `rtl/datapath.v`, portanto declarava um segundo `datapath` e não havia
qualquer módulo `memory`. O arquivo monolítico `hdl.v` continha uma versão mais
coerente e compilável, inclusive o módulo de memória e o seletor `addr_src`, mas
divergia da árvore modular em caminhos de memória, writeback de JAL e decode.
Nenhum testbench era self-checking.

## 1. Módulos encontrados

Na árvore modular:

| Arquivo | Declaração | Observação |
| --- | --- | --- |
| `rtl/alu.v` | `alu` | Coerente com o monolítico. |
| `rtl/register_file.v` | `register_file` | Coerente com o monolítico. |
| `rtl/memory.v` | `datapath` | Nome incompatível; cópia de `datapath.v`. |
| `rtl/datapath.v` | `datapath` | Duplicado pela falsa memória. |
| `rtl/control.v` | `control` | Mais comentários e alguns decodes além do monolítico. |
| `rtl/riscv_top.v` | `riscv_top` | Instancia datapath e controle, mas sem `addr_src`. |
| `rtl/top.v` | `top` | Módulo gerado sem portas nem instâncias. |

Em `hdl.v`: `alu`, `register_file`, `memory`, `datapath`, `control`,
`riscv_top` e um wrapper `top(clk, rst)`.

## 2. Duplicados, ausentes e incompatíveis

- `datapath` aparecia duas vezes na lista modular (`datapath.v` e `memory.v`).
- `memory` estava ausente da árvore modular.
- O nome do módulo em `memory.v` não correspondia ao arquivo.
- `top.v` e `simulate.v` tinham conteúdo idêntico gerado pelo ChipInventor e
  não representavam a CPU.
- Compilar `hdl.v` junto com `rtl/*.v` duplicaria praticamente todos os módulos.

## 3. Tops existentes

- `riscv_top(clk, rst)` era o top real da CPU.
- `hdl.v` acrescentava `top(clk, rst)` envolvendo `riscv_top`.
- `rtl/top.v` e `simulate.v` declaravam um `top()` vazio.
- `config.json` definia `DESIGN_NAME=top`, mas apontava
  `VERILOG_FILES=dir::src/*.v`; a pasta `src/` não existia.

O top oficial normalizado é somente `riscv_top`, listado em `rtl/files.f`.

## 4. Testbenches e dependências hierárquicas

Foram encontrados:

- `testbench/tb_riscv.v`: instancia `riscv_top` e escreve diretamente em
  `dut.dp.mem.mem[]`; lê `dut.dp.rf.regs[]`, `dut.dp.pc` e `dut.ctrl.state`.
- `testbench/testbench.v`: instancia o wrapper `top` monolítico e depende de
  `dut.riscv.dp.mem.mem[]` e `dut.riscv.dp.rf.regs[]`.
- `testbench/testCaravel.v`: texto corrompido, sem sintaxe Verilog válida.

Os dois testbenches executáveis usavam apenas `$display` e `$finish`. Valores
incorretos não alterariam o exit status, logo seus logs de “esperado” não eram
prova automatizada de sucesso.

## 5. Arquivos gerados, binários e temporários

- Gerados: `rtl/top.v`, `simulate.v`, `hdl.v`, `config.json`,
  `convertion/diagram.json`, logs de conversão/síntese e `fpga_exec.sh` com
  caminho absoluto `/chipinventor/...`.
- Artefatos: `testbench/testbench.o` é um script executável do VVP (43 KiB),
  `testbench.vcd` tem 31 KiB e `testbench_dec.vcd` está vazio.
- Logs locais: `simulation.log`, `error.log`, `logSdf.log` e dois logs de
  síntese do serviço anterior.
- O `.gitignore` original tinha zero bytes.

O export inteiro foi arquivado para proveniência. Binários e waveforms dentro
dele permanecem no disco, mas o `.gitignore` raiz impede que sejam adicionados;
os pequenos logs históricos têm exceção deliberada para poderem ser revisados.

## 6. Compilação, simulação e lint originais

Os comandos foram executados no devcontainer Ubuntu 24.04 com Icarus 12.0 e
Verilator 5.020.

### Árvore modular

```text
iverilog ... rtl/*.v testbench/tb_riscv.v
rtl/memory.v:1: error: 'datapath' has already been declared in this scope.
```

Exit status diferente de zero. O Verilator também encontrou `MODDUP`,
`DECLFILENAME`, módulos sem timescale e 14 erros de referências hierárquicas à
memória ausente.

### Monolítico

`hdl.v + tb_riscv.v` compilou e simulou com exit status zero, produzindo os
valores impressos x1=5, x2=3, x3=8 e x4=8. Isso não era self-checking. O Icarus
também avisou que os módulos de RTL não tinham unidade/precisão de tempo.

Os logs do serviço externo afirmavam sucesso de layout, mas não eram
reproduzíveis pelo checkout: o `config.json` apontava a pasta inexistente e os
scripts dependiam de caminhos absolutos do serviço.

## 7. Divergências e falhas funcionais confirmadas

- O monolítico tinha `addr_src` e usava `alu_out` para LW/SW; a árvore modular
  sempre endereçava memória com `pc`, quebrando acesso de dados.
- O monolítico tinha a memória correta; a modular não tinha memória.
- O decode modular incluía SLTU que não aparecia no decode monolítico.
- O writeback de JAL divergia: o monolítico selecionava o PC e a versão modular
  selecionava o resultado combinacional da ALU.
- Branch e JAL calculavam alvo a partir do PC já incrementado, deslocando o alvo
  por 4 bytes. O testbench antigo incorporava esse comportamento nos saltos.
- LUI passava pelo caminho `PC + imm`, em vez de escrever apenas o imediato U.
- O top fechado só tinha entradas; uma síntese otimizante podia remover toda a
  lógica por falta de saídas observáveis.

## 8. Decisão de normalização

A árvore modular foi escolhida como base legível. Foram portados do monolítico
somente `memory` e `addr_src`, adicionados `old_pc` e writeback explícito de
`PC+4`, corrigido LUI e completado o decode das operações que a ALU já possuía.
A microarquitetura multiciclo e a memória unificada foram mantidas.

Cada correção observável é coberta por teste: memória/`addr_src` por unit e core,
PC relativo e JAL pelo programa integrado, LUI pelo core, shifts/SLT/SLTU pela
ALU e pelo core. A ISA e os gaps restantes estão em `docs/isa-status.md`.
