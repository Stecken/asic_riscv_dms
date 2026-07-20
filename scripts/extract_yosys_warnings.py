#!/usr/bin/env python3
"""Write a stable warning-only synthesis report from a Yosys log."""

from pathlib import Path
import sys


def main() -> int:
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} INPUT_LOG OUTPUT_REPORT", file=sys.stderr)
        return 2
    source = Path(sys.argv[1])
    destination = Path(sys.argv[2])
    warnings = [
        line for line in source.read_text(encoding="utf-8", errors="replace").splitlines()
        if "warning" in line.lower()
    ]
    destination.write_text("\n".join(warnings) + ("\n" if warnings else "No Yosys warnings.\n"), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
