#!/usr/bin/env python3
"""Generate a static portability inventory without changing HDL sources."""

from __future__ import annotations

import os
import re
from dataclasses import dataclass
from pathlib import Path

from project_config import load_project_config


ROOT = Path(__file__).resolve().parents[1]
ABSOLUTE_RE = re.compile(r"(?:^|[\s\"'(=])(?:/[A-Za-z0-9_.-]+/|[A-Za-z]:[\\/])")


@dataclass(frozen=True)
class Finding:
    level: str
    path: str
    line: int | str
    rule: str
    detail: str


def source_manifest(path: Path) -> list[Path]:
    return [
        Path(line.strip())
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]


def add_matches(
    findings: list[Finding], path: Path, lines: list[str], pattern: re.Pattern[str],
    level: str, rule: str, detail: str,
) -> None:
    for number, line in enumerate(lines, 1):
        if pattern.search(line):
            findings.append(Finding(level, path.as_posix(), number, rule, detail))


def main() -> int:
    os.chdir(ROOT)
    config = load_project_config()
    rtl = source_manifest(Path(config["RTL_MANIFEST"]))
    portable_tb = sorted(Path("tb/portable").rglob("*.v"))
    sources = rtl + portable_tb
    findings: list[Finding] = []

    ignored_roots = {"build", "dist", ".git"}
    all_hdl = {
        path for path in Path(".").rglob("*.v")
        if path.parts and path.parts[0] not in ignored_roots
    }
    for path in sorted(all_hdl - set(sources)):
        level = "INFO" if path.parts and path.parts[0] == "legacy" else "WARNING"
        detail = (
            "Preserved legacy HDL is intentionally excluded from the explicit source list."
            if level == "INFO"
            else "HDL file is outside the official/portable explicit source set."
        )
        findings.append(Finding(level, path.as_posix(), "-", "outside-source-list", detail))

    disk_rtl = set(Path("rtl").glob("*.v"))
    listed_rtl = set(rtl)
    for path in sorted(disk_rtl - listed_rtl):
        findings.append(Finding("ERROR", path.as_posix(), "-", "unlisted-rtl", "RTL file is outside the official source manifest."))
    for path in sorted(listed_rtl - disk_rtl):
        findings.append(Finding("ERROR", path.as_posix(), "-", "missing-rtl", "Official manifest entry is missing from disk."))

    for path in sources:
        text = path.read_text(encoding="utf-8")
        lines = text.splitlines()
        add_matches(findings, path, lines, ABSOLUTE_RE, "ERROR", "absolute-path", "Absolute filesystem path cannot travel with the package.")
        add_matches(findings, path, lines, re.compile(r"`include\s+[\"<]"), "WARNING", "include", "Include resolution must be confirmed in the target platform.")
        add_matches(findings, path, lines, re.compile(r"\b(?:import|export)\s+\"DPI-|\bDPI-C\b"), "ERROR", "dpi", "DPI requires an external runtime and is outside the portable profile.")
        add_matches(findings, path, lines, re.compile(r"^\s*(?:virtual\s+)?class\b"), "WARNING", "class", "SystemVerilog class support must be confirmed.")
        add_matches(findings, path, lines, re.compile(r"^\s*interface\b"), "WARNING", "interface", "SystemVerilog interface support must be confirmed.")
        add_matches(findings, path, lines, re.compile(r"^\s*package\b|^\s*import\s+[A-Za-z_]"), "WARNING", "package", "SystemVerilog package support and compile order must be confirmed.")
        add_matches(findings, path, lines, re.compile(r"\bcocotb\b", re.IGNORECASE), "ERROR", "cocotb", "Python/cocotb runtime is outside the portable package.")
        add_matches(findings, path, lines, re.compile(r"\bverilator\b", re.IGNORECASE), "WARNING", "tool-pragma", "Tool-specific pragma may be ignored or rejected elsewhere.")
        add_matches(findings, path, lines, re.compile(r"\b(?:dut|uut)\.[A-Za-z_][A-Za-z0-9_$]*\."), "WARNING", "hierarchical-access", "Deep DUT hierarchy access is fragile across platforms.")
        add_matches(findings, path, lines, re.compile(r"\$(?:readmemh|readmemb)\b"), "MANUAL", "memory-load", "Confirm relative firmware path and memory initialization support in ChipInventor.")
        add_matches(findings, path, lines, re.compile(r"\$(?:dumpfile|dumpvars)\b"), "MANUAL", "waveform", "Confirm VCD task support and where the platform stores the waveform.")
        add_matches(findings, path, lines, re.compile(r"\$(?:fatal|error)\b"), "MANUAL", "self-check", "Confirm nonzero failure propagation for self-checking tasks.")
        add_matches(findings, path, lines, re.compile(r"\$value\$plusargs\b"), "MANUAL", "plusargs", "Confirm simulator plusarg support; the default waveform path remains usable without it.")
        if path in listed_rtl:
            add_matches(findings, path, lines, re.compile(r"^\s*initial\b"), "MANUAL", "rtl-initial", "Confirm synthesizable initialization semantics for the selected target flow.")
        debug_macro = re.compile(r"`(?:ifdef|ifndef)\s+RISCV_DEBUG\b")
        if debug_macro.search(text):
            findings.append(Finding("INFO", path.as_posix(), next(i for i, line in enumerate(lines, 1) if debug_macro.search(line)), "external-macro", "RISCV_DEBUG is intentionally supplied by the simulation command."))
        if "`PROGRAM_HEX" in text or "`PROGRAM_WORDS" in text:
            first = next(i for i, line in enumerate(lines, 1) if "`PROGRAM_" in line)
            findings.append(Finding("INFO", path.as_posix(), first, "config-macro", "PROGRAM_HEX and PROGRAM_WORDS have local defaults and may be overridden by the runner."))

    if config["CHIPINVENTOR_LANGUAGE_PROFILE"].lower().startswith("verilog-"):
        sv_pattern = re.compile(r"\b(?:logic|always_ff|always_comb|typedef|enum|string)\b|\$(?:fatal|error)\b")
        for path in sources:
            add_matches(findings, path, path.read_text(encoding="utf-8").splitlines(), sv_pattern, "ERROR", "language-profile", "SystemVerilog construct conflicts with the configured Verilog-only profile.")

    order = {"ERROR": 0, "WARNING": 1, "MANUAL": 2, "INFO": 3}
    findings.sort(
        key=lambda item: (
            order[item.level],
            item.path,
            item.line if isinstance(item.line, int) else -1,
            item.rule,
        )
    )
    counts = {level: sum(item.level == level for item in findings) for level in order}
    report = Path("reports/chipinventor-portability.md")
    report.parent.mkdir(parents=True, exist_ok=True)
    rows = [
        "# ChipInventor portability report",
        "",
        "> Static repository scan only. This report is not evidence of execution or compatibility in ChipInventor.",
        "",
        "## Scan scope",
        "",
        f"- Language profile: `{config['CHIPINVENTOR_LANGUAGE_PROFILE']}`",
        f"- Official RTL manifest: `{config['RTL_MANIFEST']}`",
        f"- Portable testbench tree: `tb/portable/`",
        f"- Files scanned: {len(sources)}",
        "",
        "## Summary",
        "",
        "| Error | Warning | Manual validation | Info |",
        "| ---: | ---: | ---: | ---: |",
        f"| {counts['ERROR']} | {counts['WARNING']} | {counts['MANUAL']} | {counts['INFO']} |",
        "",
        "## Findings",
        "",
        "| Class | File | Line | Rule | Observation |",
        "| --- | --- | ---: | --- | --- |",
    ]
    if findings:
        for finding in findings:
            rows.append(f"| {finding.level} | `{finding.path}` | {finding.line} | `{finding.rule}` | {finding.detail} |")
    else:
        rows.append("| INFO | - | - | `none` | No patterns from this scanner were found. |")
    rows += [
        "",
        "## Interpretation",
        "",
        "`ERROR` blocks this repository package profile. `WARNING` flags a construct that may vary by tool. "
        "`MANUAL` requires confirmation in the real platform. `INFO` records an intentional dependency or convention.",
        "",
        "The scanner does not rewrite RTL and cannot replace the official Block Guide, Submission Guide, or a manual platform run.",
    ]
    report.write_text("\n".join(rows) + "\n", encoding="utf-8")
    print(f"Portability report: {report} ({counts['ERROR']} errors, {counts['WARNING']} warnings, {counts['MANUAL']} manual)")
    return 1 if counts["ERROR"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
