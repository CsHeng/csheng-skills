#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  skills/_review-libs/smoke-test/smoke-cross-model-review.sh [plan|code-impl|design|all|eval] [options]

Options:
  --reviewer <auto|claude|codex>   Reviewer CLI to use. Default: auto
  --timeout <seconds>              Per-check timeout. Default: 1800
  --plan <path>                    Plan path for plan smoke test
  --design <path>                  Design path for design smoke test
  --code-impl-file <path>          File to include in code-impl smoke test (repeatable)
  -h, --help                       Show this help

Defaults:
  plan mode uses skills/_review-libs/smoke-test/fixtures/sample-plan.md
  design mode uses skills/_review-libs/smoke-test/fixtures/sample-design.md
  code-impl mode uses a maintained hard-coded fixture set aligned with the sample plan's impl/test refs

Notes:
  - This script tests the direct cross-model reviewer path, not `claude --agent`.
  - Success here means the smoke harness accepted the run output contract; it does not imply the reviewer returned `PASS`.
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

resolve_input_path() {
  local input_path="$1"
  local candidate_path=""

  if [[ "$input_path" = /* ]]; then
    candidate_path="$input_path"
  else
    candidate_path="$ROOT_DIR/$input_path"
  fi

  realpath "$candidate_path" 2>/dev/null || return 1
}

ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
MODE="all"
REVIEWER="auto"
TIMEOUT_SECONDS=1800
PLAN_PATH="skills/_review-libs/smoke-test/fixtures/sample-plan.md"
DESIGN_PATH="skills/_review-libs/smoke-test/fixtures/sample-design.md"
DEFAULT_CODE_IMPL_FILES=(
  "skills/_review-libs/artifact-dag.sh"
  "skills/_review-libs/output-validator.sh"
  "skills/_review-libs/run-review.sh"
  "skills/_review-libs/workspace.sh"
  "skills/_review-libs/prompt-builder.sh"
  "skills/_review-libs/smoke-test/test-artifact-dag.sh"
  "skills/_review-libs/smoke-test/test-review-gating.sh"
  "skills/_review-libs/smoke-test/smoke-cross-model-review.sh"
)
CODE_IMPL_FILES=("${DEFAULT_CODE_IMPL_FILES[@]}")

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
      if [[ "${CODE_IMPL_FILES[*]:-}" == "${DEFAULT_CODE_IMPL_FILES[*]}" ]]; then
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

require_cmd jq
require_cmd realpath
require_cmd timeout

resolve_mode_paths() {
  local resolved_path=""
  local -a resolved_files=()
  local file_path=""

  case "$MODE" in
    plan|code-impl|all)
      resolved_path="$(resolve_input_path "$PLAN_PATH")" || die "plan file not found: $PLAN_PATH"
      PLAN_PATH="$resolved_path"
      ;;
  esac

  case "$MODE" in
    design|all)
      resolved_path="$(resolve_input_path "$DESIGN_PATH")" || die "design file not found: $DESIGN_PATH"
      DESIGN_PATH="$resolved_path"
      ;;
  esac

  case "$MODE" in
    code-impl|all)
      for file_path in "${CODE_IMPL_FILES[@]}"; do
        resolved_path="$(resolve_input_path "$file_path")" || die "code-impl file not found: $file_path"
        resolved_files+=("$resolved_path")
      done
      CODE_IMPL_FILES=("${resolved_files[@]}")
      ;;
  esac
}

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
    def is_int: type == "number" and floor == .;
    def valid_confidence: . == "high" or . == "medium" or . == "low";
    def valid_scope_class:
      . == "baseline_mismatch"
      or . == "in_scope_blocking"
      or . == "adjacent_debt"
      or . == "out_of_dag_issue"
      or . == "external_verification_failure";
    def valid_blocking_finding:
      type == "object"
      and (.severity == "Critical" or .severity == "Important")
      and (.location | nonempty)
      and (.evidence | nonempty)
      and (.impact | nonempty)
      and (.fix | nonempty)
      and (.confidence | valid_confidence)
      and (.scope_class | valid_scope_class);
    type == "object"
    and (.mode == "design" or .mode == "plan" or .mode == "code-impl")
    and (.host | nonempty)
    and (.reviewer | nonempty)
    and (.reviewer_model | nonempty)
    and (.review_mode == "cross-driver" or .review_mode == "same-driver")
    and (.status == "pass" or .status == "needs_fixes" or .status == "manual_review_required")
    and (.next_action == "stop_passed" or .next_action == "host_fix_then_rerun" or .next_action == "human_decision_required")
    and (.manual_intervention_required | type == "boolean")
    and (.batch | is_int)
    and (.round | is_int)
    and (.max_rounds | is_int)
    and (.suggested_next_batch | is_int)
    and (.suggested_next_round | is_int)
    and (.batch >= 1)
    and (.round >= 1)
    and (.round <= .max_rounds)
    and (.max_rounds >= 1)
    and (.max_rounds <= 3)
    and (.blocking_findings | type == "array")
    and (all(.blocking_findings[]?; valid_blocking_finding))
    and (.scope | type == "object")
    and (.scope.workspace_mode == "isolated")
    and (.scope.workspace_root | nonempty)
    and (.scope.spec_baseline == "design" or .scope.spec_baseline == "plan" or .scope.spec_baseline == "inferred")
    and (.scope.files | type == "array")
    and (.scope.allowed_touch_set | type == "array")
    and (.scope.out_of_scope_touched_files | type == "array")
    and (if .mode == "plan" then (.scope.spec_baseline == "plan" and (.scope.design_path | nonempty) and (.scope.allowed_touch_set | length > 0)) else true end)
    and (if .mode == "code-impl" and .scope.spec_baseline == "plan" then ((.scope.design_path | nonempty) and (.scope.allowed_touch_set | length > 0)) else true end)
    and (.result | type == "object")
    and (.result.lens | nonempty)
    and (.result.verdict == "PASS" or .result.verdict == "FAIL")
    and (.result.summary | nonempty)
    and (.result.pass_rationale | type == "string")
    and (.result.findings | type == "array")
    and (
      if .result.verdict == "PASS" then
        (.blocking_findings == [] and (.result.pass_rationale | nonempty))
      else
        ((.blocking_findings | length) > 0)
      end
    )
    and (
      if .status == "pass" then
        (.next_action == "stop_passed"
        and .manual_intervention_required == false
        and .result.verdict == "PASS"
        and .blocking_findings == []
        and .suggested_next_batch == .batch
        and .suggested_next_round == .round)
      elif .status == "needs_fixes" then
        (.next_action == "host_fix_then_rerun"
        and .manual_intervention_required == false
        and .result.verdict == "FAIL"
        and (.blocking_findings | length) > 0
        and all(.blocking_findings[]; .scope_class == "in_scope_blocking")
        and .round < .max_rounds
        and .suggested_next_batch == .batch
        and .suggested_next_round == (.round + 1))
      else
        (.next_action == "human_decision_required"
        and .manual_intervention_required == true
        and .result.verdict == "FAIL"
        and (.blocking_findings | length) > 0
        and ((any(.blocking_findings[]; .scope_class != "in_scope_blocking")) or (.round == .max_rounds))
        and .suggested_next_batch == (.batch + 1)
        and .suggested_next_round == 1)
      end
    )
  ' "$output_file" >/dev/null
}

normalize_output() {
  local output_file="$1"
  local normalized_file
  normalized_file="${output_file}.normalized"

  if jq -e . "$output_file" >/dev/null 2>&1; then
    return
  fi

  # Match production normalize_output behavior.
  sed -e '/^[[:space:]]*$/d' -e '/^```[[:alpha:]]*$/d' -e '/^```$/d' "$output_file" > "$normalized_file"

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
    bash "$ROOT_DIR/skills/_review-libs/run-review.sh" \
    --mode plan \
    --host "$host" \
    --cross-model \
    --reviewer "$reviewer" \
    --plan "$PLAN_PATH" \
    > "$output_file"
}

run_design_wrapper() {
  local host="$1"
  local output_file="$2"
  timeout "$TIMEOUT_SECONDS"s \
    bash "$ROOT_DIR/skills/_review-libs/run-review.sh" \
    --mode design \
    --host "$host" \
    --cross-model \
    --reviewer "$reviewer" \
    --plan "$DESIGN_PATH" \
    > "$output_file"
}

run_code_impl_wrapper() {
  local host="$1"
  local output_file="$2"
  local args=(
    bash "$ROOT_DIR/skills/_review-libs/run-review.sh"
    --mode code-impl
    --host "$host"
    --cross-model
    --reviewer "$reviewer"
    --plan "$PLAN_PATH"
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
  log "validated ${label} harness contract reviewer_verdict=$(jq -r '.result.verdict' "$output_file")"
  jq . "$output_file"
}

main() {
  resolve_mode_paths

  local reviewer
  reviewer=$(pick_reviewer)
  local host
  host=$(pick_host "$reviewer")
  TMP_DIR=$(mktemp -d)
  trap 'code=$?; if [[ $code -ne 0 ]]; then log "temp dir preserved for debugging: $TMP_DIR"; else rm -rf "$TMP_DIR"; fi' EXIT

  if [[ "$MODE" == "plan" || "$MODE" == "all" ]]; then
    [[ -f "$PLAN_PATH" ]] || die "plan file not found: $PLAN_PATH"
    run_plan_wrapper "$host" "$TMP_DIR/plan.json"
    run_check "plan smoke test" "$TMP_DIR/plan.json"
  fi

  if [[ "$MODE" == "design" || "$MODE" == "all" ]]; then
    [[ -f "$DESIGN_PATH" ]] || die "design file not found: $DESIGN_PATH"
    run_design_wrapper "$host" "$TMP_DIR/design.json"
    run_check "design smoke test" "$TMP_DIR/design.json"
  fi

  if [[ "$MODE" == "code-impl" || "$MODE" == "all" ]]; then
    local file_path
    for file_path in "${CODE_IMPL_FILES[@]}"; do
      [[ -f "$file_path" ]] || die "code-impl file not found: $file_path"
    done
    run_code_impl_wrapper "$host" "$TMP_DIR/code-impl.json"
    run_check "code-impl smoke test" "$TMP_DIR/code-impl.json"
  fi

  if [[ "$MODE" == "eval" ]]; then
    local eval_script="$ROOT_DIR/skills/_review-libs/eval/run-eval.sh"
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
      log "eval smoke run completed with exit_code=0"
    else
      log "eval smoke test failed exit_code=$eval_rc"
      exit "$eval_rc"
    fi
    return
  fi

  log "all requested smoke checks completed with valid harness output"
}

main
