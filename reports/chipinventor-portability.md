# ChipInventor portability report

> Static repository scan only. This report is not evidence of execution or compatibility in ChipInventor.

## Scan scope

- Language profile: `systemverilog-2012`
- Official RTL manifest: `rtl/files.f`
- Portable testbench tree: `tb/portable/`
- Files scanned: 17

## Summary

| Error | Warning | Manual validation | Info |
| ---: | ---: | ---: | ---: |
| 0 | 32 | 34 | 19 |

## Findings

| Class | File | Line | Rule | Observation |
| --- | --- | ---: | --- | --- |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/06-yosys-synthesis/riscv_top.nl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/13-openroad-floorplan/riscv_top.nl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/13-openroad-floorplan/riscv_top.pnl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/18-openroad-tapendcapinsertion/riscv_top.nl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/18-openroad-tapendcapinsertion/riscv_top.pnl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/20-openroad-generatepdn/riscv_top.nl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/20-openroad-generatepdn/riscv_top.pnl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/23-openroad-globalplacementskipio/riscv_top.nl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/23-openroad-globalplacementskipio/riscv_top.pnl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/24-openroad-ioplacement/riscv_top.nl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/24-openroad-ioplacement/riscv_top.pnl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/27-openroad-globalplacement/riscv_top.nl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/27-openroad-globalplacement/riscv_top.pnl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/31-openroad-repairdesignpostgpl/riscv_top.nl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/31-openroad-repairdesignpostgpl/riscv_top.pnl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/33-openroad-detailedplacement/riscv_top.nl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/33-openroad-detailedplacement/riscv_top.pnl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/34-openroad-cts/riscv_top.nl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/34-openroad-cts/riscv_top.pnl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/36-openroad-resizertimingpostcts/riscv_top.nl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/36-openroad-resizertimingpostcts/riscv_top.pnl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/43-openroad-detailedrouting/riscv_top.nl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/43-openroad-detailedrouting/riscv_top.pnl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/51-openroad-fillinsertion/riscv_top.nl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/51-openroad-fillinsertion/riscv_top.pnl.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `openlane/runs/RUN_2026-07-23_02-56-23/tmp/ae0ae0ec2be8463f8fee51a44ac002c0.bb.v` | - | `outside-source-list` | HDL file is outside the official/portable explicit source set. |
| WARNING | `rtl/datapath.v` | 61 | `tool-pragma` | Tool-specific pragma may be ignored or rejected elsewhere. |
| WARNING | `rtl/datapath.v` | 63 | `tool-pragma` | Tool-specific pragma may be ignored or rejected elsewhere. |
| WARNING | `rtl/dmem.v` | 8 | `tool-pragma` | Tool-specific pragma may be ignored or rejected elsewhere. |
| WARNING | `rtl/dmem.v` | 10 | `tool-pragma` | Tool-specific pragma may be ignored or rejected elsewhere. |
| WARNING | `rtl/imem.v` | 9 | `tool-pragma` | Tool-specific pragma may be ignored or rejected elsewhere. |
| WARNING | `rtl/imem.v` | 11 | `tool-pragma` | Tool-specific pragma may be ignored or rejected elsewhere. |
| MANUAL | `rtl/dmem.v` | 18 | `rtl-initial` | Confirm synthesizable initialization semantics for the selected target flow. |
| MANUAL | `rtl/imem.v` | 18 | `rtl-initial` | Confirm synthesizable initialization semantics for the selected target flow. |
| MANUAL | `rtl/imem.v` | 23 | `memory-load` | Confirm relative firmware path and memory initialization support in ChipInventor. |
| MANUAL | `rtl/register_file.v` | 18 | `rtl-initial` | Confirm synthesizable initialization semantics for the selected target flow. |
| MANUAL | `tb/portable/tb_core.v` | 93 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/tb_core.v` | 110 | `plusargs` | Confirm simulator plusarg support; the default waveform path remains usable without it. |
| MANUAL | `tb/portable/tb_core.v` | 113 | `waveform` | Confirm VCD task support and where the platform stores the waveform. |
| MANUAL | `tb/portable/tb_core.v` | 114 | `waveform` | Confirm VCD task support and where the platform stores the waveform. |
| MANUAL | `tb/portable/tb_core.v` | 126 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/tb_core.v` | 163 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/tb_core.v` | 168 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_alu.v` | 25 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_alu.v` | 30 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_alu.v` | 54 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_branch_comp.v` | 24 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_branch_comp.v` | 49 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_control.v` | 46 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_control.v` | 58 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_control.v` | 79 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_control.v` | 84 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_control.v` | 94 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_control.v` | 99 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_control.v` | 110 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_control.v` | 117 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_control.v` | 122 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_dmem.v` | 22 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_dmem.v` | 47 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_imem.v` | 18 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_imem.v` | 34 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_immediate_gen.v` | 18 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_immediate_gen.v` | 35 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_register_file.v` | 45 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_register_file.v` | 49 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| MANUAL | `tb/portable/unit/tb_register_file.v` | 76 | `self-check` | Confirm nonzero failure propagation for self-checking tasks. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/hdl.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/rtl/alu.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/rtl/branch_comp.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/rtl/control.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/rtl/datapath.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/rtl/dmem.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/rtl/imem.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/rtl/register_file.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/rtl/riscv_top.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/rtl/top.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/simulate.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
| INFO | `legacy/original-export/design2.0-2026.06.21/design/testbench/tb_branch_comp.v` | - | `outside-source-list` | Preserved legacy HDL is intentionally excluded from the explicit source list. |
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
