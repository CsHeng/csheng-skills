#!/usr/bin/env bash
set -euo pipefail

FILE="$1"

# Syntax check
PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile "$FILE" 2>&1 | head -20 || true

# Ruff check (if available)
if command -v ruff >/dev/null 2>&1; then
  ruff check "$FILE" 2>&1 | head -30 || true
fi
