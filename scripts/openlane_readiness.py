#!/usr/bin/env python3
"""Inventory unresolved OpenLane template fields; do not run implementation."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FILES = (
    Path("openlane/config.template.json"),
    Path("openlane/pin_order.template.cfg"),
    Path("openlane/constraints.template.sdc"),
)


def main() -> int:
    missing = [path for path in FILES if not (ROOT / path).is_file()]
    if missing:
        for path in missing:
            print(f"ERROR: missing template: {path}")
        return 1
    total = 0
    print("OpenLane readiness (informational only):")
    for path in FILES:
        lines = (ROOT / path).read_text(encoding="utf-8").splitlines()
        entries = [(number, line.strip()) for number, line in enumerate(lines, 1) if "PENDENTE_DE_CONFIRMACAO" in line]
        total += len(entries)
        print(f"- {path}: {len(entries)} pending entries")
        for number, line in entries:
            print(f"    line {number}: {line}")
    print(f"Pending physical-design entries: {total}")
    print("No P&R, GDS generation, physical constraint choice, tag, or release was performed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
