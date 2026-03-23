#!/usr/bin/env bash
set -euo pipefail

FILE="$1"
DIR="$(dirname "$FILE")"

# Check if we're in a Go module
if [[ -f "$DIR/go.mod" ]] || git -C "$DIR" rev-parse --show-toplevel >/dev/null 2>&1; then
  MODULE_ROOT="$(cd "$DIR" && while [[ ! -f go.mod && "$PWD" != "/" ]]; do cd ..; done && pwd)"
  if [[ -f "$MODULE_ROOT/go.mod" ]]; then
    cd "$MODULE_ROOT"
    go vet "./$(realpath --relative-to="$MODULE_ROOT" "$DIR")/..." 2>&1 | head -30 || true
    return 2>/dev/null || exit 0
  fi
fi

# Standalone file: basic syntax check
go vet "$FILE" 2>&1 | head -20 || true
