# Validação da baseline e atualização do fluxo

Última atualização: 2026-07-24 (America/Sao_Paulo).

## Validação atual

Esta seção registra a execução mais recente depois da integração de `branch_comp`,
dos seis branches e do firmware `core_basic` expandido. O Dockerfile do
devcontainer foi construído e os comandos foram executados dentro do container.

| Comando | Resultado atual |
| --- | --- |
| `make programs-check` | PASS |
| `make test` | PASS: 7 testes unitários + teste integrado |
| `make test-core TEST=core_basic` | PASS em 152 ciclos |
| `make schematic MODULE=riscv_top` | PASS; SVG e DOT gerados |

O teste integrado confirmou os registradores esperados e o `SW` de `8` para o
endereço `128`. Também foi produzido o waveform em
`build/sim/core_basic/test-core.vcd` e o diagrama em
`build/schematic/riscv_top.svg`.

O host Linux não tinha `iverilog`, `vvp`, Yosys ou Graphviz disponíveis
diretamente. A execução atual usou o `.devcontainer/Dockerfile`, que instala
essas ferramentas no container.

Os comandos de lint, síntese completa, pacote ChipInventor e `make ci` abaixo
continuam sendo a baseline histórica de 2026-07-19; devem ser reexecutados
quando esta alteração for promovida como uma nova baseline.

## Ambiente

O Dockerfile do devcontainer foi construído com sucesso. O script de
`postCreateCommand` foi executado como usuário não privilegiado e terminou com
`Codespace ready`, após `setup-check`, build e os testes unitários então
existentes.

Ferramentas observadas: Icarus/VVP 12.0, Verilator 5.020, Yosys 0.33, Graphviz
2.43.0, Python 3.12.3 e Make 4.3.

## Comandos e resultados — baseline de 2026-07-19

| Comando | Resultado |
| --- | --- |
| `make setup-check` | PASS; 7 fontes oficiais, sem módulos duplicados, top presente. |
| `make lint` | PASS; logs de Icarus e Verilator sem warnings. |
| `make build` | PASS; `build/rtl/riscv_top.vvp`. |
| `make test-unit` | HISTÓRICO: PASS nos cinco testbenches self-checking então existentes. |
| `make test-core TEST=core_basic` | HISTÓRICO: PASS em 86 ciclos, antes do firmware expandido. |
| `make ci` | PASS completo no devcontainer. |
| `make wave TEST=core_basic` | PASS; VCD válido de aproximadamente 60 KiB. |
| `make synth` | PASS; `check` com zero problemas e zero warnings. |
| `make schematic MODULE=alu` | PASS; SVG renderizado e inspecionado. |
| `make schematic MODULE=riscv_top` | PASS; esquema hierárquico renderizado e inspecionado. |
| `make open-wave TEST=core_basic` fora do VS Code | PASS com instrução de fallback; não tenta GUI inexistente. |

O relatório de síntese contém 1.404 células genéricas na hierarquia completa,
incluindo datapath, controle, ALU, banco de registradores, memória e gerador de
imediato. O top tem 46 sinais públicos quando `RISCV_DEBUG` está ativo.

## Prova de falha

Para confirmar o contrato de exit status, o testbench do core foi executado com
um programa que não produz a assinatura esperada:

```text
make test-core TEST=arithmetic
FATAL: core timeout after 300 cycles (...)
make: Error 1
```

O processo Docker retornou exit status 2 (Make propagando o `$fatal` do VVP),
demonstrando que uma divergência não termina falsamente em verde.

## `.gitignore`

`git status --ignored` confirmou como ignorados `build/`, relatórios gerados, `waves/`,
`scripts/__pycache__/`, o executável VVP legado e os VCDs legados. Fontes,
Assembly, `.hex` reproduzível, configurações compartilhadas e logs históricos
explicitamente preservados continuam visíveis para versionamento. A política
atual também ignora `dist/` e mantém somente o inventário estático
`reports/chipinventor-portability.md` visível para versionamento.

## Limites desta validação

- O container e o post-create foram testados localmente, mas a criação pela UI
  hospedada do GitHub Codespaces e a instalação das extensões dependem de um
  repositório remoto; não havia commit/remoto para iniciar essa sessão.
- O VCD e a configuração inicial de sinais foram validados como arquivos. A UI
  WASM do Surfer no navegador não foi operada nesta execução local.
- O workflow foi revisado e chama a mesma baseline, mas só uma execução real no
  GitHub pode validar permissões e upload de artifacts end-to-end.
- Não há ainda GNU RISC-V toolchain, cocotb, riscv-formal, compliance de ISA,
  constraints de timing nem mapeamento tecnológico.
- O repositório recebido não declarava licença. O proprietário deve escolher
  uma licença antes de distribuição pública.

## Próximos passos

1. Criar o primeiro commit e abrir um Codespace no GitHub para validar a UI do
   Surfer e a primeira execução do Actions.
2. Adicionar testes integrados self-checking para AUIPC, shifts imediatos e
   operações I lógicas/comparação.
3. Definir comportamento de instrução ilegal, alinhamento e acessos fora da
   memória antes de ampliar a ISA.
4. Adotar uma toolchain RISC-V fixada e testes oficiais somente quando houver
   contrato de assinatura/traps.
5. Escolher tecnologia/constraints antes de interpretar área, frequência ou
   timing do netlist genérico.
