# Portable testbenches

Testes HDL self-checking que não dependem de cocotb, Python em runtime, DPI ou bibliotecas do Verilator. `tb_core.v` possui timeout, retorna falha real com `$fatal`, carrega firmware relativo e sempre gera VCD.

O perfil local configurado é SystemVerilog 2012 por causa das tarefas de verificação usadas pelos testes. O suporte real do simulador ChipInventor permanece sujeito a teste manual.
