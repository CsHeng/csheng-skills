#!/usr/bin/env bash
set -euo pipefail

# PostToolUse(Edit) dispatcher: run language-specific checks after file edits.
# Invoked by Claude Code hook with CLAUDE_FILE set to the edited file path.

FILE="${CLAUDE_FILE:-}"
if [[ -z "$FILE" || ! -f "$FILE" ]]; then
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$FILE" in
  *.py)   bash "$SCRIPT_DIR/checkers/python.sh" "$FILE" ;;
  *.go)   bash "$SCRIPT_DIR/checkers/go.sh" "$FILE" ;;
  *.sh)   bash "$SCRIPT_DIR/checkers/shell.sh" "$FILE" ;;
  *.lua)  bash "$SCRIPT_DIR/checkers/lua.sh" "$FILE" ;;
  *.puml) bash "$SCRIPT_DIR/checkers/plantuml.sh" "$FILE" ;;
  *)      exit 0 ;;
esac
