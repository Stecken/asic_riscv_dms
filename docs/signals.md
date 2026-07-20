# Sinais para debug e waveforms

`make wave TEST=core_basic` cria `waves/core_basic.vcd`. Os taps abaixo existem
quando `RISCV_DEBUG` está definido e aparecem no escopo `tb_core`.

| Sinal | Interpretação |
| --- | --- |
| `clk`, `rst` | Clock de borda positiva e reset assíncrono ativo alto. |
| `debug_pc` | Próximo endereço de fetch/corrente da CPU. |
| `debug_old_pc` | Endereço da instrução retida no IR. |
| `debug_instruction` | Instruction Register. |
| `debug_state` | Estado 0..11 da FSM; tabela em `architecture.md`. |
| `debug_opcode`, `debug_funct3`, `debug_funct7_5` | Campos de decode. |
| `debug_rs1`, `debug_rs2`, `debug_rd` | Endereços dos registradores. |
| `debug_operand_a`, `debug_operand_b` | Valores capturados das portas de leitura. |
| `debug_immediate` | Imediato já estendido para 32 bits. |
| `debug_alu_a`, `debug_alu_b` | Entradas selecionadas da ALU. |
| `debug_alu_control` | ADD=0, SUB=1, AND=2, OR=3, XOR=4, SLL=5, SRL=6, SRA=7, SLT=8, SLTU=9. |
| `debug_alu_result`, `debug_zero` | Resultado combinacional e flag zero. |
| `debug_alu_out` | Resultado da ALU retido entre ciclos. |
| `debug_reg_write`, `debug_writeback` | Pulso e dado de writeback; combine com `debug_rd`. |
| `debug_mem_write` | Pulso de escrita da memória. |
| `debug_mem_address` | PC no fetch ou endereço efetivo no acesso de dados. |
| `debug_mem_read_data`, `debug_mem_write_data` | Dados de leitura/escrita. |
| `debug_mdr` | Memory Data Register. |
| `debug_pc_src`, `debug_alu_src_a`, `debug_alu_src_b`, `debug_result_src` | Seletores dos multiplexadores. |

## Abrindo no Codespaces

1. Execute `make wave TEST=core_basic`.
2. Abra `waves/core_basic.vcd` no Explorer.
3. Selecione Surfer quando o VS Code perguntar pelo editor.
4. No Surfer, use **File > Run command file** e escolha
   `tb/core/core_basic.sucl` para adicionar os sinais principais.

Também é possível executar `make open-wave`. Se a associação automática falhar,
use **Open With > Surfer** e confirme que não há outra extensão disputando VCD.

O VCD foi gerado e sua estrutura/sinais foram verificados. A extensão Surfer foi
configurada pelo identificador oficial e funciona como editor WASM de VCD, mas
a UI hospedada do Codespaces não foi iniciada nesta validação local. Como
fallback, baixe o VCD e use Surfer nativo ou GTKWave em um desktop Linux.
