# Registros manuais do ChipInventor

Esta pasta separa checagens locais de uma validação realmente executada na plataforma. Crie um formulário vazio com:

```bash
make chipinventor-validation-record DATE=YYYY-MM-DD
```

O comando nunca preenche resultados. Depois do teste manual, registre o commit exato e use `Resultado geral: APROVADO` somente se a execução na plataforma tiver sido concluída e revisada.

Uma tag opcional pode ser criada manualmente no formato `chipinventor-ok-YYYY-MM-DD`. Nenhum script deste repositório cria ou envia tags.
