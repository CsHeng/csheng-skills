#!/usr/bin/env bash
set -euo pipefail

FILE="$1"

# Detect interpreter from shebang
INTERP="bash"
if head -1 "$FILE" | grep -q "zsh"; then
  INTERP="zsh"
elif head -1 "$FILE" | grep -q "bin/sh"; then
  INTERP="sh"
fi

# Syntax check
"$INTERP" -n "$FILE" 2>&1 | head -20 || true

# ShellCheck (if available)
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "$FILE" 2>&1 | head -30 || true
fi
