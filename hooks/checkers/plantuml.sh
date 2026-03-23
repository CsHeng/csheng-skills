#!/usr/bin/env bash
set -euo pipefail

FILE="$1"

# Syntax check with plantuml
if command -v plantuml >/dev/null 2>&1; then
  plantuml --check-syntax "$FILE" 2>&1 | head -20 || true
fi
