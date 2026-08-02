#!/usr/bin/env python3
"""Assemble the small, documented RV32I subset used by this repository's tests.

This is intentionally not a general-purpose assembler. It keeps checked-in .hex
programs reproducible without requiring a full RISC-V GNU toolchain.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


R_TYPE = {
    "add": (0b000, 0b0000000),
    "sub": (0b000, 0b0100000),
    "sll": (0b001, 0b0000000),
    "slt": (0b010, 0b0000000),
    "sltu": (0b011, 0b0000000),
    "xor": (0b100, 0b0000000),
    "srl": (0b101, 0b0000000),
    "sra": (0b101, 0b0100000),
    "or": (0b110, 0b0000000),
    "and": (0b111, 0b0000000),
}

I_TYPE = {
    "addi": 0b000,
    "slti": 0b010,
    "sltiu": 0b011,
    "xori": 0b100,
    "ori": 0b110,
    "andi": 0b111,
}

BRANCH_TYPE = {
    "beq": 0b000,
    "bne": 0b001,
    "blt": 0b100,
    "bge": 0b101,
    "bltu": 0b110,
    "bgeu": 0b111,
}


class AssemblyError(ValueError):
    pass


def register(token: str) -> int:
    match = re.fullmatch(r"x([0-9]|[12][0-9]|3[01])", token.lower())
    if not match:
        raise AssemblyError(f"invalid register: {token}")
    return int(match.group(1))


def immediate(token: str) -> int:
    try:
        return int(token, 0)
    except ValueError as exc:
        raise AssemblyError(f"invalid immediate: {token}") from exc


def signed_field(value: int, bits: int, what: str) -> int:
    minimum = -(1 << (bits - 1))
    maximum = (1 << (bits - 1)) - 1
    if not minimum <= value <= maximum:
        raise AssemblyError(f"{what} {value} does not fit signed {bits} bits")
    return value & ((1 << bits) - 1)


def unsigned_field(value: int, bits: int, what: str) -> int:
    if not 0 <= value < (1 << bits):
        raise AssemblyError(f"{what} {value} does not fit unsigned {bits} bits")
    return value


def tokenize(line: str) -> list[str]:
    line = re.split(r"#|//|;", line, maxsplit=1)[0]
    line = line.replace(",", " ").replace("(", " ").replace(")", " ")
    return line.split()


def read_source(path: Path) -> tuple[list[tuple[int, list[str], int]], dict[str, int]]:
    statements: list[tuple[int, list[str], int]] = []
    labels: dict[str, int] = {}
    pc = 0

    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        clean = re.split(r"#|//|;", raw_line, maxsplit=1)[0].strip()
        while ":" in clean:
            label, clean = clean.split(":", 1)
            label = label.strip()
            if not re.fullmatch(r"[A-Za-z_.$][\w.$]*", label):
                raise AssemblyError(f"line {line_number}: invalid label {label!r}")
            if label in labels:
                raise AssemblyError(f"line {line_number}: duplicate label {label}")
            labels[label] = pc
            clean = clean.strip()
        tokens = tokenize(clean)
        if tokens:
            statements.append((line_number, tokens, pc))
            pc += 4

    return statements, labels


def branch_offset(token: str, labels: dict[str, int], pc: int) -> int:
    value = labels[token] - pc if token in labels else immediate(token)
    if value & 1:
        raise AssemblyError(f"branch/jump offset must be 2-byte aligned: {value}")
    return value


def encode(tokens: list[str], labels: dict[str, int], pc: int) -> int:
    mnemonic = tokens[0].lower()
    args = tokens[1:]

    if mnemonic == ".word":
        if len(args) != 1:
            raise AssemblyError(".word expects one value")
        return immediate(args[0]) & 0xFFFFFFFF

    if mnemonic == "nop":
        mnemonic, args = "addi", ["x0", "x0", "0"]

    if mnemonic == "j":
        mnemonic, args = "jal", ["x0", *args]

    if mnemonic in R_TYPE:
        if len(args) != 3:
            raise AssemblyError(f"{mnemonic} expects rd, rs1, rs2")
        rd, rs1, rs2 = map(register, args)
        funct3, funct7 = R_TYPE[mnemonic]
        return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | 0x33

    if mnemonic in I_TYPE:
        if len(args) != 3:
            raise AssemblyError(f"{mnemonic} expects rd, rs1, immediate")
        rd, rs1 = register(args[0]), register(args[1])
        imm = signed_field(immediate(args[2]), 12, "immediate")
        return (imm << 20) | (rs1 << 15) | (I_TYPE[mnemonic] << 12) | (rd << 7) | 0x13

    if mnemonic in {"slli", "srli", "srai"}:
        if len(args) != 3:
            raise AssemblyError(f"{mnemonic} expects rd, rs1, shamt")
        rd, rs1 = register(args[0]), register(args[1])
        shamt = unsigned_field(immediate(args[2]), 5, "shift amount")
        funct3 = 0b001 if mnemonic == "slli" else 0b101
        funct7 = 0b0100000 if mnemonic == "srai" else 0
        return (funct7 << 25) | (shamt << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | 0x13

    load_types = {
        "lb": 0b000,
        "lh": 0b001,
        "lw": 0b010,
        "lbu": 0b100,
        "lhu": 0b101,
    }
    if mnemonic in load_types:
        if len(args) != 3:
            raise AssemblyError(f"{mnemonic} expects rd, offset(rs1)")
        rd = register(args[0])
        imm = signed_field(immediate(args[1]), 12, "load offset")
        rs1 = register(args[2])
        funct3 = load_types[mnemonic]
        return (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | 0x03

    store_types = {"sb": 0b000, "sh": 0b001, "sw": 0b010}
    if mnemonic in store_types:
        if len(args) != 3:
            raise AssemblyError(f"{mnemonic} expects rs2, offset(rs1)")
        rs2 = register(args[0])
        imm = signed_field(immediate(args[1]), 12, "store offset")
        rs1 = register(args[2])
        funct3 = store_types[mnemonic]
        return ((imm >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | ((imm & 0x1F) << 7) | 0x23

    if mnemonic in BRANCH_TYPE:
        if len(args) != 3:
            raise AssemblyError(f"{mnemonic} expects rs1, rs2, target")
        rs1, rs2 = register(args[0]), register(args[1])
        imm = signed_field(branch_offset(args[2], labels, pc), 13, "branch offset")
        funct3 = BRANCH_TYPE[mnemonic]
        return (((imm >> 12) & 1) << 31) | (((imm >> 5) & 0x3F) << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (((imm >> 1) & 0xF) << 8) | (((imm >> 11) & 1) << 7) | 0x63

    if mnemonic in {"lui", "auipc"}:
        if len(args) != 2:
            raise AssemblyError(f"{mnemonic} expects rd, immediate20")
        rd = register(args[0])
        imm20 = unsigned_field(immediate(args[1]), 20, "upper immediate")
        opcode = 0x37 if mnemonic == "lui" else 0x17
        return (imm20 << 12) | (rd << 7) | opcode

    if mnemonic == "jal":
        if len(args) != 2:
            raise AssemblyError("jal expects rd, target")
        rd = register(args[0])
        imm = signed_field(branch_offset(args[1], labels, pc), 21, "jump offset")
        return (((imm >> 20) & 1) << 31) | (((imm >> 1) & 0x3FF) << 21) | (((imm >> 11) & 1) << 20) | (((imm >> 12) & 0xFF) << 12) | (rd << 7) | 0x6F

    raise AssemblyError(f"unsupported instruction: {mnemonic}")


def assemble(path: Path) -> str:
    statements, labels = read_source(path)
    words: list[str] = []
    for line_number, tokens, pc in statements:
        try:
            words.append(f"{encode(tokens, labels, pc):08x}")
        except AssemblyError as exc:
            raise AssemblyError(f"{path}:{line_number}: {exc}") from exc
    return "\n".join(words) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--check", action="store_true", help="fail if output is not current")
    args = parser.parse_args()

    try:
        rendered = assemble(args.source)
    except (AssemblyError, OSError) as exc:
        print(exc, file=sys.stderr)
        return 1

    if args.check:
        try:
            current = args.output.read_text(encoding="utf-8")
        except OSError as exc:
            print(exc, file=sys.stderr)
            return 1
        if current != rendered:
            print(f"stale generated program: {args.output}", file=sys.stderr)
            return 1
        return 0

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(rendered, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
