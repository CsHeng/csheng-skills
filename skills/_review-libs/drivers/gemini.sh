#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "--probe" ]]; then
  command -v gemini >/dev/null 2>&1
  exit $?
fi

die() { printf '[driver:gemini] error: %s\n' "$*" >&2; exit 1; }

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

command -v gemini >/dev/null 2>&1 || die "gemini CLI not found"
command -v jq >/dev/null 2>&1 || die "jq is required"
command -v file >/dev/null 2>&1 || die "file command is required"

# Build augmented prompt:
# - gemini has no native --json-schema support → append schema as text
# - gemini headless mode blocks file-reading tools (LocalAgentExecutor,
#   confirmed as known issue: github.com/google-gemini/gemini-cli#16012)
# - workaround: extract file paths referenced in the prompt and inline their
#   contents; the workspace is an isolated temp dir with only review targets,
#   so the total size stays bounded
AUGMENTED_PROMPT="$(mktemp)"
RAW_OUTPUT="$(mktemp)"
trap 'rm -f "$AUGMENTED_PROMPT" "$RAW_OUTPUT"' EXIT

# Collect referenced file paths from prompt:
#   - design/plan mode: 'Review the (design document|plan) at "relpath"'
#   - code-impl mode:   '- relpath' list items (supports paths with spaces)
#   - spec baseline:    'Use "relpath" as the spec baseline'
mapfile -t referenced_files < <(
  grep -oP '(?<=at ")[^"]+|(?<=^- ).+|(?<=Use ")[^"]+(?=" as the spec baseline)' "$PROMPT" | sort -u
)

RESOLVED_REPO_ROOT="$(realpath "$REPO_ROOT")"

{
  cat "$PROMPT"

  # Inline referenced files so gemini can review without tool access
  if [[ ${#referenced_files[@]} -gt 0 ]]; then
    printf '\n\n--- REFERENCED FILES (inline) ---\n'
    for rel in "${referenced_files[@]}"; do
      fpath="$REPO_ROOT/$rel"
      if [[ ! -f "$fpath" ]]; then
        printf '\n=== FILE: %s ===\n[not found in workspace]\n' "$rel"
        continue
      fi
      # Path traversal guard: resolved path must stay inside REPO_ROOT
      resolved="$(realpath "$fpath" 2>/dev/null)" || continue
      if [[ "$resolved" != "$RESOLVED_REPO_ROOT"/* ]]; then
        printf '\n=== FILE: %s ===\n[path outside workspace, skipped]\n' "$rel"
        continue
      fi
      if file -b --mime-encoding "$fpath" 2>/dev/null | grep -q binary; then
        printf '\n=== FILE: %s ===\n[binary file skipped]\n' "$rel"
        continue
      fi
      printf '\n=== FILE: %s ===\n' "$rel"
      cat "$fpath"
    done
    printf '\n--- END REFERENCED FILES ---\n'
  fi

  printf '\n\nReturn JSON only matching this schema:\n'
  cat "$SCHEMA"
} > "$AUGMENTED_PROMPT"

# Prompt delivery: stdin carries the bulk content, -p triggers headless mode.
# gemini docs: "-p/--prompt … Appended to input on stdin (if any)."
# --approval-mode yolo: auto-approve all tools; enables sandbox by default (per docs).
#   plan mode blocks read_file/glob in headless mode despite docs listing them as allowed.
# --include-directories: bind the isolated workspace so gemini can read review targets.
gemini_exit=0
timeout "${TIMEOUT}s" gemini \
  --approval-mode yolo \
  --model gemini-3.1-pro-preview \
  --output-format json \
  --include-directories "$REPO_ROOT" \
  -p "" \
  < "$AUGMENTED_PROMPT" \
  > "$RAW_OUTPUT" || gemini_exit=$?

if [[ $gemini_exit -eq 124 ]]; then
  die "gemini timed out after ${TIMEOUT}s"
elif [[ $gemini_exit -ne 0 ]]; then
  die "gemini exited with code $gemini_exit"
fi

# Extract reviewer JSON from gemini CLI envelope
# gemini --output-format json wraps output in {"response": "..."}
# Handle multiple envelope shapes with fallbacks (mirrors claude driver)
raw_type="$(jq -r 'type' "$RAW_OUTPUT" 2>/dev/null || printf 'invalid')"
case "$raw_type" in
  object)
    if jq -e 'has("response") and (.response | type) == "string" and (.response | length) > 0' "$RAW_OUTPUT" >/dev/null 2>&1; then
      # Standard envelope: {"response": "<json-string>"}
      extracted="$(jq -r '.response' "$RAW_OUTPUT")"
      if printf '%s' "$extracted" | jq -e . >/dev/null 2>&1; then
        printf '%s' "$extracted" | jq -c '.' > "$OUTPUT"
      else
        # .response is non-empty string but not valid JSON — try stripping markdown fences
        stripped="$(printf '%s' "$extracted" | sed -e '1{/^```[[:alpha:]]*[[:space:]]*$/d;}' -e '${/^```[[:space:]]*$/d;}')"
        if printf '%s' "$stripped" | jq -e . >/dev/null 2>&1; then
          printf '%s' "$stripped" | jq -c '.' > "$OUTPUT"
        else
          die "gemini .response is not valid JSON"
        fi
      fi
    elif jq -e 'has("response") and (.response | type) == "object"' "$RAW_OUTPUT" >/dev/null 2>&1; then
      # Object envelope: {"response": {...}}
      jq -c '.response' "$RAW_OUTPUT" > "$OUTPUT"
    elif jq -e 'has("lens") and has("verdict")' "$RAW_OUTPUT" >/dev/null 2>&1; then
      # Raw reviewer JSON without envelope
      jq -c '.' "$RAW_OUTPUT" > "$OUTPUT"
    else
      die "gemini output did not contain expected reviewer JSON"
    fi
    ;;
  string)
    # Bare JSON string — parse inner content
    inner="$(jq -r '.' "$RAW_OUTPUT")"
    if printf '%s' "$inner" | jq -e . >/dev/null 2>&1; then
      printf '%s' "$inner" | jq -c '.' > "$OUTPUT"
    else
      die "gemini output string is not valid JSON"
    fi
    ;;
  *)
    die "gemini output is not valid JSON (type=$raw_type)"
    ;;
esac

# Schema validation: verify required reviewer fields are present and well-typed.
# claude/codex drivers get this via native --json-schema / --output-schema;
# gemini has no equivalent, so we validate post-extraction.
if ! jq -e 'has("lens") and has("verdict") and has("findings") and (.findings | type) == "array"' "$OUTPUT" >/dev/null 2>&1; then
  die "gemini output missing required reviewer fields (lens, verdict, findings[])"
fi
