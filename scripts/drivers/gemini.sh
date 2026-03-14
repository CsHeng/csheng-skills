#!/usr/bin/env bash
set -euo pipefail

# Gemini CLI driver for cross-model review
# Unified driver interface: --prompt --schema --output --repo-root --timeout
# NOTE: Gemini CLI structured output support is preliminary.
# The --output-format json flag produces plain JSON but does not enforce a schema.
# Output normalization and schema validation are handled by the caller (run-review.sh).

die() { printf '[driver:gemini] error: %s\n' "$*" >&2; exit 1; }

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
[[ -f "$PROMPT" ]] || die "prompt file not found: $PROMPT"
[[ -f "$SCHEMA" ]] || die "schema file not found: $SCHEMA"

command -v gemini >/dev/null 2>&1 || die "gemini CLI not found"

# Append schema instructions to prompt so gemini knows the expected shape
AUGMENTED_PROMPT="$(mktemp)"
trap 'rm -f "$AUGMENTED_PROMPT"' EXIT
{
  cat "$PROMPT"
  printf '\n\nReturn JSON only matching this schema:\n'
  cat "$SCHEMA"
} > "$AUGMENTED_PROMPT"

timeout "${TIMEOUT}s" gemini -p \
  --output-format json \
  --no-history \
  < "$AUGMENTED_PROMPT" > "$OUTPUT"
