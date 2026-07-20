#!/usr/bin/env python3
"""Validate and simulate the generated package without platform claims."""

from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path, PurePosixPath

from project_config import load_project_config


ROOT = Path(__file__).resolve().parents[1]
MODULE_RE = re.compile(r"^\s*module\s+([A-Za-z_][A-Za-z0-9_$]*)\b", re.MULTILINE)
INCLUDE_RE = re.compile(r"`include\s+[\"<]([^\">]+)[\">]")
READ_FILE_RE = re.compile(r"\$(?:readmemh|readmemb)\s*\(\s*\"([^\"]+)\"")
ABSOLUTE_RE = re.compile(r"(?:^|[\s\"'(=])(?:/[A-Za-z0-9_.-]+/|[A-Za-z]:[\\/])")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(65536), b""):
            digest.update(block)
    return digest.hexdigest()


def safe_relative(value: str) -> bool:
    path = PurePosixPath(value)
    return bool(value) and not path.is_absolute() and ".." not in path.parts and "\\" not in value


def snapshot(root: Path) -> dict[str, str]:
    return {
        path.relative_to(root).as_posix(): sha256(path)
        for path in sorted(root.rglob("*"))
        if path.is_file()
    }


def main() -> int:
    os.chdir(ROOT)
    project = load_project_config()
    package = ROOT / project["CHIPINVENTOR_DIST_DIR"]
    errors: list[str] = []
    notes: list[str] = []
    log_dir = ROOT / "build/logs"
    log_dir.mkdir(parents=True, exist_ok=True)

    if not package.is_dir():
        print(f"ERROR: package does not exist: {package.relative_to(ROOT)}", file=sys.stderr)
        print("Run make chipinventor-package first.", file=sys.stderr)
        return 1

    required = {"config.json", "sources.txt", "MANIFEST.txt", "VERSION.txt"}
    for name in sorted(required):
        if not (package / name).is_file():
            errors.append(f"missing required file: {name}")

    try:
        package_config = json.loads((package / "config.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(f"invalid config.json: {exc}")
        package_config = {}

    try:
        source_names = [
            line.strip()
            for line in (package / "sources.txt").read_text(encoding="utf-8").splitlines()
            if line.strip()
        ]
    except OSError as exc:
        errors.append(f"cannot read sources.txt: {exc}")
        source_names = []

    if len(source_names) != len(set(source_names)):
        errors.append("sources.txt contains duplicate paths")
    source_paths: list[Path] = []
    for name in source_names:
        if not safe_relative(name):
            errors.append(f"unsafe or non-relative source path: {name}")
            continue
        path = package / name
        source_paths.append(path)
        if not path.is_file():
            errors.append(f"source listed but missing: {name}")
        elif path.suffix != ".v":
            errors.append(f"source does not use the portable .v file convention: {name}")

    expected_source_files = sorted(
        path.relative_to(package).as_posix()
        for directory in (package / "rtl", package / "tb")
        for path in directory.glob("*.v")
    )
    if sorted(source_names) != expected_source_files:
        errors.append("sources.txt does not exactly enumerate packaged RTL and testbench files")

    module_owners: dict[str, str] = {}
    for path in source_paths:
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        rel = path.relative_to(package).as_posix()
        if ABSOLUTE_RE.search(text):
            errors.append(f"absolute filesystem reference in {rel}")
        if "../" in text or "..\\" in text:
            errors.append(f"parent-directory reference in {rel}")
        for include in INCLUDE_RE.findall(text):
            include_path = path.parent / include
            if not safe_relative(include) or not include_path.is_file():
                errors.append(f"external or missing include in {rel}: {include}")
        for filename in READ_FILE_RE.findall(text):
            referenced = package / filename
            if not safe_relative(filename) or not referenced.is_file():
                errors.append(f"external or missing memory file in {rel}: {filename}")
        for module in MODULE_RE.findall(text):
            if module in module_owners:
                errors.append(f"duplicate module {module}: {module_owners[module]} and {rel}")
            else:
                module_owners[module] = rel

    expected_top = project["TOP_MODULE"]
    expected_tb = project["PORTABLE_TB_TOP"]
    if expected_top not in module_owners:
        errors.append(f"configured top module is absent: {expected_top}")
    if expected_tb not in module_owners:
        errors.append(f"configured testbench module is absent: {expected_tb}")

    design = package_config.get("design", {}) if isinstance(package_config, dict) else {}
    simulation = package_config.get("simulation", {}) if isinstance(package_config, dict) else {}
    if design.get("top_module") != expected_top:
        errors.append("config.json top_module differs from config/project.mk")
    if simulation.get("testbench_top") != expected_tb:
        errors.append("config.json testbench_top differs from config/project.mk")
    if design.get("sources_file") != "sources.txt":
        errors.append("config.json must reference sources.txt")
    if design.get("rtl_sources") != [name for name in source_names if name.startswith("rtl/")]:
        errors.append("config.json rtl_sources differs from sources.txt")
    tb_source = simulation.get("testbench_source")
    if tb_source not in source_names:
        errors.append("config.json testbench_source is absent from sources.txt")
    elif isinstance(tb_source, str) and (package / tb_source).is_file():
        tb_text = (package / tb_source).read_text(encoding="utf-8")
        if "$fatal" not in tb_text:
            errors.append("portable testbench has no real fatal failure path")
        if "timeout" not in tb_text.lower():
            errors.append("portable testbench has no explicit timeout diagnostic")

    firmware_name = simulation.get("firmware", "")
    if not isinstance(firmware_name, str) or not safe_relative(firmware_name):
        errors.append("config.json firmware path is not a safe relative path")
        firmware_path = package / "__invalid_firmware__"
    else:
        firmware_path = package / firmware_name
        if not firmware_path.is_file():
            errors.append(f"configured firmware is missing: {firmware_name}")
    firmware_words = 0
    if firmware_path.is_file():
        firmware_lines = [line.strip() for line in firmware_path.read_text(encoding="ascii").splitlines() if line.strip()]
        firmware_words = len(firmware_lines)
        for number, line in enumerate(firmware_lines, 1):
            if not re.fullmatch(r"[0-9A-Fa-f]{8}", line):
                errors.append(f"invalid firmware word at {firmware_name}:{number}")

    manifest_records: dict[str, tuple[str, str, str]] = {}
    try:
        manifest_lines = (package / "MANIFEST.txt").read_text(encoding="utf-8").splitlines()
        if not manifest_lines or manifest_lines[0] != "path\tsha256\tclassification\torigin":
            errors.append("MANIFEST.txt has an invalid header")
        for number, line in enumerate(manifest_lines[1:], 2):
            fields = line.split("\t")
            if len(fields) != 4:
                errors.append(f"MANIFEST.txt:{number}: expected four tab-separated fields")
                continue
            name, digest, classification, origin = fields
            if name in manifest_records:
                errors.append(f"MANIFEST.txt contains duplicate path: {name}")
            if not safe_relative(name) or not safe_relative(origin):
                errors.append(f"MANIFEST.txt:{number}: unsafe path or origin")
            manifest_records[name] = (digest, classification, origin)
    except OSError as exc:
        errors.append(f"cannot read MANIFEST.txt: {exc}")

    actual_payload = {
        path.relative_to(package).as_posix()
        for path in package.rglob("*")
        if path.is_file() and path.name != "MANIFEST.txt"
    }
    if set(manifest_records) != actual_payload:
        errors.append("MANIFEST.txt does not exactly cover every non-manifest package file")
    for name, (digest, classification, _origin) in manifest_records.items():
        path = package / name
        if path.is_file() and sha256(path) != digest:
            errors.append(f"hash mismatch: {name}")
        if not classification:
            errors.append(f"missing classification: {name}")

    forbidden_suffixes = {".vvp", ".vcd", ".fst", ".log", ".pyc", ".o"}
    for path in package.rglob("*"):
        if path.is_symlink():
            errors.append(f"symlink is not allowed: {path.relative_to(package)}")
        if path.is_file() and path.suffix.lower() in forbidden_suffixes:
            errors.append(f"temporary artifact is not allowed: {path.relative_to(package)}")
        if path.is_file():
            try:
                text = path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
            relative = path.relative_to(package).as_posix()
            if ABSOLUTE_RE.search(text):
                errors.append(f"absolute filesystem reference in package file: {relative}")
            if "../" in text or "..\\" in text:
                errors.append(f"parent-directory reference in package file: {relative}")

    missing_tools = [tool for tool in ("iverilog", "vvp") if shutil.which(tool) is None]
    if missing_tools:
        errors.append("missing required local simulator tools: " + ", ".join(missing_tools))

    if not errors:
        original_snapshot = snapshot(package)
        with tempfile.TemporaryDirectory(prefix="chipinventor-check-") as temporary:
            isolated = Path(temporary) / "package"
            shutil.copytree(package, isolated)
            binary = Path(temporary) / "simulation.vvp"
            compile_command = [
                "iverilog", "-g2012", "-Wall", "-Wimplicit", "-DRISCV_DEBUG",
                f'-DPROGRAM_HEX="{firmware_name}"',
                f"-DPROGRAM_WORDS={firmware_words}",
                "-s", expected_tb, "-o", str(binary), *source_names,
            ]
            compile_result = subprocess.run(
                compile_command, cwd=isolated, text=True, capture_output=True, check=False
            )
            compile_log = "$ " + " ".join(compile_command) + "\n" + compile_result.stdout + compile_result.stderr
            (log_dir / "chipinventor-check-compile.log").write_text(compile_log, encoding="utf-8")
            if compile_result.returncode != 0:
                errors.append("isolated Icarus compilation failed; see build/logs/chipinventor-check-compile.log")
            else:
                run_command = ["vvp", str(binary)]
                run_result = subprocess.run(
                    run_command, cwd=isolated, text=True, capture_output=True, check=False
                )
                run_log = "$ " + " ".join(run_command) + "\n" + run_result.stdout + run_result.stderr
                (log_dir / "chipinventor-check-simulation.log").write_text(run_log, encoding="utf-8")
                if run_result.returncode != 0 or f"PASS {expected_tb}" not in run_result.stdout:
                    errors.append("isolated portable testbench failed; see build/logs/chipinventor-check-simulation.log")
                waveform = isolated / simulation.get("waveform", "core_basic.vcd")
                if not waveform.is_file() or waveform.stat().st_size == 0:
                    errors.append("portable testbench did not create the configured waveform")
                elif "$enddefinitions" not in waveform.read_text(encoding="utf-8", errors="replace"):
                    errors.append("generated waveform is not a recognizable VCD")
            if snapshot(package) != original_snapshot:
                errors.append("package changed while it was checked")
        notes.append("portable testbench compiled and ran from a temporary isolated copy")

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        print("FAIL package infrastructure check; no ChipInventor compatibility claim.", file=sys.stderr)
        return 1

    for note in notes:
        print(f"PASS: {note}")
    print(f"PASS: {len(source_names)} explicit sources, unique modules, local references and valid manifest")
    print("PASS package infrastructure check; this is NOT a ChipInventor validation.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
