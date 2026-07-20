#!/usr/bin/env python3
"""Validate the deterministic official RTL manifest."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

from project_config import load_project_config


MODULE_RE = re.compile(r"^\s*module\s+([A-Za-z_][A-Za-z0-9_$]*)\b", re.MULTILINE)


def main() -> int:
    config = load_project_config()
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, default=Path(config["RTL_MANIFEST"]))
    parser.add_argument("--top", default=config["TOP_MODULE"])
    parser.add_argument("--print", action="store_true", dest="print_sources")
    args = parser.parse_args()

    errors: list[str] = []
    try:
        entries = [
            line.strip()
            for line in args.manifest.read_text(encoding="utf-8").splitlines()
            if line.strip() and not line.lstrip().startswith("#")
        ]
    except OSError as exc:
        print(exc, file=sys.stderr)
        return 1

    if len(entries) != len(set(entries)):
        errors.append(f"{args.manifest} contains a duplicate path")

    listed_paths = {Path(entry) for entry in entries}
    disk_paths = set(Path("rtl").glob("*.v"))
    missing_from_manifest = sorted(disk_paths - listed_paths)
    extra_in_manifest = sorted(listed_paths - disk_paths)
    if missing_from_manifest:
        errors.append("official RTL missing from manifest: " + ", ".join(map(str, missing_from_manifest)))
    if extra_in_manifest:
        errors.append("manifest entries missing from disk: " + ", ".join(map(str, extra_in_manifest)))

    module_owners: dict[str, Path] = {}
    for path in sorted(listed_paths):
        if path.parent != Path("rtl"):
            errors.append(f"official source must be directly under rtl/: {path}")
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except OSError as exc:
            errors.append(str(exc))
            continue
        modules = MODULE_RE.findall(text)
        if len(modules) != 1:
            errors.append(f"{path} must contain exactly one module; found {modules}")
            continue
        module = modules[0]
        if module != path.stem:
            errors.append(f"{path} contains module {module}; expected {path.stem}")
        if module in module_owners:
            errors.append(f"duplicate module {module}: {module_owners[module]} and {path}")
        module_owners[module] = path

    if args.top not in module_owners:
        errors.append(f"top module {args.top!r} is absent from official RTL")

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    if args.print_sources:
        print(" ".join(entries))
    else:
        print(f"PASS source manifest: {len(entries)} files, top={args.top}, no duplicate modules")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
