# ChipInventor readiness

## Escopo e limite da conclusão

O repositório possui uma ponte de empacotamento e verificação local para facilitar a transferência ao ChipInventor. Ela organiza fontes, firmware e testbench, mas **não demonstra compatibilidade com a plataforma**. Nenhuma execução real no ChipInventor foi registrada nesta preparação.

As mudanças desta frente são exclusivamente de infraestrutura, organização, documentação e portabilidade do testbench existente. Elas não acrescentam instruções, extensões de ISA, unidades funcionais, estados de controle nem decisões microarquiteturais.

## Pronto no repositório

- Fonte oficial explícita e ordenada em `rtl/files.f`, com top lógico definido centralmente como `riscv_top`.
- Metadados canônicos em `config/project.mk`: top, testbench, firmware, manifesto, perfil de linguagem e destinos.
- Testbench integrado existente em `tb/portable/tb_core.v`, self-checking, com timeout, `$fatal`, firmware relativo e VCD sempre habilitado.
- Testes unitários existentes agrupados em `tb/portable/unit/`; nenhum runtime Python, cocotb, DPI ou biblioteca do Verilator é necessário para executá-los.
- Firmware e apoio separados em `tb/support/`.
- Diretório determinístico `dist/chipinventor/`, produzido por `make chipinventor-package`, com fontes explícitas, hashes e procedência.
- Checagem isolada local por `make chipinventor-check`, incluindo compilação, simulação, falha propagada, firmware e VCD.
- Relatório estático em `reports/chipinventor-portability.md`.
- Formulários manuais versionáveis em `validation/chipinventor/`, sem resultados pré-preenchidos.

## Estrutura do pacote local

```text
dist/chipinventor/
├── rtl/
├── tb/
├── firmware/
├── config.json
├── sources.txt
├── MANIFEST.txt
└── VERSION.txt
```

`sources.txt` é a ordem completa de compilação. `MANIFEST.txt` lista todos os outros arquivos do pacote com caminho relativo, SHA-256, classe e origem. `VERSION.txt` registra commit, branch, data do commit, estado clean/dirty, top, testbench e versão do formato. A data do commit, em vez do relógio da máquina, mantém a geração reproduzível para a mesma árvore e o mesmo estado Git.

`config.json` é um formato interno deste repositório. Ele não deve ser confundido com um schema oficial da plataforma.

## Pendente no Block Guide

Os seguintes itens dependem da documentação oficial e continuam `PENDENTE_DE_CONFIRMACAO`:

- versão aplicável do Block Guide e simulador usado pela plataforma;
- extensões e versão de Verilog/SystemVerilog aceitas;
- formato oficial de configuração e forma de declarar top/testbench;
- ordem/forma de envio das fontes e regras para nomes/diretórios;
- suporte e localização de `$readmemh`, VCD, plusargs, `$error` e `$fatal`;
- comportamento de `initial` em RTL e inicialização de memória/registradores;
- macros de compilação e forma de habilitar `RISCV_DEBUG`;
- limites de tamanho, tempo de simulação, waveform e firmware;
- necessidade de wrapper ou interface de bloco diferente do top lógico atual.

## Pendente no Submission Guide

- versão/revisão aplicável do Submission Guide;
- formato de upload (diretório, arquivo compactado ou formulário);
- campos obrigatórios, licença, autoria, identificação e convenção de versão;
- limites de arquivo/pacote e extensões permitidas;
- critérios oficiais de aprovação e evidências exigidas;
- procedimento de reenvio, atualização, tag ou publicação;
- qualquer requisito físico, de pinout ou de OpenLane associado à submissão.

## Pontos de portabilidade a confirmar

- O perfil local é `systemverilog-2012`; tarefas `$fatal`/`$error` e `$value$plusargs` podem variar entre simuladores.
- O testbench usa `$dumpfile`/`$dumpvars`; a plataforma pode adotar outro fluxo de waveform.
- `memory.v` usa `$readmemh` com caminho fornecido por parâmetro.
- `memory.v` e `register_file.v` contêm blocos `initial`; a semântica para síntese precisa ser confirmada no fluxo alvo.
- `RISCV_DEBUG` altera a interface observável durante simulação e é fornecido pela linha de compilação.
- Há pragmas em comentário específicos do Verilator; normalmente são ignorados por outros simuladores, mas o comportamento deve ser confirmado.

O inventário detalhado e classificado é gerado por:

```bash
make chipinventor-portability
```

O scanner sinaliza caminhos absolutos, includes, DPI, classes, interfaces, packages, dependências cocotb/Verilator, macros, inicialização, hierarquia frágil e arquivos fora do manifesto. Ele não reescreve o RTL.

## Fluxo local diário

```bash
make lint
make build
make test
make chipinventor-package
make chipinventor-check
```

O último comando copia o pacote para um diretório temporário, compila a lista explícita, roda o testbench, verifica a falha/passagem, o firmware, o VCD, o JSON, os hashes e a ausência de referências externas. Um `PASS` aqui significa somente que a infraestrutura local do pacote é autoconsistente.

## Teste manual obrigatório no ChipInventor

1. Consulte as revisões atuais do Block Guide e do Submission Guide.
2. Gere e confira o pacote local; adapte somente os campos exigidos pela documentação oficial.
3. Faça o upload sem incluir `build/`, `waves/`, logs ou arquivos temporários.
4. Configure o top e o testbench conforme o guia, sem inferir que `config.json` seja reconhecido.
5. Compile e execute o testbench na plataforma.
6. Confirme que um teste positivo termina, que uma falha intencional é reportada como falha real, que o firmware é carregado e que o waveform pode ser inspecionado.
7. Crie o formulário vazio com `make chipinventor-validation-record DATE=YYYY-MM-DD` e preencha apenas com evidências observadas.
8. Opcionalmente, após revisão humana, crie manualmente a tag `chipinventor-ok-YYYY-MM-DD`.

## Responsabilidades

- **Infraestrutura:** estrutura de diretórios, manifesto, pacote, hashes, scripts, CI, documentação, formulários e checagens locais.
- **Design HDL:** comportamento do processador, ISA, microarquitetura, temporização lógica e interfaces funcionais.
- **Validação manual:** compatibilidade real do simulador/plataforma, resultados observados, guias oficiais e aceite da submissão.
- **Implementação física:** PDK, clock, áreas, densidade, pinout, alimentação, bibliotecas e constraints; todos fora desta preparação.

Essas responsabilidades não são intercambiáveis: uma checagem de infraestrutura não aprova o design nem substitui execução manual na plataforma.
