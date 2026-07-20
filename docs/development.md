# Ambiente de desenvolvimento

## Ambiente reproduzível

O devcontainer e o GitHub Actions usam Ubuntu 24.04. A imagem validada em
2026-07-19 forneceu:

| Ferramenta | Versão validada |
| --- | --- |
| Icarus Verilog / VVP | 12.0 |
| Verilator | 5.020 |
| Yosys | 0.33 |
| Graphviz | 2.43.0 |
| Python | 3.12.3 |
| Make | 4.3 |

Atualizações de patch do repositório Ubuntu são permitidas; mudanças da versão
principal devem passar por `make ci` e atualizar esta tabela. O Dockerfile foi
construído localmente, mas uma criação hospedada do Codespace ainda depende da
disponibilidade do registry e do marketplace de extensões.

## Codespaces

`.devcontainer/Dockerfile` instala as ferramentas como root durante o build.
Depois, o usuário `vscode` executa todos os comandos sem acesso privilegiado.
`.devcontainer/scripts/post-create.sh` roda checks, build e testes unitários.

O Surfer é instalado como extensão do VS Code (`surfer-project.surfer`), solução
compatível com o browser do Codespaces e sem servidor local extra. Não há
GTKWave no container porque uma GUI X11 não acrescentaria um fluxo funcional no
navegador.

Verible, cocotb/pytest, GNU RISC-V toolchain e riscv-formal não foram instalados
nesta baseline porque ainda não participam de nenhum alvo. Eles devem entrar em
uma fase posterior junto com testes reais que justifiquem o custo e fixem suas
versões.

## Comandos

```bash
make help
make setup-check
make lint
make build
make test-unit
make test-core
make wave TEST=core_basic
make synth
make schematic MODULE=alu
make clean
make ci
```

`make setup-check` falha se uma ferramenta obrigatória ou o módulo pip estiver
ausente. `scripts/check_sources.py` também garante que todos os `rtl/*.v` estão
no manifesto, que cada arquivo contém um módulo de mesmo nome e que não há
duplicatas.

## Arquivos ignorados

O `.gitignore` raiz cobre outputs de simulação/síntese, waveforms, executáveis
VVP/objetos, caches Python, workdirs comuns de EDA, estado de editor e arquivos
`.env`. Os `.hex` em `tb/programs/` são deliberadamente versionados porque são
entradas reproduzíveis da simulação. O diretório `legacy/` é somente histórico.
O `.gitattributes` fixa LF para fontes ativas e preserva os bytes/line endings do
export original sem produzir diffs gigantes de conteúdo arquivado.
