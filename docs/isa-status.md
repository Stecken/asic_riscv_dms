# Estado da ISA

Esta matriz descreve o RTL atual, não uma declaração de conformidade RV32I. “UT”
inclui ALU/controle/imediato; “core” significa `core_basic` self-checking.

| Instrução | Decode | Execute | Teste unitário | Teste integrado | Status |
| --- | --- | --- | --- | --- | --- |
| ADD | sim | sim | sim | sim | implementada |
| SUB | sim | sim | sim | sim | implementada |
| AND | sim | sim | sim | sim | implementada |
| OR | sim | sim | sim | sim | implementada |
| XOR | sim | sim | sim | sim | implementada |
| SLL | sim | sim | sim | sim | implementada |
| SRL | sim | sim | sim | sim | implementada |
| SRA | sim | sim | sim | sim | implementada |
| SLT | sim | sim | sim | sim | implementada |
| SLTU | sim | sim | sim | sim | implementada |
| ADDI | sim | sim | ALU/imediato | sim | implementada |
| ANDI, ORI, XORI | sim | sim | ALU/imediato | não | implementada, cobertura core pendente |
| SLLI, SRLI, SRAI | sim | sim | ALU; decode SRA | não | implementada, cobertura core pendente |
| SLTI, SLTIU | sim | sim | ALU/imediato | não | implementada, cobertura core pendente |
| LUI | sim | sim | imediato | sim | implementada |
| AUIPC | sim | sim | imediato | não | parcial até teste integrado |
| LW | sim | palavra | memória/controle | sim | implementada para palavra alinhada |
| SW | sim | palavra | memória | sim | implementada para palavra alinhada |
| BEQ | sim | sim | comparador/imediato | tomado | implementada |
| BNE | sim | sim | comparador/imediato | não tomado | implementada |
| BLT, BGE | sim | signed | comparador | sim | implementadas |
| BLTU, BGEU | sim | unsigned | comparador | sim | implementadas |
| JAL | sim | sim | imediato | sim | implementada |
| JALR | não | não | não | não | não implementada |
| LB, LBU, LH, LHU | não | não | não | não | não implementada |
| SB, SH | não | não | não | não | não implementada |
| FENCE, ECALL, EBREAK | não | não | não | não | não implementada |
| CSR/Zicsr | não | não | não | não | não implementada |
| MUL/DIV (extensão M) | não | não | não | não | não implementada |

## Comportamentos importantes

- ADD/SUB e SLT/SLTU têm decodes distintos e casos negativos testados.
- SRL/SRA usam `funct7[5]` para distinguir shift lógico e aritmético.
- `branch_comp` decide os seis branches; `funct3` inválido nunca toma o salto.
- JAL usa `old_pc + immediate` como alvo e grava `old_pc + 4` como link.
- LUI zera a entrada A da ALU; AUIPC usa `old_pc`.
- PC é alinhado por construção dos imediatos B/J, mas não há trap de instrução
  desalinhada.
- x0 retorna zero e escrita em x0 é descartada.
- Loads/stores aceitam somente semântica de palavra; não há trap de desalinhamento
  nem verificação de faixa. Endereços fora dos 1 KiB aliasam pelos bits `[9:2]`.
