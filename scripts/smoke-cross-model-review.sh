#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/smoke-cross-model-review.sh [plan|code-impl|design|all|eval] [options]

Options:
  --reviewer <auto|claude|codex>   Reviewer CLI to use. Default: auto
  --timeout <seconds>              Per-check timeout. Default: 1800
  --plan <path>                    Plan path for plan smoke test
  --design <path>                  Design path for design smoke test
  --code-impl-file <path>          File to include in code-impl smoke test (repeatable)
  -h, --help                       Show this help

Defaults:
  plan mode uses plans/2026-03-03-cross-model-review-skills.md
  design mode uses scripts/fixtures/sample-design.md
  code-impl mode uses commands/review-code-impl.md and skills/review-code-impl/SKILL.md

Notes:
  - This script tests the direct cross-model reviewer path, not `claude --agent`.
  - Wrapper output is validated against docs/schemas/review-run-output.schema.json.
USAGE
}

log() {
  printf '[smoke] %s\n' "$*"
}

die() {
  printf '[smoke] error: %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCHEMA_PATH="$ROOT_DIR/docs/schemas/review-run-output.schema.json"
MODE="all"
REVIEWER="auto"
TIMEOUT_SECONDS=1800
PLAN_PATH="plans/2026-03-03-cross-model-review-skills.md"
DESIGN_PATH="scripts/fixtures/sample-design.md"
CODE_IMPL_FILES=("commands/review-code-impl.md" "skills/review-code-impl/SKILL.md")

if [[ $# -gt 0 && ${1:-} != --* ]]; then
  MODE="$1"
  shift
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --reviewer)
      REVIEWER="$2"
      shift 2
      ;;
    --timeout)
      TIMEOUT_SECONDS="$2"
      shift 2
      ;;
    --plan)
      PLAN_PATH="$2"
      shift 2
      ;;
    --design)
      DESIGN_PATH="$2"
      shift 2
      ;;
    --code-impl-file)
      if [[ ${CODE_IMPL_FILES[0]:-} == "commands/review-code-impl.md" && ${#CODE_IMPL_FILES[@]} -eq 2 ]]; then
        CODE_IMPL_FILES=()
      fi
      CODE_IMPL_FILES+=("$2")
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

case "$MODE" in
  plan|code-impl|design|all|eval) ;;
  *) die "invalid mode: $MODE" ;;
esac

[[ -f "$SCHEMA_PATH" ]] || die "schema file not found: $SCHEMA_PATH"
require_cmd jq
require_cmd timeout

pick_reviewer() {
  if [[ "$REVIEWER" == "auto" ]]; then
    if command -v claude >/dev/null 2>&1; then
      printf 'claude\n'
      return
    fi
    if command -v codex >/dev/null 2>&1; then
      printf 'codex\n'
      return
    fi
    die "neither claude nor codex is available"
  fi

  if [[ "$REVIEWER" == "claude" ]]; then
    require_cmd claude
    printf 'claude\n'
    return
  fi

  if [[ "$REVIEWER" == "codex" ]]; then
    require_cmd codex
    printf 'codex\n'
    return
  fi

  die "invalid reviewer: $REVIEWER"
}

pick_host() {
  local reviewer="$1"
  case "$reviewer" in
    claude) printf 'codex\n' ;;
    codex) printf 'claude\n' ;;
    *) printf 'claude\n' ;;
  esac
}

validate_output() {
  local output_file="$1"

  jq -e . "$output_file" >/dev/null
  jq -e '
    def nonempty: type == "string" and length > 0;
    type == "object"
    and (.mode == "design" or .mode == "plan" or .mode == "code-impl")
    and (.host | nonempty)
    and (.reviewer | nonempty)
    and (.reviewer_model | nonempty)
    and (.review_mode == "cross-driver" or .review_mode == "same-driver")
    and (.status == "pass" or .status == "needs_fixes" or .status == "manual_review_required")
    and (.next_action == "stop_passed" or .next_action == "host_fix_then_rerun" or .next_action == "human_decision_required")
    and (.manual_intervention_required | type == "boolean")
    and (.batch | type == "number")
    and (.round | type == "number")
    and (.max_rounds | type == "number")
    and (.suggested_next_batch | type == "number")
    and (.suggested_next_round | type == "number")
    and (.blocking_findings | type == "array")
    and (.scope | type == "object")
    and (.scope.workspace_mode == "isolated")
    and (.scope.workspace_root | nonempty)
    and (.scope.spec_baseline == "design" or .scope.spec_baseline == "plan" or .scope.spec_baseline == "inferred")
    and (.scope.files | type == "array")
    and (.result | type == "object")
    and (.result.lens | nonempty)
    and (.result.verdict == "PASS" or .result.verdict == "FAIL")
    and (.result.summary | nonempty)
    and (.result.pass_rationale | type == "string")
    and (.result.findings | type == "array")
  ' "$output_file" >/dev/null
}

normalize_output() {
  local output_file="$1"
  local normalized_file
  normalized_file="${output_file}.normalized"

  if jq -e . "$output_file" >/dev/null 2>&1; then
    return
  fi

  # Strip markdown code fences and empty lines
  grep -v '^```' "$output_file" | grep -v '^[[:space:]]*$' > "$normalized_file"

  if jq -e . "$normalized_file" >/dev/null 2>&1; then
    mv "$normalized_file" "$output_file"
    return
  fi

  rm -f "$normalized_file"
  die "reviewer output is not valid JSON: $output_file"
}

run_plan_wrapper() {
  local host="$1"
  local output_file="$2"
  timeout "$TIMEOUT_SECONDS"s \
    bash "$ROOT_DIR/skills/review-plan/scripts/run-review.sh" \
    --host "$host" \
    --plan "$PLAN_PATH" \
    > "$output_file"
}

run_design_wrapper() {
  local host="$1"
  local output_file="$2"
  timeout "$TIMEOUT_SECONDS"s \
    bash "$ROOT_DIR/skills/review-design/scripts/run-review.sh" \
    --host "$host" \
    --plan "$DESIGN_PATH" \
    > "$output_file"
}

run_code_impl_wrapper() {
  local host="$1"
  local output_file="$2"
  local args=(
    bash "$ROOT_DIR/skills/review-code-impl/scripts/run-review.sh"
    --host "$host"
  )
  local file_path
  for file_path in "${CODE_IMPL_FILES[@]}"; do
    args+=(--file "$file_path")
  done
  timeout "$TIMEOUT_SECONDS"s "${args[@]}" > "$output_file"
}

run_check() {
  local label="$1"
  local output_file="$2"

  log "running ${label}"
  normalize_output "$output_file"
  validate_output "$output_file"
  log "validated ${label} output verdict=$(jq -r '.result.verdict' "$output_file")"
  jq . "$output_file"
}

main() {
  local reviewer
  reviewer=$(pick_reviewer)
  local host
  host=$(pick_host "$reviewer")
  TMP_DIR=$(mktemp -d)
  trap 'code=$?; if [[ $code -ne 0 ]]; then log "temp dir preserved for debugging: $TMP_DIR"; else rm -rf "$TMP_DIR"; fi' EXIT

  if [[ "$MODE" == "plan" || "$MODE" == "all" ]]; then
    [[ -f "$ROOT_DIR/$PLAN_PATH" ]] || die "plan file not found: $PLAN_PATH"
    run_plan_wrapper "$host" "$TMP_DIR/plan.json"
    run_check "plan smoke test" "$TMP_DIR/plan.json"
  fi

  if [[ "$MODE" == "design" || "$MODE" == "all" ]]; then
    [[ -f "$ROOT_DIR/$DESIGN_PATH" ]] || die "design file not found: $DESIGN_PATH"
    run_design_wrapper "$host" "$TMP_DIR/design.json"
    run_check "design smoke test" "$TMP_DIR/design.json"
  fi

  if [[ "$MODE" == "code-impl" || "$MODE" == "all" ]]; then
    local file_path
    for file_path in "${CODE_IMPL_FILES[@]}"; do
      [[ -f "$ROOT_DIR/$file_path" ]] || die "code-impl file not found: $file_path"
    done
    run_code_impl_wrapper "$host" "$TMP_DIR/code-impl.json"
    run_check "code-impl smoke test" "$TMP_DIR/code-impl.json"
  fi

  if [[ "$MODE" == "eval" ]]; then
    local eval_script="$ROOT_DIR/eval/run-eval.sh"
    [[ -f "$eval_script" ]] || die "eval script not found: $eval_script"
    log "running eval mode reviewer=$reviewer timeout=${TIMEOUT_SECONDS}s"
    local eval_rc=0
    local eval_output
    eval_output="$(bash "$eval_script" \
      --mode all \
      --reviewer "$reviewer" \
      --runs 1 \
      --timeout "$TIMEOUT_SECONDS")" || eval_rc=$?
    printf '%s\n' "$eval_output"
    if [[ "$eval_rc" -eq 0 ]]; then
      log "eval smoke test passed"
    else
      log "eval smoke test failed exit_code=$eval_rc"
      exit "$eval_rc"
    fi
    return
  fi

  log "all requested smoke tests passed"
}

main
