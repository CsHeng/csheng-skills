#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  run-review.sh --mode <design|plan|code-impl> --host <host> [options]

Options:
  --mode <design|plan|code-impl>     Review mode. Required.
  --host <host>                      Current orchestrator host (e.g. claude, codex). Required.
  --plan <path>                      Design or implementation-plan path. Required for design/plan modes, optional for code-impl mode.
  --file <path>                      File to review (repeatable, code-impl mode only). If omitted, use git scope.
  --repo-root <path>                 Review target repository root. Defaults to current git root or cwd.
  --branch <name>                    Resolve a git worktree branch to its path and use as repo root. Mutually exclusive with --repo-root.
  --reviewer <name>                  Optional reviewer driver override. When set, it must match --host.
  --timeout <seconds>                Reviewer timeout. Default: 1800.
  --batch <n>                        Current review batch metadata. Default: 1.
  --round <n>                        Current review round metadata. Default: 1.
  --max-rounds <n>                   Maximum rounds metadata. Default: 1 for design/plan, 10 for code-impl. Hard limit: 3 for design/plan, 10 for code-impl.
  REVIEW_MAX_BATCHES                 Optional env override for maximum batches. Default: 2.
  --approve-next-batch               Confirm explicit human approval before starting a new batch (>1).
  --depth <auto|boundary|thorough|quick>
                                      Review depth. auto defaults to boundary for design/plan and thorough for code-impl.
  --prior-findings <path>             JSON file with previous round blocking findings for reviewer context.
  --output <path>                    Write normalized JSON output to path instead of stdout.
  -h, --help                         Show this help.
USAGE
}

log() { printf '[run-review] %s\n' "$*" >&2; }
die() {
  local code=1
  if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
    code="$1"
    shift
  fi
  printf '[run-review] error: %s\n' "$*" >&2
  exit "$code"
}
require_cmd() { command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"; }

EXIT_OK=0
EXIT_REVIEWER_UNAVAILABLE=10
EXIT_REVIEWER_FAILED=11
EXIT_SCHEMA_VALIDATION_FAILED=12
EXIT_INPUT_NOT_FOUND=13
EXIT_EMPTY_SCOPE=14
EXIT_MANUAL_APPROVAL_REQUIRED=15

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PLUGIN_ROOT="$(cd -- "$SKILLS_DIR/.." && pwd)"
SCHEMA_PATH="$SCRIPT_DIR/schemas/reviewer-output.schema.json"
RUN_SCHEMA_PATH="$SCRIPT_DIR/schemas/review-run-output.schema.json"

# Source modules
source "$SCRIPT_DIR/artifact-dag.sh"
source "$SCRIPT_DIR/prompt-builder.sh"
source "$SCRIPT_DIR/output-validator.sh"
source "$SCRIPT_DIR/workspace.sh"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
MODE=""
HOST=""
REVIEWER="auto"
TIMEOUT_SECONDS=1800
PLAN_PATH=""
OUTPUT_PATH=""
BATCH_NUMBER=1
ROUND_NUMBER=1
MAX_ROUNDS="auto"
MAX_BATCHES="${REVIEW_MAX_BATCHES:-2}"
APPROVE_NEXT_BATCH=0
DEPTH="auto"
PRIOR_FINDINGS_PATH=""
CODE_IMPL_FILES=()
BRANCH=""
DESIGN_PATH=""
DESIGN_VERSION=""
REPO_ROOT_EXPLICIT=0

canonicalize_root() {
  local candidate="$1"
  local resolved
  resolved="$(realpath "$candidate" 2>/dev/null)" || die $EXIT_INPUT_NOT_FOUND "failed to resolve path: $candidate"
  printf '%s\n' "$resolved"
}

assert_resolved_artifact_path_allowed() {
  local artifact_label="$1"
  local resolved_path="$2"
  local -a allowed_roots=("$REPO_ROOT")

  if printf '%s' "$resolved_path" | grep -q '[[:cntrl:]]'; then
    die $EXIT_INPUT_NOT_FOUND "$artifact_label path contains control characters: $resolved_path"
  fi

  if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    allowed_roots+=("$(realpath "$CLAUDE_PLUGIN_ROOT" 2>/dev/null || printf '%s' "$CLAUDE_PLUGIN_ROOT")")
  fi
  allowed_roots+=("$PLUGIN_ROOT")

  path_is_within_allowed_roots "$resolved_path" "${allowed_roots[@]}" \
    || die $EXIT_INPUT_NOT_FOUND "$artifact_label path outside allowed roots: $resolved_path"
}

parse_and_validate_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mode) MODE="$2"; shift 2 ;;
      --host) HOST="$2"; shift 2 ;;
      --plan) PLAN_PATH="$2"; shift 2 ;;
      --file) CODE_IMPL_FILES+=("$2"); shift 2 ;;
      --repo-root) REPO_ROOT="$2"; REPO_ROOT_EXPLICIT=1; shift 2 ;;
      --branch) BRANCH="$2"; shift 2 ;;
      --reviewer) REVIEWER="$2"; shift 2 ;;
      --timeout) TIMEOUT_SECONDS="$2"; shift 2 ;;
      --batch) BATCH_NUMBER="$2"; shift 2 ;;
      --round) ROUND_NUMBER="$2"; shift 2 ;;
      --max-rounds) MAX_ROUNDS="$2"; shift 2 ;;
      --approve-next-batch) APPROVE_NEXT_BATCH=1; shift ;;
      --depth) DEPTH="$2"; shift 2 ;;
      --prior-findings) PRIOR_FINDINGS_PATH="$2"; shift 2 ;;
      --output) OUTPUT_PATH="$2"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      *) die "unknown argument: $1" ;;
    esac
  done

  case "$MODE" in
    design|plan|code-impl) ;;
    *) die "--mode must be design, plan, or code-impl" ;;
  esac
  [[ -n "$HOST" ]] || die "--host is required"
  if [[ -n "$BRANCH" && "$REPO_ROOT_EXPLICIT" -eq 1 ]]; then
    die "--branch and --repo-root are mutually exclusive"
  fi

  if [[ -n "$BRANCH" ]]; then
    require_cmd awk
    worktree_path="$(command git worktree list --porcelain 2>/dev/null | awk -v branch="refs/heads/$BRANCH" '
      /^worktree / { wt = substr($0, 10) }
      $0 == "branch " branch { print wt; exit }
    ')"
    [[ -n "$worktree_path" ]] || die $EXIT_INPUT_NOT_FOUND "no worktree found for branch: $BRANCH"
    REPO_ROOT="$worktree_path"
    log "step=resolve_branch branch=$BRANCH worktree=$worktree_path"
  fi
  [[ -f "$SCHEMA_PATH" ]] || die $EXIT_INPUT_NOT_FOUND "schema file not found: $SCHEMA_PATH"
  [[ -f "$RUN_SCHEMA_PATH" ]] || die $EXIT_INPUT_NOT_FOUND "run schema file not found: $RUN_SCHEMA_PATH"
  require_cmd jq
  require_cmd timeout
  require_cmd realpath

  if [[ ( "$MODE" == "design" || "$MODE" == "plan" ) && -z "$PLAN_PATH" ]]; then
    die "--plan is required for design and plan modes"
  fi

  [[ "$BATCH_NUMBER" =~ ^[0-9]+$ ]] || die "--batch must be a positive integer"
  [[ "$ROUND_NUMBER" =~ ^[0-9]+$ ]] || die "--round must be a positive integer"
  [[ "$MAX_BATCHES" =~ ^[0-9]+$ ]] || die "REVIEW_MAX_BATCHES must be a positive integer"
  [[ "$BATCH_NUMBER" -ge 1 ]] || die "--batch must be >= 1"
  [[ "$ROUND_NUMBER" -ge 1 ]] || die "--round must be >= 1"
  [[ "$MAX_BATCHES" -ge 1 ]] || die "REVIEW_MAX_BATCHES must be >= 1"
  if [[ "$BATCH_NUMBER" -gt "$MAX_BATCHES" ]]; then
    die $EXIT_MANUAL_APPROVAL_REQUIRED "review batch budget exhausted: batch=$BATCH_NUMBER max_batches=$MAX_BATCHES"
  fi

  case "$DEPTH" in
    auto|boundary|thorough|quick) ;;
    *) die "--depth must be auto, boundary, thorough, or quick" ;;
  esac
  if [[ "$DEPTH" == "auto" ]]; then
    case "$MODE" in
      design|plan) DEPTH="boundary" ;;
      code-impl) DEPTH="thorough" ;;
    esac
  fi

  if [[ "$MAX_ROUNDS" == "auto" ]]; then
    case "$MODE" in
      design|plan) MAX_ROUNDS=1 ;;
      code-impl) MAX_ROUNDS=10 ;;
    esac
  fi
  [[ "$MAX_ROUNDS" =~ ^[0-9]+$ ]] || die "--max-rounds must be a positive integer"
  [[ "$MAX_ROUNDS" -ge 1 ]] || die "--max-rounds must be >= 1"
  case "$MODE" in
    design|plan)
      [[ "$MAX_ROUNDS" -le 3 ]] || die "--max-rounds must be <= 3 for design/plan"
      ;;
    code-impl)
      [[ "$MAX_ROUNDS" -le 10 ]] || die "--max-rounds must be <= 10 for code-impl"
      ;;
  esac
  [[ "$ROUND_NUMBER" -le "$MAX_ROUNDS" ]] || die "--round must be <= --max-rounds"
  if [[ "$BATCH_NUMBER" -gt 1 && "$ROUND_NUMBER" -eq 1 && "$APPROVE_NEXT_BATCH" -ne 1 ]]; then
    die $EXIT_MANUAL_APPROVAL_REQUIRED "starting batch=$BATCH_NUMBER requires --approve-next-batch"
  fi
  if [[ -n "$PRIOR_FINDINGS_PATH" ]]; then
    [[ -f "$PRIOR_FINDINGS_PATH" ]] || die $EXIT_INPUT_NOT_FOUND "prior-findings file not found: $PRIOR_FINDINGS_PATH"
    jq -e '
      type == "array"
      and all(.[];
        type == "object"
        and (.severity | type == "string" and length > 0)
        and (.location | type == "string" and length > 0)
        and (.evidence | type == "string" and length > 0)
      )
    ' "$PRIOR_FINDINGS_PATH" >/dev/null 2>&1 \
      || die $EXIT_SCHEMA_VALIDATION_FAILED "prior-findings must be an array of finding objects with severity, location, and evidence"
  fi

  REPO_ROOT="$(canonicalize_root "$REPO_ROOT")"
}

driver_is_available() {
  local driver="$1"
  local driver_path="$SCRIPT_DIR/drivers/${driver}.sh"
  [[ -f "$driver_path" ]] || return 1
  bash "$driver_path" --probe >/dev/null 2>&1
}

pick_reviewer() {
  if [[ "$REVIEWER" != "auto" ]]; then
    if [[ "$REVIEWER" != "$HOST" ]]; then
      die $EXIT_REVIEWER_UNAVAILABLE "reviewer must match host for same-driver review: reviewer=$REVIEWER host=$HOST"
    fi
    if ! driver_is_available "$REVIEWER"; then
      die $EXIT_REVIEWER_UNAVAILABLE "reviewer driver unavailable: $REVIEWER"
    fi
    printf '%s\n' "$REVIEWER"
    return
  fi

  if driver_is_available "$HOST"; then
    printf '%s\n' "$HOST"
    return
  fi

  die $EXIT_REVIEWER_UNAVAILABLE "same-driver reviewer unavailable for host=$HOST"
}

reviewer_model_for() {
  case "$1" in
    codex) printf '%s\n' 'host-default' ;;
    claude) printf '%s\n' 'host-default' ;;
    *) printf '%s\n' 'unknown' ;;
  esac
}

run_reviewer() {
  local reviewer="$1" prompt_file="$2" output_file="$3"
  local driver="$SCRIPT_DIR/drivers/${reviewer}.sh"
  [[ -f "$driver" ]] || die $EXIT_REVIEWER_UNAVAILABLE "no driver found: $driver"
  bash "$driver" \
    --prompt "$prompt_file" \
    --schema "$SCHEMA_PATH" \
    --output "$output_file" \
    --repo-root "$WORKSPACE_ROOT" \
    --timeout "$TIMEOUT_SECONDS" \
    --depth "$DEPTH"
}

load_plan_design_linkage() {
  [[ -n "${RESOLVED_PLAN:-}" ]] || die $EXIT_INPUT_NOT_FOUND "missing resolved plan path for design linkage"

  local -a design_ref=()
  local design_ref_output=""
  design_ref_output="$(resolve_plan_design_ref "$REPO_ROOT" "$RESOLVED_PLAN")" \
    || die $EXIT_INPUT_NOT_FOUND "missing required upstream design linkage for plan: $RESOLVED_PLAN"

  mapfile -t design_ref < <(printf '%s\n' "$design_ref_output")
  [[ "${#design_ref[@]}" -eq 2 ]] || die $EXIT_INPUT_NOT_FOUND "failed to resolve upstream design from plan: $RESOLVED_PLAN"

  DESIGN_PATH="$(realpath "${design_ref[0]}" 2>/dev/null)" || die $EXIT_INPUT_NOT_FOUND "upstream design file not found: ${design_ref[0]}"
  [[ -f "$DESIGN_PATH" ]] || die $EXIT_INPUT_NOT_FOUND "upstream design file not found: $DESIGN_PATH"
  assert_resolved_artifact_path_allowed "upstream design" "$DESIGN_PATH"
  DESIGN_VERSION="${design_ref[1]}"

  local allowed_touch_output=""
  allowed_touch_output="$(build_allowed_touch_set "$RESOLVED_PLAN" "$DESIGN_PATH")" \
    || die $EXIT_INPUT_NOT_FOUND "failed to compute allowed touch set from plan/design linkage"
  [[ -n "$allowed_touch_output" ]] \
    || die $EXIT_INPUT_NOT_FOUND "allowed touch set is empty for plan/design linkage"
  mapfile -t ALLOWED_TOUCH_SET < <(printf '%s\n' "$allowed_touch_output")

  local review_read_surface_output=""
  review_read_surface_output="$(build_review_read_surface "$DESIGN_PATH")" \
    || die $EXIT_INPUT_NOT_FOUND "failed to compute review read surface from upstream design"
  [[ -n "$review_read_surface_output" ]] \
    || die $EXIT_INPUT_NOT_FOUND "review read surface is empty for upstream design"
  mapfile -t REVIEW_READ_SURFACE < <(printf '%s\n' "$review_read_surface_output")
}

main() {
  parse_and_validate_args "$@"

  local reviewer
  reviewer="$(pick_reviewer)"
  local reviewer_model
  reviewer_model="$(reviewer_model_for "$reviewer")"

  RESOLVED_PLAN=""
  WORKSPACE_PLAN_PATH=""
  SPEC_BASELINE="inferred"
  if [[ -n "$PLAN_PATH" ]]; then
    RESOLVED_PLAN="$(resolve_plan_path)"
    if [[ "$MODE" == "design" ]]; then
      SPEC_BASELINE="design"
    else
      SPEC_BASELINE="plan"
    fi

    if [[ "$MODE" == "plan" || "$MODE" == "code-impl" ]]; then
      load_plan_design_linkage
    fi
  fi

  if [[ "$MODE" == "code-impl" ]]; then
    collect_code_impl_scope
  fi

  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  prepare_workspace

  PRE_CHECK_FINDINGS="$(run_pre_checks)"

  local prompt_file="$TMP_DIR/review.prompt"
  local reviewer_output="$TMP_DIR/reviewer.json"
  local scope_json="$TMP_DIR/scope.json"
  local run_output="$TMP_DIR/run-output.json"

  case "$MODE" in
    design) make_design_prompt "$prompt_file" "$WORKSPACE_PLAN_PATH" ;;
    plan) make_plan_prompt "$prompt_file" "$WORKSPACE_PLAN_PATH" ;;
    code-impl) make_code_impl_prompt "$prompt_file" "${CODE_IMPL_SCOPE[@]}" ;;
  esac

  log "step=config mode=$MODE host=$HOST reviewer=$reviewer repo_root=$REPO_ROOT workspace_root=$WORKSPACE_ROOT batch=$BATCH_NUMBER round=$ROUND_NUMBER/$MAX_ROUNDS depth=$DEPTH prior_findings=${PRIOR_FINDINGS_PATH:-none}"
  local review_mode="same-driver"
  log "step=prompt prompt_file=$prompt_file prompt_bytes=$(wc -c < "$prompt_file")"
  log "step=invoke_reviewer reviewer=$reviewer driver=skills/_review-libs/drivers/${reviewer}.sh"
  local reviewer_rc=0
  run_reviewer "$reviewer" "$prompt_file" "$reviewer_output" || reviewer_rc=$?
  log "step=reviewer_done reviewer=$reviewer exit_code=$reviewer_rc"
  if [[ "$reviewer_rc" -ne 0 ]]; then
    die $EXIT_REVIEWER_FAILED "reviewer=$reviewer exited with code=$reviewer_rc"
  fi

  normalize_output "$reviewer_output"
  if validate_reviewer_output "$reviewer_output"; then
    log "step=validate_reviewer result=ok"
  else
    log "step=validate_reviewer result=fail"
    die $EXIT_SCHEMA_VALIDATION_FAILED "reviewer output schema validation failed"
  fi

  build_scope_json "$scope_json"
  build_run_output "$reviewer_output" "$scope_json" "$run_output" "$review_mode" "$reviewer" "$reviewer_model"
  if validate_run_output "$run_output"; then
    log "step=validate_run_output result=ok"
  else
    log "step=validate_run_output result=fail"
    die $EXIT_SCHEMA_VALIDATION_FAILED "run output schema validation failed"
  fi

  [[ -n "$OUTPUT_PATH" ]] && cp "$run_output" "$OUTPUT_PATH"
  log "step=done review_mode=$review_mode reviewer=$reviewer verdict=$(jq -r '.result.verdict // "unknown"' "$run_output") status=$(jq -r '.status // "unknown"' "$run_output") next_action=$(jq -r '.next_action // "unknown"' "$run_output")"
  cat "$run_output"
}

if [[ "${RUN_REVIEW_SOURCE_ONLY:-0}" == "1" ]]; then
  return 0 2>/dev/null || exit 0
fi

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
