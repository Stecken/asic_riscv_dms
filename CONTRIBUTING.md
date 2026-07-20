# Contribuindo

## Fluxo

1. Abra ou escolha uma issue com critérios de aceitação verificáveis.
2. Crie uma branch específica, por exemplo `feature/issue-42-srl` ou
   `fix/issue-57-branch-target`.
3. Faça a menor mudança coerente e inclua testes self-checking.
4. Execute `make ci` no devcontainer.
5. Abra um pull request, preencha o template e vincule a issue.
6. Aguarde revisão e CI verde antes do merge.

## Regras para RTL

- `rtl/files.f` define toda e somente a fonte oficial.
- Cada arquivo em `rtl/*.v` deve conter exatamente um módulo de mesmo nome.
- Não adicione versões monolíticas ou geradas à lista oficial.
- Não use fios implícitos; os arquivos oficiais usam `default_nettype none`.
- Clock é na borda de subida. `rst` é assíncrono, ativo em nível alto.
- Mudança funcional exige primeiro um teste que falhe sem a correção.
- Pipeline, cache, forwarding, hazards, interrupções, CSR, extensão M, novo
  barramento ou separação Harvard exigem ADR em `docs/decisions/`.

## Programas de teste

Edite `tb/programs/*.S`, não o `.hex` diretamente:

```bash
make programs
make programs-check
make test-core
```

O assembler mínimo rejeita instruções fora do subconjunto suportado. Para
programas maiores, proponha a inclusão explícita e versionada de uma toolchain
RISC-V em um ADR, sem depender de software instalado apenas na máquina local.

## Antes do pull request

```bash
make setup-check
make lint
make test
make synth
```

Se o comportamento temporal for relevante, gere `make wave` e anexe o VCD ao
PR como artifact ou evidência; não faça commit do VCD. Artefatos em `build/`,
`reports/` e `waves/` são descartáveis e estão no `.gitignore`.
