#!/usr/bin/env bash
set -euo pipefail

wave_file="${1:-waves/core_basic.vcd}"
if [[ ! -f "$wave_file" ]]; then
    echo "ERROR: waveform does not exist: $wave_file" >&2
    echo "Run: make wave TEST=core_basic" >&2
    exit 1
fi

if command -v code >/dev/null 2>&1 && code --reuse-window "$wave_file" >/dev/null 2>&1; then
    echo "Opened $wave_file in VS Code. Select the Surfer editor if VS Code asks."
else
    echo "Waveform: $wave_file"
    echo "The VS Code CLI is unavailable in this shell. In Codespaces, open this file from Explorer with Surfer."
fi
