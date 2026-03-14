#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/run-review.sh --mode <plan|impl> --host <host> [options]

Options:
  --mode <plan|impl>                 Review mode. Required.
  --host <host>                      Current orchestrator host (e.g. claude, codex). Required.
  --plan <path>                      Plan path. Required for plan mode, optional for impl mode.
  --file <path>                      File to review (repeatable, impl mode only). If omitted, use git scope.
  --repo-root <path>                 Review target repository root. Defaults to current git root or cwd.
  --reviewer <name>                  Override reviewer driver. Must differ from host unless fallback allowed.
  --allow-same-model-fallback        Allow same-driver fallback when opposite driver is unavailable.
  --timeout <seconds>                Reviewer timeout. Default: 3600.
  --output <path>                    Write normalized JSON output to path instead of stdout.
  -h, --help                         Show this help.
USAGE
}

log() { printf '[run-review] %s\n' "$*" >&2; }
die() {
  local code=1
  if [[ "$1" =~ ^[0-9]+$ ]]; then code="$1"; shift; fi
  printf '[run-review] error: %s\n' "$*" >&2
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
PLUGIN_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
SCHEMA_PATH="$PLUGIN_ROOT/docs/schemas/adversarial-reviewer-output.schema.json"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
MODE=""
HOST=""
REVIEWER="auto"
ALLOW_FALLBACK=0
TIMEOUT_SECONDS=3600
PLAN_PATH=""
OUTPUT_PATH=""
IMPL_FILES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;
    --host) HOST="$2"; shift 2 ;;
    --plan) PLAN_PATH="$2"; shift 2 ;;
    --file) IMPL_FILES+=("$2"); shift 2 ;;
    --repo-root) REPO_ROOT="$2"; shift 2 ;;
    --reviewer) REVIEWER="$2"; shift 2 ;;
    --allow-same-model-fallback) ALLOW_FALLBACK=1; shift ;;
    --timeout) TIMEOUT_SECONDS="$2"; shift 2 ;;
    --output) OUTPUT_PATH="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

case "$MODE" in plan|impl) ;; *) die "--mode must be plan or impl" ;; esac
[[ -n "$HOST" ]] || die "--host is required"
[[ -f "$SCHEMA_PATH" ]] || die $EXIT_INPUT_NOT_FOUND "schema file not found: $SCHEMA_PATH"
require_cmd jq
require_cmd timeout

if [[ "$MODE" == "plan" && -z "$PLAN_PATH" ]]; then
  die "--plan is required for plan mode"
fi

normalize_output() {
  local output_file="$1"
  local normalized_file="${output_file}.normalized"
  if jq -e . "$output_file" >/dev/null 2>&1; then return; fi
  sed -e '1{/^```[[:alpha:]]*$/d;}' -e '${/^```$/d;}' "$output_file" > "$normalized_file"
  if jq -e . "$normalized_file" >/dev/null 2>&1; then mv "$normalized_file" "$output_file"; return; fi
  rm -f "$normalized_file"
  die $EXIT_SCHEMA_VALIDATION_FAILED "reviewer output is not valid JSON: $output_file"
}

validate_output() {
  local output_file="$1"
  jq -e . "$output_file" >/dev/null || return 1
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
  ' "$output_file" >/dev/null || return 1
}

pick_reviewer() {
  local driver_dir="$SCRIPT_DIR/drivers"
  if [[ "$REVIEWER" != "auto" ]]; then
    [[ -f "$driver_dir/${REVIEWER}.sh" ]] || die $EXIT_REVIEWER_UNAVAILABLE "no driver found: $REVIEWER"
    printf '%s\n' "$REVIEWER"
    return
  fi
  # Try known opposites first
  local opposite=""
  case "$HOST" in
    claude) opposite="codex" ;;
    codex) opposite="claude" ;;
  esac
  if [[ -n "$opposite" ]] && [[ -f "$driver_dir/${opposite}.sh" ]]; then
    printf '%s\n' "$opposite"
    return
  fi
  # Try any available driver that is not the host
  for driver in "$driver_dir"/*.sh; do
    [[ -f "$driver" ]] || continue
    local name
    name="$(basename "$driver" .sh)"
    if [[ "$name" != "$HOST" ]]; then
      printf '%s\n' "$name"
      return
    fi
  done
  # Fallback to same driver
  if [[ "$ALLOW_FALLBACK" -eq 1 ]] && [[ -f "$driver_dir/${HOST}.sh" ]]; then
    printf '%s\n' "$HOST"
    return
  fi
  die $EXIT_REVIEWER_UNAVAILABLE "no opposite reviewer driver available for host=$HOST"
}

run_reviewer() {
  local reviewer="$1" prompt_file="$2" output_file="$3"
  local driver_dir="$SCRIPT_DIR/drivers"
  local driver="$driver_dir/${reviewer}.sh"
  [[ -f "$driver" ]] || die $EXIT_REVIEWER_UNAVAILABLE "no driver found: $driver"
  bash "$driver" \
    --prompt "$prompt_file" \
    --schema "$SCHEMA_PATH" \
    --output "$output_file" \
    --repo-root "$REPO_ROOT" \
    --timeout "$TIMEOUT_SECONDS"
}

resolve_plan_path() {
  local candidate_path=""
  if [[ -f "$PLAN_PATH" ]]; then
    candidate_path="$PLAN_PATH"
  elif [[ -f "$REPO_ROOT/$PLAN_PATH" ]]; then
    candidate_path="$REPO_ROOT/$PLAN_PATH"
  else
    die $EXIT_INPUT_NOT_FOUND "plan file not found: $PLAN_PATH"
  fi

  local resolved
  resolved="$(realpath "$candidate_path" 2>/dev/null)" || die $EXIT_INPUT_NOT_FOUND "failed to resolve plan path: $candidate_path"

  if printf '%s' "$resolved" | grep -q '[[:cntrl:]]'; then
    die $EXIT_INPUT_NOT_FOUND "plan path contains control characters: $PLAN_PATH"
  fi

  local allowed_roots=("$REPO_ROOT")
  if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    allowed_roots+=("$(realpath "$CLAUDE_PLUGIN_ROOT" 2>/dev/null || printf '%s' "$CLAUDE_PLUGIN_ROOT")")
  fi

  local contained=0
  for root in "${allowed_roots[@]}"; do
    if [[ "$resolved" == "$root"/* || "$resolved" == "$root" ]]; then
      contained=1
      break
    fi
  done
  [[ "$contained" -eq 1 ]] || die $EXIT_INPUT_NOT_FOUND "plan path outside allowed roots: $resolved"

  printf '%s' "$resolved"
}

make_plan_prompt() {
  local prompt_file="$1"
  local resolved_plan="$2"
  cat > "$prompt_file" <<EOF2
Review the plan at "$resolved_plan".
You are the enforced reviewer CLI for a cross-tool plan review.
Review the plan across these dimensions:
- requirements and risk
- architecture and dependencies
- test strategy and operations
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
Only mark FAIL for issues explicitly present in the plan as written.
Do not mark FAIL for hypothetical misuse by an external orchestrator that is not described here.
If there are no Critical or Important issues, return PASS and a non-empty pass_rationale.
EOF2
}

make_impl_prompt() {
  local prompt_file="$1"
  local resolved_plan="$2"
  shift 2
  local files=("$@")
  {
    printf '%s\n' 'You are the enforced reviewer CLI for a cross-tool implementation review.'
    if [[ ${#files[@]} -gt 0 ]]; then
      printf '%s\n' 'Review these files using correctness, security, testing, and production-readiness concerns:'
      printf -- '- %s\n' "${files[@]}"
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
}

main() {
  local reviewer
  reviewer="$(pick_reviewer)"
  [[ "$reviewer" != "$HOST" || "$ALLOW_FALLBACK" -eq 1 ]] || die "same-driver reviewer selected without fallback"

  local resolved_plan=""
  if [[ -n "$PLAN_PATH" ]]; then
    resolved_plan="$(resolve_plan_path)"
  fi

  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  local prompt_file="$TMP_DIR/review.prompt"
  local output_file="$TMP_DIR/review.json"

  case "$MODE" in
    plan) make_plan_prompt "$prompt_file" "$resolved_plan" ;;
    impl) make_impl_prompt "$prompt_file" "$resolved_plan" "${IMPL_FILES[@]}" ;;
  esac

  log "step=config mode=$MODE host=$HOST reviewer=$reviewer repo_root=$REPO_ROOT"
  log "step=prompt prompt_file=$prompt_file prompt_bytes=$(wc -c < "$prompt_file")"
  log "step=invoke_reviewer reviewer=$reviewer driver=scripts/drivers/${reviewer}.sh"
  local reviewer_rc=0
  run_reviewer "$reviewer" "$prompt_file" "$output_file" || reviewer_rc=$?
  log "step=reviewer_done reviewer=$reviewer exit_code=$reviewer_rc"
  if [[ "$reviewer_rc" -ne 0 ]]; then
    die $EXIT_REVIEWER_FAILED "reviewer=$reviewer exited with code=$reviewer_rc"
  fi
  log "step=normalize output_file=$output_file output_bytes=$(wc -c < "$output_file")"
  normalize_output "$output_file"
  if validate_output "$output_file"; then
    log "step=validate result=ok"
  else
    log "step=validate result=fail"
    die $EXIT_SCHEMA_VALIDATION_FAILED "reviewer output schema validation failed"
  fi
  [[ -n "$OUTPUT_PATH" ]] && cp "$output_file" "$OUTPUT_PATH"
  log "step=done verdict=$(jq -r '.verdict // "unknown"' "$output_file")"
  cat "$output_file"
}

main
