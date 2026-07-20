# RISC-V HDL Laboratory

Laboratório colaborativo para um processador RISC-V multiciclo de 32 bits em
Verilog. A árvore oficial de RTL é `rtl/`, o top é `riscv_top` e os comandos do
`Makefile` são a interface única para desenvolvimento local, GitHub Codespaces
e GitHub Actions.

O projeto implementa um subconjunto de RV32I; ele **não** declara conformidade
RV32I completa. Consulte [docs/isa-status.md](docs/isa-status.md) antes de usar
uma instrução.

## Início rápido

No Codespaces, o ambiente já é preparado automaticamente. Em um Linux local,
instale as ferramentas listadas em [docs/development.md](docs/development.md).

```bash
make setup-check
make test
make wave
make synth
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
- `tb/unit/`: testes unitários self-checking em Verilog/SystemVerilog.
- `tb/core/`: teste integrado e configuração inicial de sinais do Surfer.
- `tb/programs/`: Assembly, `.hex` reproduzível e resultados esperados.
- `scripts/`: validação de fontes, assembler mínimo, síntese e esquemas.
- `docs/`: auditoria, arquitetura, verificação, sinais, síntese e ISA.
- `legacy/original-export/`: export original preservado; nunca entra no build.
- `build/`, `reports/`, `waves/`: artefatos locais descartáveis e ignorados.

## Simulação e testes

```bash
make lint
make build
make test-unit
make test-core TEST=core_basic
make test
```

Os testes retornam código diferente de zero por `$fatal` quando uma verificação
falha. O teste integrado carrega `tb/programs/core_basic.hex` por parâmetro,
observa a interface condicional `RISCV_DEBUG` e mantém um modelo dos writes do
banco de registradores; ele não acessa arrays internos do DUT por hierarquia.

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
abrir, carregue `tb/core/core_basic.sucl` no menu de command files para adicionar
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

Use **Terminal > Run Task** para executar lint, build, todos os testes, teste do
core, waveform, abertura do waveform, síntese, esquema ou limpeza. As tarefas
chamam exatamente os mesmos alvos usados no terminal e no CI.

## Colaboração

- Uma tarefa por issue e uma branch curta por tarefa.
- Pull requests pequenos, com issue vinculada e revisão obrigatória.
- Execute `make ci` antes de enviar.
- Inclua teste antes de corrigir comportamento funcional.
- Não altere microarquitetura sem um registro em `docs/decisions/`.
- Não versione `build/`, `reports/`, `waves/`, VCDs, executáveis ou logs locais.
- Não edite netlists, `.hex` gerado ou export legado como se fossem RTL oficial.

Consulte [CONTRIBUTING.md](CONTRIBUTING.md) e a auditoria inicial em
[docs/initial-audit.md](docs/initial-audit.md). Os comandos e resultados da
validação estão em [docs/final-validation.md](docs/final-validation.md).
