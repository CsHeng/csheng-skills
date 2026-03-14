#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  skills/review-impl/scripts/run-review.sh --host <claude|codex> [options]

Options:
  --host <claude|codex>              Current orchestrator host. Required.
  --repo-root <path>                 Review target repository root. Defaults to current git root or cwd.
  --plan <path>                      Optional plan baseline path.
  --file <path>                      File to review (repeatable). If omitted, use git scope.
  --reviewer <claude|codex>          Override reviewer CLI. Must differ from host unless fallback allowed.
  --allow-same-model-fallback        Allow same-tool fallback when opposite CLI is unavailable.
  --timeout <seconds>                Reviewer timeout. Default: 3600.
  --output <path>                    Write normalized JSON output to path instead of stdout.
  -h, --help                         Show this help.
USAGE
}

log() { printf '[review-impl] %s\n' "$*" >&2; }
die() {
  local code=1
  if [[ "$1" =~ ^[0-9]+$ ]]; then code="$1"; shift; fi
  printf '[review-impl] error: %s\n' "$*" >&2
  exit "$code"
}
require_cmd() { command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"; }

# Semantic exit codes
EXIT_OK=0
EXIT_REVIEWER_UNAVAILABLE=10
EXIT_REVIEWER_FAILED=11
EXIT_SCHEMA_VALIDATION_FAILED=12
EXIT_INPUT_NOT_FOUND=13

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PLUGIN_ROOT="$(cd -- "$SKILL_ROOT/../.." && pwd)"
SCHEMA_PATH="$PLUGIN_ROOT/docs/schemas/adversarial-reviewer-output.schema.json"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HOST=""
REVIEWER="auto"
ALLOW_FALLBACK=0
TIMEOUT_SECONDS=3600
PLAN_PATH=""
OUTPUT_PATH=""
IMPL_FILES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="$2"; shift 2 ;;
    --repo-root) REPO_ROOT="$2"; shift 2 ;;
    --plan) PLAN_PATH="$2"; shift 2 ;;
    --file) IMPL_FILES+=("$2"); shift 2 ;;
    --reviewer) REVIEWER="$2"; shift 2 ;;
    --allow-same-model-fallback) ALLOW_FALLBACK=1; shift ;;
    --timeout) TIMEOUT_SECONDS="$2"; shift 2 ;;
    --output) OUTPUT_PATH="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

case "$HOST" in claude|codex) ;; *) die "--host must be claude or codex" ;; esac
[[ -f "$SCHEMA_PATH" ]] || die $EXIT_INPUT_NOT_FOUND "schema file not found: $SCHEMA_PATH"
require_cmd jq
require_cmd timeout

normalize_output() {
  local output_file="$1"
  local normalized_file="${output_file}.normalized"
  if jq -e . "$output_file" >/dev/null 2>&1; then return; fi
  sed -e '1{/^```[[:alpha:]]*$/d;}' -e '${/^```$/d;}' "$output_file" > "$normalized_file"
  if jq -e . "$normalized_file" >/dev/null 2>&1; then mv "$normalized_file" "$output_file"; return; fi
  rm -f "$normalized_file"
  die "reviewer output is not valid JSON: $output_file"
}

validate_output() {
  local output_file="$1"
  jq -e . "$output_file" >/dev/null
  jq -e '
    def nonempty: type == "string" and length > 0;
    type == "object"
    and (.lens | nonempty)
    and (.verdict == "PASS" or .verdict == "FAIL")
    and (.summary | nonempty)
    and (.pass_rationale | type == "string")
    and (.findings | type == "array")
    and (all(.findings[]?;
      type == "object"
      and (.severity == "Critical" or .severity == "Important" or .severity == "Minor")
      and (.location | nonempty)
      and (.evidence | nonempty)
      and (.impact | nonempty)
      and (.fix | nonempty)
      and (.confidence == "high" or .confidence == "medium" or .confidence == "low")
    ))
  ' "$output_file" >/dev/null
}

pick_reviewer() {
  if [[ "$REVIEWER" != "auto" ]]; then printf '%s\n' "$REVIEWER"; return; fi
  if [[ "$HOST" == "claude" ]] && command -v codex >/dev/null 2>&1; then printf 'codex\n'; return; fi
  if [[ "$HOST" == "codex" ]] && command -v claude >/dev/null 2>&1; then printf 'claude\n'; return; fi
  if [[ "$ALLOW_FALLBACK" -eq 1 ]] && command -v "$HOST" >/dev/null 2>&1; then printf '%s\n' "$HOST"; return; fi
  die $EXIT_REVIEWER_UNAVAILABLE "opposite reviewer CLI unavailable for host=$HOST"
}

run_claude() {
  local prompt_file="$1"
  local output_file="$2"
  require_cmd claude
  timeout "$TIMEOUT_SECONDS"s claude -p --tools "Read,Grep,Bash" --json-schema "$(cat "$SCHEMA_PATH")" < "$prompt_file" > "$output_file"
}

run_codex() {
  local prompt_file="$1"
  local output_file="$2"
  require_cmd codex
  timeout "$TIMEOUT_SECONDS"s codex exec -C "$REPO_ROOT" -s read-only --ephemeral --output-schema "$SCHEMA_PATH" -o "$output_file" - < "$prompt_file" >/dev/null
}

main() {
  local reviewer
  reviewer="$(pick_reviewer)"
  [[ "$reviewer" != "$HOST" || "$ALLOW_FALLBACK" -eq 1 ]] || die "same-tool reviewer selected without fallback"

  local resolved_plan=""
  if [[ -n "$PLAN_PATH" ]]; then
    local candidate_path=""
    if [[ -f "$PLAN_PATH" ]]; then
      candidate_path="$PLAN_PATH"
    elif [[ -f "$REPO_ROOT/$PLAN_PATH" ]]; then
      candidate_path="$REPO_ROOT/$PLAN_PATH"
    else
      die $EXIT_INPUT_NOT_FOUND "plan file not found: $PLAN_PATH"
    fi

    # Resolve to canonical path
    resolved_plan="$(realpath "$candidate_path" 2>/dev/null)" || die $EXIT_INPUT_NOT_FOUND "failed to resolve plan path: $candidate_path"

    # Reject control characters
    if printf '%s' "$resolved_plan" | grep -q '[[:cntrl:]]'; then
      die $EXIT_INPUT_NOT_FOUND "plan path contains control characters: $PLAN_PATH"
    fi

    # Enforce containment inside repo root or plugin root
    local allowed_roots=("$REPO_ROOT")
    if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
      allowed_roots+=("$(realpath "$CLAUDE_PLUGIN_ROOT" 2>/dev/null || printf '%s' "$CLAUDE_PLUGIN_ROOT")")
    fi

    local contained=0
    for root in "${allowed_roots[@]}"; do
      if [[ "$resolved_plan" == "$root"/* || "$resolved_plan" == "$root" ]]; then
        contained=1
        break
      fi
    done
    [[ "$contained" -eq 1 ]] || die $EXIT_INPUT_NOT_FOUND "plan path outside allowed roots: $resolved_plan"
  fi

  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  local prompt_file="$TMP_DIR/review.prompt"
  local output_file="$TMP_DIR/review.json"
  {
    printf '%s\n' 'You are the enforced reviewer CLI for a cross-tool implementation review.'
    if [[ ${#IMPL_FILES[@]} -gt 0 ]]; then
      printf '%s\n' 'Review these files using correctness, security, testing, and production-readiness concerns:'
      printf -- '- %s\n' "${IMPL_FILES[@]}"
    else
      printf '%s\n' 'Review the current git change scope using correctness, security, testing, and production-readiness concerns.'
      printf '%s\n' 'Use git status and git diff to determine scope.'
    fi
    if [[ -n "$resolved_plan" ]]; then
      printf 'Use "%s" as the spec baseline when checking implementation compliance.\n' "$resolved_plan"
    fi
    cat <<'EOF2'
Return JSON only and match this shape exactly:
{
  "lens": string,
  "verdict": "PASS" | "FAIL",
  "summary": string,
  "findings": [
    {
      "severity": "Critical" | "Important" | "Minor",
      "location": string,
      "evidence": string,
      "impact": string,
      "fix": string,
      "confidence": "high" | "medium" | "low"
    }
  ],
  "pass_rationale": string
}
Populate every finding with evidence, impact, fix, and confidence.
Only mark FAIL for issues explicitly present in the reviewed files or git scope as written.
Do not mark FAIL for hypothetical misuse by an external orchestrator that is not described here.
Do not treat fixed literal example paths or placeholder prompt text as untrusted input interpolation.
If there are no Critical or Important issues, return PASS and a non-empty pass_rationale.
EOF2
  } > "$prompt_file"

  log "step=config plugin_root=$PLUGIN_ROOT repo_root=$REPO_ROOT host=$HOST reviewer=$reviewer"
  log "step=invoke_reviewer reviewer=$reviewer"
  local reviewer_rc=0
  case "$reviewer" in
    claude) run_claude "$prompt_file" "$output_file" || reviewer_rc=$? ;;
    codex) run_codex "$prompt_file" "$output_file" || reviewer_rc=$? ;;
  esac
  if [[ "$reviewer_rc" -ne 0 ]]; then
    die $EXIT_REVIEWER_FAILED "reviewer=$reviewer exited with code=$reviewer_rc"
  fi
  normalize_output "$output_file" || die $EXIT_SCHEMA_VALIDATION_FAILED "reviewer output normalization failed"
  validate_output "$output_file" || die $EXIT_SCHEMA_VALIDATION_FAILED "reviewer output schema validation failed"
  [[ -n "$OUTPUT_PATH" ]] && cp "$output_file" "$OUTPUT_PATH"
  cat "$output_file"
}

main
