#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
cd "$repository_root"

echo "Checking the Codespaces HDL toolchain..."
make setup-check

echo "Running the post-create smoke test..."
make build test-unit

echo "Codespace ready. Run 'make help' or a VS Code task for HDL and ChipInventor infrastructure commands."
