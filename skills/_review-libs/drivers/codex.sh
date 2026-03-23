#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "--probe" ]]; then
  command -v codex >/dev/null 2>&1
  exit $?
fi

die() { printf '[driver:codex] error: %s\n' "$*" >&2; exit 1; }

PROMPT=""
SCHEMA=""
OUTPUT=""
REPO_ROOT=""
TIMEOUT=1800

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prompt)  [[ $# -ge 2 ]] || die "--prompt requires a value"; PROMPT="$2"; shift 2 ;;
    --schema)  [[ $# -ge 2 ]] || die "--schema requires a value"; SCHEMA="$2"; shift 2 ;;
    --output)  [[ $# -ge 2 ]] || die "--output requires a value"; OUTPUT="$2"; shift 2 ;;
    --repo-root) [[ $# -ge 2 ]] || die "--repo-root requires a value"; REPO_ROOT="$2"; shift 2 ;;
    --timeout) [[ $# -ge 2 ]] || die "--timeout requires a value"; TIMEOUT="$2"; shift 2 ;;
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
command -v jq >/dev/null 2>&1 || die "jq is required"

codex_exit=0
timeout "${TIMEOUT}s" codex exec \
  -C "$REPO_ROOT" \
  -m gpt-5.4 \
  -s read-only \
  -c 'model_reasoning_effort="medium"' \
  --ephemeral \
  --skip-git-repo-check \
  --output-schema "$SCHEMA" \
  -o "$OUTPUT" \
  - < "$PROMPT" >/dev/null || codex_exit=$?

if [[ $codex_exit -eq 124 ]]; then
  die "codex timed out after ${TIMEOUT}s"
elif [[ $codex_exit -ne 0 ]]; then
  die "codex exited with code $codex_exit"
fi
