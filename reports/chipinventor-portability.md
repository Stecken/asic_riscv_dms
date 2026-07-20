# ChipInventor portability report

> Static repository scan only. This report is not evidence of execution or compatibility in ChipInventor.

## Scan scope

- Language profile: `systemverilog-2012`
- Official RTL manifest: `rtl/files.f`
- Portable testbench tree: `tb/portable/`
- Files scanned: 13

## Summary

| Error | Warning | Manual validation | Info |
| ---: | ---: | ---: | ---: |
| 0 | 2 | 28 | 16 |

## Findings

| Class | File | Line | Rule | Observation |
| --- | --- | ---: | --- | --- |
| WARNING | `rtl/memory.v` | 10 | `tool-pragma` | Tool-specific pragma may be ignored or rejected elsewhere. |
| WARNING | `rtl/memory.v` | 12 | `tool-pragma` | Tool-specific pragma may be ignored or rejected elsewhere. |
| MANUAL | `rtl/memory.v` | 20 | `rtl-initial` | Confirm synthesizable initialization semantics for the selected target flow. |
| MANUAL | `rtl/memory.v` | 25 | `memory-load` | Confirm relative firmware path and memory initialization support in ChipInventor. |
| MANUAL | `rtl/register_file.v` | 18 | `rtl-initial` | Confirm synthesizable initialization semantics for the selected target flow. |
| MANUAL | `tb/portable/tb_core.v` | 93 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/tb_core.v` | 110 | `plusargs` | Confirm simulator plusarg support; the default waveform path remains usable without it. |
| MANUAL | `tb/portable/tb_core.v` | 113 | `waveform` | Confirm VCD task support and where the platform stores the waveform. |
| MANUAL | `tb/portable/tb_core.v` | 114 | `waveform` | Confirm VCD task support and where the platform stores the waveform. |
| MANUAL | `tb/portable/tb_core.v` | 126 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/tb_core.v` | 153 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/tb_core.v` | 158 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_alu.v` | 25 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_alu.v` | 30 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_alu.v` | 54 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_control.v` | 46 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_control.v` | 58 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_control.v` | 79 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_control.v` | 84 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_control.v` | 94 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_control.v` | 99 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_control.v` | 110 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_control.v` | 115 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_immediate_gen.v` | 18 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_immediate_gen.v` | 35 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_memory.v` | 22 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_memory.v` | 47 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_register_file.v` | 45 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_register_file.v` | 49 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_register_file.v` | 76 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/hdl.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/rtl/alu.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/rtl/control.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/rtl/datapath.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/rtl/memory.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/rtl/register_file.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/rtl/riscv_top.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/rtl/top.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/simulate.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/testbench/tb_riscv.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/testbench/testCaravel.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/testbench/testbench.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `rtl/control.v` | 21 | `external-macro` | RISCV_DEBUG is intentionally supplied by the simulation command. |
| INFO | `rtl/datapath.v` | 24 | `external-macro` | RISCV_DEBUG is intentionally supplied by the simulation command. |
| INFO | `rtl/riscv_top.v` | 10 | `external-macro` | RISCV_DEBUG is intentionally supplied by the simulation command. |
| INFO | `tb/portable/tb_core.v` | 53 | `config-macro` | PROGRAM_HEX and PROGRAM_WORDS have local defaults and may be overridden by the runner. |

## Interpretation

`ERROR` blocks this repository package profile. `WARNING` flags a construct that may vary by tool. `MANUAL` requires confirmation in the real platform. `INFO` records an intentional dependency or convention.

The scanner does not rewrite RTL and cannot replace the official Block Guide, Submission Guide, or a manual platform run.
