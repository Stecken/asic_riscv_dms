#!/usr/bin/env python3
"""Report drift since the newest explicitly approved manual validation."""

from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path

from project_config import load_project_config


ROOT = Path(__file__).resolve().parents[1]
COMMIT_RE = re.compile(r"^- Commit validado no ChipInventor:\s*([0-9a-fA-F]{40})\s*$", re.MULTILINE)
RESULT_RE = re.compile(r"^- Resultado geral:\s*APROVADO\s*$", re.MULTILINE)


def git(*args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["git", *args], cwd=ROOT, text=True, capture_output=True, check=check)


def main() -> int:
    os.chdir(ROOT)
    config = load_project_config()
    records = sorted(Path("validation/chipinventor").glob("????-??-??.md"), reverse=True)
    validated: tuple[Path, str] | None = None
    for record in records:
        text = record.read_text(encoding="utf-8")
        match = COMMIT_RE.search(text)
        if match and RESULT_RE.search(text):
            validated = (record, match.group(1).lower())
            break

    current = git("rev-parse", "HEAD").stdout.strip()
    print(f"Current commit: {current}")
    if validated is None:
        print("Last validated commit: NONE")
        print("Last validation date: NONE")
        print("Commits since validation: UNKNOWN")
        print("RTL changed since validation: UNKNOWN")
        print("Reason: no dated record contains both a 40-character commit and Resultado geral: APROVADO.")
    else:
        record, commit = validated
        exists = git("cat-file", "-e", f"{commit}^{{commit}}", check=False).returncode == 0
        print(f"Last validated commit: {commit}")
        print(f"Last validation date: {record.stem}")
        print(f"Validation record: {record}")
        if not exists:
            print("Commits since validation: UNKNOWN")
            print("RTL changed since validation: UNKNOWN")
            print("Reason: the recorded commit is not present in this checkout.")
        else:
            ancestor = git("merge-base", "--is-ancestor", commit, "HEAD", check=False).returncode == 0
            if ancestor:
                count = git("rev-list", "--count", f"{commit}..HEAD").stdout.strip()
                changed = [line for line in git("diff", "--name-only", f"{commit}..HEAD", "--", "rtl").stdout.splitlines() if line]
                print(f"Commits since validation: {count}")
                print(f"RTL changed since validation: {'YES' if changed else 'NO'}")
                if changed:
                    print("Changed RTL files: " + ", ".join(changed))
            else:
                print("Commits since validation: DIVERGED")
                print("RTL changed since validation: UNKNOWN")
                print("Reason: the validated commit is not an ancestor of HEAD.")

    dirty_rtl = [line for line in git("status", "--short", "--", "rtl").stdout.splitlines() if line]
    print(f"Uncommitted RTL changes: {'YES' if dirty_rtl else 'NO'}")
    if dirty_rtl:
        for line in dirty_rtl:
            print(f"  {line}")
    print(f"Configured RTL manifest: {config['RTL_MANIFEST']}")
    print("Status is informational and does not create or infer a platform validation.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
