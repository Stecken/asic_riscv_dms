#!/usr/bin/env python3
"""Run the existing Yosys baseline from canonical project metadata."""

from __future__ import annotations

import os
import subprocess
from pathlib import Path

from project_config import load_project_config


ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    os.chdir(ROOT)
    config = load_project_config()
    sources = [
        line.strip()
        for line in Path(config["RTL_MANIFEST"]).read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]
    top = config["TOP_MODULE"]
    commands = [
        "read_verilog -sv -D RISCV_DEBUG " + " ".join(sources),
        f"hierarchy -check -top {top}",
        "proc",
        "opt",
        "fsm",
        "opt",
        "memory",
        "opt",
        "check",
        f"write_verilog -noattr build/synth/{top}_netlist.v",
        f"write_json build/synth/{top}.json",
        "tee -o reports/synthesis-stat.txt stat",
    ]
    subprocess.run(
        ["yosys", "-ql", "build/logs/yosys-synth.log", "-p", "; ".join(commands)],
        cwd=ROOT,
        check=True,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
