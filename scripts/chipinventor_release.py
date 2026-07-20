#!/usr/bin/env python3
"""Create a reproducible local archive; never tag, publish, or mutate Git."""

from __future__ import annotations

import gzip
import hashlib
import io
import os
import subprocess
import tarfile
from pathlib import Path

from project_config import load_project_config


ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    os.chdir(ROOT)
    config = load_project_config()
    package = ROOT / config["CHIPINVENTOR_DIST_DIR"]
    release_dir = ROOT / config["CHIPINVENTOR_RELEASE_DIR"]
    if not package.is_dir():
        raise SystemExit("package missing; run make chipinventor-package first")
    release_dir.mkdir(parents=True, exist_ok=True)

    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    epoch = int(subprocess.check_output(
        ["git", "show", "-s", "--format=%ct", commit], cwd=ROOT, text=True
    ).strip())
    version = config["CHIPINVENTOR_PACKAGE_FORMAT_VERSION"]
    dirty = "-dirty" if "worktree: dirty" in (package / "VERSION.txt").read_text(encoding="utf-8") else ""
    base = f"{config['PROJECT_NAME']}-chipinventor-v{version}-{commit[:12]}{dirty}.tar.gz"
    archive = release_dir / base

    buffer = io.BytesIO()
    with tarfile.open(fileobj=buffer, mode="w", format=tarfile.PAX_FORMAT) as tar:
        for path in sorted(package.rglob("*"), key=lambda item: item.relative_to(package).as_posix()):
            relative = path.relative_to(package)
            if not path.is_file():
                continue
            info = tar.gettarinfo(str(path), arcname=(Path("chipinventor") / relative).as_posix())
            info.uid = 0
            info.gid = 0
            info.uname = ""
            info.gname = ""
            info.mtime = epoch
            info.mode = 0o644
            with path.open("rb") as stream:
                tar.addfile(info, stream)
    with archive.open("wb") as raw:
        with gzip.GzipFile(filename="", mode="wb", fileobj=raw, mtime=epoch) as compressed:
            compressed.write(buffer.getvalue())

    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    checksum = archive.with_suffix(archive.suffix + ".sha256")
    checksum.write_text(f"{digest}  {archive.name}\n", encoding="ascii")
    print(f"Archive: {archive.relative_to(ROOT)}")
    print(f"SHA-256: {digest}")
    print("No Git tag or remote release was created.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
