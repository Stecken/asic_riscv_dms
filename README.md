# RISC-V HDL Laboratory

Laboratório colaborativo para um processador RISC-V multiciclo de 32 bits em
Verilog. A árvore oficial de RTL é `rtl/`, o top é `riscv_top` e os comandos do
`Makefile` são a interface única para desenvolvimento local, GitHub Codespaces
e GitHub Actions. Top, testbench, firmware, manifesto e perfil de linguagem são
centralizados em `config/project.mk`.

O projeto implementa um subconjunto de RV32I; ele **não** declara conformidade
RV32I completa. Consulte [docs/isa-status.md](docs/isa-status.md) antes de usar
uma instrução.

## Início rápido

No Codespaces, o ambiente já é preparado automaticamente. Em um Linux local,
instale as ferramentas listadas em [docs/development.md](docs/development.md).

```bash
make setup-check
make test
make test-legacy
make wave
make synth
make chipinventor-package
make chipinventor-check
```

Use `make help` para listar todos os alvos.

## Abrindo no GitHub Codespaces

1. No GitHub, abra a página do repositório.
2. Selecione **Code > Codespaces > Create codespace on main** (ou a branch da
   tarefa).
3. Aguarde o terminal mostrar `Codespace ready`.
4. Execute `make test` ou use **Terminal > Run Task** no VS Code.

O devcontainer usa Ubuntu 24.04 e instala Icarus Verilog, Verilator, Yosys,
Graphviz, Make, Git, Python 3 e pip. O `postCreateCommand` executa
`make setup-check`, compila o top e roda os testes unitários sem privilégios.

## Organização

- `rtl/`: única fonte oficial e o manifesto determinístico `rtl/files.f`.
- `tb/portable/`: testes unitários e integrado self-checking, sem runtime externo.
- `tb/advanced/`: área explícita para futuros testes fora do perfil portátil.
- `tb/support/`: Assembly, `.hex`, resultados esperados e sinais do Surfer.
- `config/`: metadados canônicos e template do pacote local.
- `scripts/`: validação de fontes, assembler mínimo, síntese e esquemas.
- `validation/chipinventor/`: formulários manuais sem resultados presumidos.
- `openlane/`: placeholders físicos, sem decisões nem execução de P&R.
- `docs/`: auditoria, arquitetura, verificação, sinais, síntese, ISA e readiness.
- `legacy/original-export/`: linha legacy, fora do build oficial; possui teste
  separado para as formas monolítica e modular.
- `build/`, `dist/`, `waves/`: artefatos locais descartáveis e ignorados.

## Simulação e testes

```bash
make lint
make build
make test-unit
make test-core TEST=core_basic
make test
make test-legacy
```

Os testes retornam código diferente de zero por `$fatal` quando uma verificação
falha. O teste integrado carrega `tb/support/firmware/core_basic.hex` por parâmetro,
observa a interface condicional `RISCV_DEBUG` e mantém um modelo dos writes do
banco de registradores; ele não acessa arrays internos do DUT por hierarquia.
Ele também possui timeout e sempre gera um VCD, inclusive quando executado no
pacote isolado.

`make test-legacy` não mistura o export antigo ao manifesto oficial: ele compila
e simula separadamente `hdl.v`, o wrapper legado e `legacy/.../rtl/*.v`,
verificando registradores, o dado gravado na DMEM e a preservação da instrução
correspondente na IMEM.

Para alterar um programa, edite o `.S`, execute `make programs` e confira
`make programs-check`. O assembler incluído cobre somente o subconjunto
documentado e não substitui a GNU RISC-V toolchain.

## Waveforms

```bash
make wave TEST=core_basic
make open-wave TEST=core_basic
```

O primeiro comando imprime o caminho exato, normalmente
`waves/core_basic.vcd`. No Codespaces, a extensão oficial
[Surfer](https://marketplace.visualstudio.com/items?itemName=surfer-project.surfer)
é instalada e abre `.vcd` dentro do VS Code no navegador. Se necessário, clique
com o botão direito no arquivo e selecione **Open With > Surfer**. Depois de
abrir, carregue `tb/support/core_basic.sucl` no menu de command files para adicionar
o conjunto inicial de sinais.

A geração e a validade do VCD foram testadas no devcontainer. A interação da
extensão na interface web do Codespaces não pode ser automatizada neste
ambiente; [docs/signals.md](docs/signals.md) registra esse limite e o fallback.

## Síntese e esquemas

```bash
make synth
make schematic MODULE=alu
make schematic MODULE=control
make schematic MODULE=riscv_top
```

Os resultados ficam em `build/synth/`, `build/schematic/` e `reports/`. A
síntese ativa `RISCV_DEBUG` para manter saídas observáveis; sem isso, o antigo
top fechado (`clk`/`rst` apenas) seria corretamente removido pelo otimizador.
Veja [docs/synthesis.md](docs/synthesis.md).

## Tarefas do VS Code

Use **Terminal > Run Task** para executar `HDL: Lint`, `HDL: Build`, `HDL: Test`
e `HDL: Wave`. Também existem tarefas para gerar e checar o pacote ChipInventor,
mostrar o status da última validação manual, criar um formulário semanal e
listar a prontidão OpenLane. Elas chamam os mesmos alvos usados no terminal e,
quando aplicável, no CI.

## Ponte para ChipInventor

O fluxo prepara uma entrega autocontida, mas não afirma que o ChipInventor a
aceita. O formato `config.json` é interno ao repositório e deve ser comparado ao
Block Guide e ao Submission Guide oficiais antes do upload.

Fluxo diário local:

```bash
make lint
make build
make test
make chipinventor-package
make chipinventor-check
```

O pacote determinístico é criado em `dist/chipinventor/` com `rtl/`, `tb/`,
`firmware/`, `config.json`, `sources.txt`, `MANIFEST.txt` e `VERSION.txt`.
`make chipinventor-check` o copia para uma área temporária, recompila, simula e
verifica referências, módulos, firmware, JSON, hashes e waveform. Esse resultado
é uma checagem de infraestrutura local, não uma validação da plataforma.

Fluxo semanal/manual:

```bash
make chipinventor-status
make chipinventor-package
make chipinventor-check
make chipinventor-validation-record DATE=YYYY-MM-DD
```

O último comando cria somente um formulário vazio. Depois de uma execução real,
um responsável humano registra evidências e, opcionalmente, cria manualmente a
tag `chipinventor-ok-YYYY-MM-DD`. Scripts e CI não criam tags, releases nem
resultados de validação. Consulte
[docs/chipinventor-readiness.md](docs/chipinventor-readiness.md) e
[docs/block-guide-checklist.md](docs/block-guide-checklist.md) antes do teste.

Papéis separados:

- infraestrutura mantém empacotamento, CI, hashes, portabilidade e documentação;
- design HDL responde pelo comportamento, ISA, microarquitetura e interfaces;
- validação manual confirma o comportamento real no ChipInventor e registra evidências;
- implementação física define PDK, clock, área, pinout, alimentação e constraints.

`make openlane-readiness` apenas lista os parâmetros físicos ainda
`PENDENTE_DE_CONFIRMACAO`; ele não executa OpenLane, P&R ou GDS.

## Colaboração

- Uma tarefa por issue e uma branch curta por tarefa.
- Pull requests pequenos, com issue vinculada e revisão obrigatória.
- Execute `make ci` antes de enviar.
- Inclua teste antes de corrigir comportamento funcional.
- Não altere microarquitetura sem um registro em `docs/decisions/`.
- Não versione `build/`, `dist/`, `waves/`, VCDs, executáveis ou logs locais.
- Não trate `make chipinventor-check` ou CI verde como validação no ChipInventor.
- Não edite netlists, `.hex` gerado ou export legado como se fossem RTL oficial.

Consulte [CONTRIBUTING.md](CONTRIBUTING.md) e a auditoria inicial em
[docs/initial-audit.md](docs/initial-audit.md). Os comandos e resultados da
validação estão em [docs/final-validation.md](docs/final-validation.md).
