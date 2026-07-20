# OpenLane readiness placeholders

Esta pasta é somente um ponto de preparação. Não contém decisões físicas aprovadas e não executa place-and-route, geração de GDS ou submissão.

Antes de adaptar os templates, confirme no PDK e no fluxo alvo: nome real do clock, período, dimensões/densidade do die e core, margens, camadas de roteamento, pinout, alimentação, arquivos de biblioteca e regras de IO. Todos esses campos permanecem `PENDENTE_DE_CONFIRMACAO`.

Use `make openlane-readiness` para listar as pendências sem iniciar OpenLane.
