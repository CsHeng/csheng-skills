#!/usr/bin/env bash
set -euo pipefail

FILE="$1"

# Syntax check with luac
if command -v luac >/dev/null 2>&1; then
  luac -p "$FILE" 2>&1 | head -20 || true
fi
