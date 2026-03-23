#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "--probe" ]]; then
  command -v claude >/dev/null 2>&1
  exit $?
fi

die() { printf '[driver:claude] error: %s\n' "$*" >&2; exit 1; }

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

command -v claude >/dev/null 2>&1 || die "claude CLI not found"
command -v jq >/dev/null 2>&1 || die "jq is required"

RAW_OUTPUT="$(mktemp)"
trap 'rm -f "$RAW_OUTPUT"' EXIT

claude_exit=0
timeout "${TIMEOUT}s" claude -p \
  --add-dir "$REPO_ROOT" \
  --model claude-opus-4-6 \
  --tools "Read,Glob,Grep" \
  --output-format json \
  --permission-mode dontAsk \
  --json-schema "$(cat "$SCHEMA")" \
  < "$PROMPT" > "$RAW_OUTPUT" || claude_exit=$?

if [[ $claude_exit -eq 124 ]]; then
  die "claude timed out after ${TIMEOUT}s"
elif [[ $claude_exit -ne 0 ]]; then
  die "claude exited with code $claude_exit"
fi

raw_type="$(jq -r 'type' "$RAW_OUTPUT" 2>/dev/null || printf 'invalid')"
case "$raw_type" in
  object)
    if jq -e 'has("structured_output") and .structured_output != null' "$RAW_OUTPUT" >/dev/null 2>&1; then
      jq -c '.structured_output' "$RAW_OUTPUT" > "$OUTPUT"
    elif jq -e 'has("result") and (.result | type) == "string" and (.result | length) > 0' "$RAW_OUTPUT" >/dev/null 2>&1; then
      # .result may be raw JSON text or text containing JSON; write as-is
      # and let run-review.sh's normalize_output / validate_reviewer_output handle it
      jq -r '.result' "$RAW_OUTPUT" > "$OUTPUT"
    else
      jq -c '.' "$RAW_OUTPUT" > "$OUTPUT"
    fi
    ;;
  string)
    jq -r '.' "$RAW_OUTPUT" > "$OUTPUT"
    ;;
  *)
    die "claude output did not contain structured JSON"
    ;;
esac
