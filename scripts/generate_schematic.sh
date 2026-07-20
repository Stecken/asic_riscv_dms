#!/usr/bin/env bash
set -euo pipefail

module_name="${1:-alu}"
if [[ ! "$module_name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    echo "ERROR: invalid module name: $module_name" >&2
    exit 2
fi

if ! python3 scripts/check_sources.py --top "$module_name" >/dev/null; then
    echo "ERROR: module is not an official RTL module: $module_name" >&2
    exit 2
fi

mkdir -p build/schematic build/logs reports
source_list="$(python3 scripts/check_sources.py --print)"
prefix="build/schematic/$module_name"
log_file="build/logs/schematic-$module_name.log"

yosys -ql "$log_file" -p "read_verilog -sv -D RISCV_DEBUG $source_list; hierarchy -check -top $module_name; proc; opt_clean; check; show -format dot -prefix $prefix $module_name"
dot -Tsvg "$prefix.dot" -o "$prefix.svg"

echo "Schematic: $prefix.svg"
echo "Yosys log: $log_file"
