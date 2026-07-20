#!/usr/bin/env python3
"""Create an empty dated validation form without asserting any result."""

from __future__ import annotations

import datetime as dt
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    value = sys.argv[1] if len(sys.argv) == 2 else ""
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", value):
        print("ERROR: use DATE=YYYY-MM-DD", file=sys.stderr)
        return 2
    try:
        dt.date.fromisoformat(value)
    except ValueError as exc:
        print(f"ERROR: invalid date: {exc}", file=sys.stderr)
        return 2
    template = ROOT / "validation/chipinventor/TEMPLATE.md"
    destination = template.with_name(f"{value}.md")
    if destination.exists():
        print(f"ERROR: refusing to overwrite {destination.relative_to(ROOT)}", file=sys.stderr)
        return 1
    destination.write_text(template.read_text(encoding="utf-8").replace("@DATE@", value), encoding="utf-8")
    print(f"Created blank form: {destination.relative_to(ROOT)}")
    print("No validation result, tag, or commit was created.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
