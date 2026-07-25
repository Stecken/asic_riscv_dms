# Fluxo da CPU RISC-V

Este documento é o mapa de leitura do projeto. Ele mostra a hierarquia dos
módulos, os sinais que ligam controle e datapath e o que acontece em cada
estado da CPU multiciclo.

## 1. Visão geral

```mermaid
flowchart LR
    TOP[riscv_top]
    CTRL[control\nFSM multiciclo]
    DP[datapath]
    TOP --> CTRL
    TOP --> DP
    CTRL -->|sinais de controle| DP
    DP -->|opcode, funct3, funct7_5| CTRL
    DP -->|branch_taken| CTRL
```

`riscv_top` não executa operações diretamente. Ele apenas conecta:

- `control`: decide em qual estado a CPU está e gera os sinais de controle;
- `datapath`: contém PC, registradores temporários, ALU, memórias, decoders e
  os caminhos de dados.

A fonte oficial é a lista [`rtl/files.f`](../rtl/files.f).
O export em `legacy/` é preservado para testes de compatibilidade e não faz
parte do build oficial.

## 2. Hierarquia e comunicação entre módulos

```mermaid
flowchart TB
    TOP[riscv_top]
    CTRL[control]
    DP[datapath]

    TOP --> CTRL
    TOP --> DP
    CTRL -->|pc_write, ir_write, reg_write\nmem_write, addr_src\npc_src, alu_src_a, alu_src_b\nresult_src, alu_ctrl| DP
    DP -->|opcode, funct3, funct7_5| CTRL
    DP -->|branch_taken| CTRL

    DP --> RF[register_file]
    RF -->|register_read_a/b| DP
    DP -->|writeback_data, reg_write, rd| RF

    DP --> IMM[immediate_gen]
    IMM -->|immediate| DP

    DP --> ALU[alu]
    ALU -->|alu_result| DP
    ALU -.->|zero / debug_zero| DP

    DP --> BC[branch_comp]
    BC -->|taken| DP

    DP --> IMEM[imem]
    IMEM -->|imem_rd| DP
    DP --> DMEM[dmem]
    DMEM -->|dmem_rd| DP
```

### Responsabilidade de cada módulo

| Módulo | Responsabilidade | Entradas principais | Saídas principais |
| --- | --- | --- | --- |
| `riscv_top` | Integra controle e datapath | `clk`, `rst` | Interface da CPU e debug opcional |
| `control` | FSM e sinais de controle | `opcode`, `funct3`, `funct7_5`, `branch_taken` | Escritas, seletores, operação da ALU |
| `datapath` | Transporte e retenção dos dados | Sinais da FSM | Campos da instrução, `branch_taken`, estado observável |
| `alu` | Operações aritméticas/lógicas | `a`, `b`, `alu_ctrl` | `result`, `zero` |
| `branch_comp` | Comparação das seis condições de branch | `operand_a`, `operand_b`, `funct3` | `taken` |
| `register_file` | 32 registradores de 32 bits | `rs1`, `rs2`, `rd`, writeback | Dois operandos lidos |
| `immediate_gen` | Decodificação e extensão de imediatos | `instruction` | Imediato de 32 bits |
| `imem` | Leitura combinacional de instruções | Endereço | Instrução |
| `dmem` | Leitura e escrita de dados | Clock, endereço, dado, `we` | Dado lido |

## 3. Datapath detalhado

```mermaid
flowchart LR
    PC[PC]
    OLD[old_pc]
    IR[IR]
    OA[operand_a]
    OB[operand_b]
    AO[ALUOut]
    MDR[MDR]

    PC -->|addr_src=0| ADDR[mem_address]
    AO -->|addr_src=1| ADDR
    ADDR --> IMEM[IMEM]
    ADDR --> DMEM[DMEM]

    IMEM --> FETCH{addr_src}
    DMEM --> FETCH
    FETCH -->|0: instrução| IR
    FETCH -->|1: dado| MDR

    IR --> DEC[opcode / funct3 / rs1 / rs2 / rd]
    DEC --> RF[register_file]
    RF --> OA
    RF --> OB

    IR --> IMM[immediate_gen]
    OLD --> AMUX{alu_src_a}
    OA --> AMUX
    AMUX --> ALUA[alu_a]
    OB --> BMUX{alu_src_b}
    IMM --> BMUX
    BMUX --> ALUB[alu_b]
    ALUA --> ALU[ALU]
    ALUB --> ALU
    ALU -->|alu_result| AO

    OA --> BC[branch_comp]
    OB --> BC
    DEC -->|funct3| BC
    BC -->|branch_taken| CONTROL[control]

    AO --> WB{result_src}
    MDR --> WB
    OLD --> LINK[old_pc + 4]
    LINK --> WB
    WB --> RF

    ALU --> NEXT{pc_src}
    AO --> NEXT
    NEXT --> PC
```

Os registradores temporários são atualizados na borda de subida do clock:

- `IR` recebe a instrução durante `IF`;
- `old_pc` recebe o PC da instrução que foi capturada;
- `operand_a` e `operand_b` recebem os valores lidos do banco;
- `ALUOut` recebe o resultado combinacional da ALU;
- `MDR` retém o dado retornado pela DMEM.

O reset é assíncrono e zera PC, `old_pc`, IR, MDR, operandos, `ALUOut` e o
estado da FSM. O banco de registradores e as memórias são inicializados para o
fluxo de laboratório, mas não possuem porta de reset.

## 4. Fluxo de uma instrução

```mermaid
sequenceDiagram
    participant C as control
    participant D as datapath
    participant M as IMEM/DMEM
    participant R as register_file
    participant A as ALU/branch_comp

    C->>D: IF: ir_write=1, pc_write=1
    D->>M: endereço = PC
    M-->>D: instrução
    D->>D: IR=instrução, old_pc=PC, PC=PC+4

    C->>D: ID: seleciona old_pc/imediato
    D->>R: rs1 e rs2
    R-->>D: operand_a e operand_b
    D->>A: calcula old_pc + imediato
    A-->>D: alvo retido em ALUOut

    alt Operação R/I
        C->>A: alu_ctrl e seletores
        A-->>D: resultado retido em ALUOut
        C->>R: WB_ALU: reg_write=1
    else Load
        C->>M: endereço efetivo em ALUOut
        M-->>D: dado em MDR
        C->>R: WB_MEM: reg_write=1
    else Store
        C->>M: mem_write=1, dado=operand_b
    else Branch
        D->>A: operand_a, operand_b, funct3
        A-->>C: branch_taken
        C->>D: pc_write=branch_taken
    else JAL
        C->>R: WB_J: rd=old_pc+4
        C->>D: PC=ALUOut
    end
```

A CPU não é pipeline. Uma instrução ocupa vários ciclos e a FSM avança pelos
estados abaixo:

| Estado | Código | Ação |
| --- | ---: | --- |
| `ST_IF` | 0 | Lê IMEM, captura IR e incrementa PC |
| `ST_ID` | 1 | Lê registradores e calcula imediato/alvo |
| `ST_EX_R` | 2 | Executa operação register-register |
| `ST_EX_I` | 3 | Executa operação com imediato |
| `ST_EX_MEM` | 4 | Calcula endereço efetivo |
| `ST_MEM_RD` | 5 | Seleciona DMEM para leitura |
| `ST_MEM_WR` | 6 | Escreve DMEM |
| `ST_WB_ALU` | 7 | Escreve `ALUOut` no banco |
| `ST_WB_MEM` | 8 | Escreve `MDR` no banco |
| `ST_EX_B` | 9 | Avalia branch e, se tomado, instala o alvo |
| `ST_EX_J` | 10 | Calcula/preserva alvo do `JAL` |
| `ST_WB_J` | 11 | Escreve link e instala o alvo do jump |

## 5. Fetch e separação IMEM/DMEM

`addr_src` escolhe o significado de `mem_address`:

```mermaid
flowchart LR
    PC[PC] --> MUX{addr_src}
    ALUOUT[ALUOut] --> MUX
    MUX -->|0: fetch| IMEM[IMEM read-only]
    MUX -->|1: load/store| DMEM[DMEM read/write]
    IMEM --> IR[IR]
    DMEM --> MDR[MDR]
    operand_b[operand_b] -->|mem_write & addr_src| DMEM
```

Cada memória tem 256 palavras de 32 bits. O índice usa `addr[9:2]`; os dois
bits menos significativos são ignorados. Não há trap de desalinhamento, faixa
de endereço ou acesso a byte/meia-palavra.

## 6. Branches

```mermaid
flowchart LR
    OA[operand_a] --> BC[branch_comp]
    OB[operand_b] --> BC
    F3[funct3] --> BC
    BC --> BT[branch_taken]
    BT --> CW[control.pc_write]
    TARGET[ALUOut = old_pc + immediate] --> PS[pc_src=01]
    PS --> PC[PC]
    CW --> PC
```

`branch_comp` é a decisão funcional do branch:

| `funct3` | Instrução | Comparação |
| --- | --- | --- |
| `000` | `BEQ` | `a == b` |
| `001` | `BNE` | `a != b` |
| `100` | `BLT` | `$signed(a) < $signed(b)` |
| `101` | `BGE` | `$signed(a) >= $signed(b)` |
| `110` | `BLTU` | `a < b` |
| `111` | `BGEU` | `a >= b` |

A flag `zero` ainda é produzida pela ALU para observação e debug. Ela não
decide mais o branch, porque só expressa se o resultado da operação atual da
ALU é zero e não distingue todas as comparações signed/unsigned.

## 7. Jumps e writeback

Para `JAL`:

```text
ID:       ALUOut = old_pc + immediate
WB_J:     rd      = old_pc + 4
          PC      = ALUOut
```

O projeto implementa `JAL`, mas ainda não implementa `JALR`. Portanto, existe
salto com link, mas não existe ainda o retorno padrão `JALR x0, 0(ra)` nem
preservação automática de uma pilha de retornos.

O writeback escolhe entre:

```text
result_src=00 -> ALUOut
result_src=01 -> MDR
result_src=10 -> old_pc + 4
```

Escritas em `x0` são descartadas pelo `register_file`.

## 8. Fluxo do mini firmware

O programa [`core_basic.S`](../tb/support/firmware/core_basic.S)
é montado pelo assembler mínimo em `core_basic.hex` e carregado na IMEM pelo
parâmetro `MEMORY_INIT_FILE`.

```mermaid
flowchart TD
    ASM[core_basic.S] -->|assemble_test_program.py| HEX[core_basic.hex]
    HEX -->|MEMORY_INIT_FILE| IMEM[IMEM]
    IMEM --> CPU[riscv_top]
    CPU -->|writes de debug| TB[tb_core]
    CPU -->|SW| DMEM[DMEM endereço 128]
    TB --> CHECK[assinatura de registradores\ne store esperado]
    CHECK --> PASS[PASS tb_core]
```

O testbench verifica aritmética, lógica, shifts, comparações, `SW/LW`, os seis
branches, `LUI` e `JAL`. O marcador `x31=1` encerra a espera do testbench; o
programa depois fica em um loop `jal x0, done`.

## 9. Como validar e inspecionar

Dentro do devcontainer ou de um Linux com as ferramentas instaladas:

```bash
make setup-check
make lint
make test
make wave TEST=core_basic
make schematic MODULE=riscv_top
make synth
```

Artefatos principais:

- `build/logs/`: logs dos testes e ferramentas;
- `build/sim/core_basic/test-core.vcd`: waveform do teste integrado;
- `build/schematic/riscv_top.svg`: esquema gerado por Yosys + Graphviz;
- `build/synth/`: netlist e JSON da síntese;
- `reports/`: estatísticas e relatórios estáticos.

Para acompanhar uma instrução na waveform, observe nesta ordem:

```text
debug_state
debug_pc / debug_old_pc
debug_instruction e campos de decode
debug_operand_a / debug_operand_b
debug_alu_a / debug_alu_b / debug_alu_result
debug_alu_out
debug_mem_address / debug_mem_write
debug_reg_write / debug_rd / debug_writeback
```

Os sinais de debug são taps de observação e não mudam o comportamento
funcional do processador.
