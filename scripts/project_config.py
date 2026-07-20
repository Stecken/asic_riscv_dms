#!/usr/bin/env python3
"""Read the repository's small, dependency-free canonical project config."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


CONFIG_PATH = Path("config/project.mk")
ASSIGNMENT_RE = re.compile(r"^([A-Z][A-Z0-9_]*)\s*:=\s*(.*?)\s*$")


def load_project_config(path: Path = CONFIG_PATH) -> dict[str, str]:
    config: dict[str, str] = {}
    for number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        match = ASSIGNMENT_RE.fullmatch(raw_line)
        if not match:
            raise ValueError(f"{path}:{number}: unsupported configuration syntax")
        key, value = match.groups()
        if key in config:
            raise ValueError(f"{path}:{number}: duplicate key {key}")
        config[key] = value
    return config


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("key", nargs="?")
    parser.add_argument("--config", type=Path, default=CONFIG_PATH)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    config = load_project_config(args.config)
    if args.json:
        print(json.dumps(config, indent=2, sort_keys=True))
        return 0
    if not args.key:
        parser.error("provide KEY or --json")
    try:
        print(config[args.key])
    except KeyError:
        parser.error(f"unknown key: {args.key}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
