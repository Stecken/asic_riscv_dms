#!/usr/bin/env bash
set -euo pipefail

required_commands=(iverilog vvp verilator yosys dot make git python3)
missing=0

for command_name in "${required_commands[@]}"; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "ERROR: required command not found: $command_name" >&2
        missing=1
    fi
done

if ! python3 -m pip --version >/dev/null 2>&1; then
    echo "ERROR: Python pip module is unavailable" >&2
    missing=1
fi

if (( missing != 0 )); then
    echo "Use the GitHub Codespaces/devcontainer environment or install the missing tools." >&2
    exit 1
fi

echo "Tool versions:"
iverilog -V 2>&1 | sed -n '1p'
vvp -V 2>&1 | sed -n '1p'
verilator --version
yosys -V
dot -V 2>&1
make --version | sed -n '1p'
git --version
python3 --version
python3 -m pip --version

python3 scripts/check_sources.py
echo "PASS setup-check"
