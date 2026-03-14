#!/usr/bin/env bash
set -euo pipefail

# Codex exec driver for cross-model review
# Unified driver interface: --prompt --schema --output --repo-root --timeout

die() { printf '[driver:codex] error: %s\n' "$*" >&2; exit 1; }

PROMPT=""
SCHEMA=""
OUTPUT=""
REPO_ROOT=""
TIMEOUT=3600

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prompt) PROMPT="$2"; shift 2 ;;
    --schema) SCHEMA="$2"; shift 2 ;;
    --output) OUTPUT="$2"; shift 2 ;;
    --repo-root) REPO_ROOT="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ -n "$PROMPT" ]] || die "--prompt is required"
[[ -n "$SCHEMA" ]] || die "--schema is required"
[[ -n "$OUTPUT" ]] || die "--output is required"
[[ -n "$REPO_ROOT" ]] || die "--repo-root is required"
[[ -f "$PROMPT" ]] || die "prompt file not found: $PROMPT"
[[ -f "$SCHEMA" ]] || die "schema file not found: $SCHEMA"

command -v codex >/dev/null 2>&1 || die "codex CLI not found"

timeout "${TIMEOUT}s" codex exec \
  -C "$REPO_ROOT" \
  -s read-only \
  --ephemeral \
  --output-schema "$SCHEMA" \
  -o "$OUTPUT" \
  - < "$PROMPT" >/dev/null
