# Testbench support files

- `firmware/`: programas Assembly existentes, imagens `.hex` reproduzíveis e resultados esperados.
- `core_basic.sucl`: conjunto de sinais para inspeção manual no Surfer.

O pacote ChipInventor inclui somente os arquivos de suporte explicitamente listados em `config/project.mk`.
- `core_adversarial.S`: firmware integrado de busca de bugs para `make test-adversarial`.
- `core_adversarial.hex`: imagem reproduzível gerada pelo assembler mínimo.
