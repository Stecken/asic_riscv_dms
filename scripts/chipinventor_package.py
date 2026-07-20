#!/usr/bin/env python3
"""Build the repository-defined deterministic ChipInventor handoff directory."""

from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
from pathlib import Path

from project_config import load_project_config


ROOT = Path(__file__).resolve().parents[1]


def git(*args: str) -> str:
    return subprocess.check_output(
        ["git", *args], cwd=ROOT, text=True, stderr=subprocess.DEVNULL
    ).strip()


def manifest_entries(path: Path) -> list[Path]:
    return [
        Path(line.strip())
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]


def copy_payload(source: Path, destination: Path) -> None:
    if not source.is_file() or source.is_symlink():
        raise SystemExit(f"source must be a regular file: {source.relative_to(ROOT)}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, destination)
    os.chmod(destination, 0o644)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(65536), b""):
            digest.update(block)
    return digest.hexdigest()


def main() -> int:
    os.chdir(ROOT)
    config = load_project_config()
    output_rel = Path(config["CHIPINVENTOR_DIST_DIR"])
    if output_rel.is_absolute() or output_rel.parts != ("dist", "chipinventor"):
        raise SystemExit("refusing unsafe CHIPINVENTOR_DIST_DIR")
    output = ROOT / output_rel
    if output.exists():
        shutil.rmtree(output)
    for name in ("rtl", "tb", "firmware"):
        (output / name).mkdir(parents=True, exist_ok=True)

    rtl_sources = manifest_entries(ROOT / config["RTL_MANIFEST"])
    payload: dict[Path, tuple[str, str]] = {}
    packaged_rtl: list[str] = []
    for source_rel in rtl_sources:
        destination_rel = Path("rtl") / source_rel.name
        copy_payload(ROOT / source_rel, output / destination_rel)
        packaged_rtl.append(destination_rel.as_posix())
        payload[destination_rel] = ("rtl", source_rel.as_posix())

    tb_source_rel = Path(config["PORTABLE_TB_SOURCE"])
    packaged_tb = Path("tb") / tb_source_rel.name
    copy_payload(ROOT / tb_source_rel, output / packaged_tb)
    payload[packaged_tb] = ("testbench", tb_source_rel.as_posix())

    firmware_names = config["PACKAGE_FIRMWARE_FILES"].split()
    for name in firmware_names:
        source_rel = Path(config["FIRMWARE_DIR"]) / name
        destination_rel = Path("firmware") / name
        copy_payload(ROOT / source_rel, output / destination_rel)
        payload[destination_rel] = ("firmware", source_rel.as_posix())

    sources = packaged_rtl + [packaged_tb.as_posix()]
    sources_path = output / "sources.txt"
    sources_path.write_text("\n".join(sources) + "\n", encoding="utf-8")
    os.chmod(sources_path, 0o644)
    payload[Path("sources.txt")] = ("source-list", config["RTL_MANIFEST"])

    template_rel = Path(config["CHIPINVENTOR_CONFIG_TEMPLATE"])
    rendered = (ROOT / template_rel).read_text(encoding="utf-8")
    replacements = {
        "@PACKAGE_FORMAT_VERSION@": config["CHIPINVENTOR_PACKAGE_FORMAT_VERSION"],
        "@PROJECT_NAME@": config["PROJECT_NAME"],
        "@LANGUAGE_PROFILE@": config["CHIPINVENTOR_LANGUAGE_PROFILE"],
        "@TOP_MODULE@": config["TOP_MODULE"],
        "@TB_TOP@": config["PORTABLE_TB_TOP"],
        "@TB_FILENAME@": tb_source_rel.name,
        "@DEFAULT_FIRMWARE@": config["DEFAULT_FIRMWARE"],
        '"@RTL_SOURCES_JSON@"': json.dumps(packaged_rtl),
    }
    for token, value in replacements.items():
        rendered = rendered.replace(token, value)
    if "@" in rendered:
        raise SystemExit("unresolved token in ChipInventor config template")
    parsed = json.loads(rendered)
    config_path = output / "config.json"
    config_path.write_text(json.dumps(parsed, indent=2) + "\n", encoding="utf-8")
    payload[Path("config.json")] = ("configuration", template_rel.as_posix())

    commit = git("rev-parse", "HEAD")
    branch = os.environ.get("GITHUB_HEAD_REF") or os.environ.get("GITHUB_REF_NAME")
    if not branch:
        branch = git("branch", "--show-current") or "DETACHED"
    commit_date = git("show", "-s", "--format=%cI", commit)
    worktree = "dirty" if git("status", "--porcelain", "--untracked-files=all") else "clean"
    version_text = (
        f"commit: {commit}\n"
        f"branch: {branch}\n"
        f"date: {commit_date}\n"
        f"worktree: {worktree}\n"
        f"top: {config['TOP_MODULE']}\n"
        f"testbench: {config['PORTABLE_TB_TOP']}\n"
        f"package_format: {config['CHIPINVENTOR_PACKAGE_FORMAT_VERSION']}\n"
    )
    version_path = output / "VERSION.txt"
    version_path.write_text(version_text, encoding="utf-8")
    payload[Path("VERSION.txt")] = ("version", "git/config/project.mk")

    manifest_path = output / "MANIFEST.txt"
    lines = ["path\tsha256\tclassification\torigin"]
    for path in sorted(payload, key=lambda item: item.as_posix()):
        classification, origin = payload[path]
        lines.append(f"{path.as_posix()}\t{sha256(output / path)}\t{classification}\t{origin}")
    manifest_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    os.chmod(manifest_path, 0o644)

    print(f"Generated {output_rel} ({len(payload)} payload files plus MANIFEST.txt)")
    print("This repository package format is not proof of ChipInventor compatibility.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
