#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=skills/_harness-libs/artifact-dag.sh
source "$SCRIPT_DIR/artifact-dag.sh"
# shellcheck source=skills/_harness-libs/design-runner.sh
source "$SCRIPT_DIR/design-runner.sh"
# shellcheck source=skills/_harness-libs/plan-runner.sh
source "$SCRIPT_DIR/plan-runner.sh"
# shellcheck source=skills/_harness-libs/evaluation-gate.sh
source "$SCRIPT_DIR/evaluation-gate.sh"
# shellcheck source=skills/_harness-libs/rollback.sh
source "$SCRIPT_DIR/rollback.sh"
# shellcheck source=skills/_harness-libs/task-ledger.sh
source "$SCRIPT_DIR/task-ledger.sh"
# shellcheck source=skills/_harness-libs/phase-engine.sh
source "$SCRIPT_DIR/phase-engine.sh"

execute_entry_phase() {
  next_phase_for_entry "implement-change"
}

execution_plan_approval_status() {
  plan_approval_status "$1"
}

validate_execution_plan() {
  local plan_file="$1"
  local approval_status=""

  validate_execution_grade_plan_artifact "$plan_file" || return 1
  approval_status="$(execution_plan_approval_status "$plan_file")"

  [[ "$approval_status" == "approved" ]] || {
    printf 'plan artifact is not approved for execution: %s\n' "$approval_status" >&2
    return 1
  }
}

execution_plan_mode() {
  local plan_file="$1"

  [[ -f "$plan_file" ]] || {
    printf 'missing plan file: %s\n' "$plan_file" >&2
    return 1
  }

  if rg -n 'parallel_execution_approved:[[:space:]]*true' "$plan_file" >/dev/null; then
    printf 'parallel-approved\n'
    return
  fi

  printf 'serial-first\n'
}

execution_workspace_mode() {
  local repo_root=""
  local git_dir=""
  local common_dir=""
  local resolved_git_dir=""
  local resolved_common_dir=""

  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  git_dir="$(git -C "$repo_root" rev-parse --git-dir 2>/dev/null || true)"
  common_dir="$(git -C "$repo_root" rev-parse --git-common-dir 2>/dev/null || true)"

  if [[ "$repo_root" == */.agents/worktrees/* ]]; then
    printf 'isolated-worktree\n'
    return
  fi

  if [[ -n "$git_dir" && -n "$common_dir" ]]; then
    if [[ "$git_dir" = /* ]]; then
      resolved_git_dir="$(realpath "$git_dir" 2>/dev/null || printf '%s' "$git_dir")"
    else
      resolved_git_dir="$(realpath "$repo_root/$git_dir" 2>/dev/null || printf '%s' "$git_dir")"
    fi
    if [[ "$common_dir" = /* ]]; then
      resolved_common_dir="$(realpath "$common_dir" 2>/dev/null || printf '%s' "$common_dir")"
    else
      resolved_common_dir="$(realpath "$repo_root/$common_dir" 2>/dev/null || printf '%s' "$common_dir")"
    fi
    if [[ "$resolved_git_dir" != "$resolved_common_dir" ]]; then
      printf 'isolated-worktree\n'
      return
    fi
  fi

  printf 'current-checkout\n'
}

execution_worktree_preflight_required() {
  local workspace_mode="$1"
  local decision_recorded="$2"

  is_valid_boolean_flag "$decision_recorded" || {
    printf 'invalid worktree decision flag: %s\n' "$decision_recorded" >&2
    return 1
  }

  case "$workspace_mode" in
    isolated-worktree) printf 'false\n' ;;
    current-checkout)
      if [[ "$decision_recorded" == "true" ]]; then
        printf 'false\n'
      else
        printf 'true\n'
      fi
      ;;
    *)
      printf 'invalid workspace mode: %s\n' "$workspace_mode" >&2
      return 1
      ;;
  esac
}

strip_wrapping_backticks() {
  sed -E 's/^`(.*)`$/\1/'
}

execution_verification_commands() {
  local plan_file="$1"

  validate_execution_plan "$plan_file" >/dev/null || return 1
  extract_markdown_list "$plan_file" "Implementation Scope" "verification_scope" \
    | awk 'NF > 0' \
    | strip_wrapping_backticks
}

resolve_execution_design_file() {
  local plan_file="$1"
  local repo_root=""
  local -a resolved=()

  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  mapfile -t resolved < <(resolve_plan_design_ref "$repo_root" "$plan_file")
  [[ "${#resolved[@]}" -ge 1 ]] || return 1
  printf '%s\n' "${resolved[0]}"
}

execution_allowed_touch_set() {
  local plan_file="$1"
  local design_file=""

  validate_execution_plan "$plan_file" >/dev/null
  design_file="$(resolve_execution_design_file "$plan_file")"
  build_allowed_touch_set "$plan_file" "$design_file"
}

execution_truth_sync_required() {
  local plan_file="$1"
  local design_file=""
  local truth_impact=""

  validate_execution_plan "$plan_file" >/dev/null
  design_file="$(resolve_execution_design_file "$plan_file")"
  truth_impact="$(rg -o 'truth_impact:[[:space:]]*(low|medium|high)' "$design_file" | head -n 1 | sed -E 's/^truth_impact:[[:space:]]*//')"

  case "$truth_impact" in
    medium|high) printf 'true\n' ;;
    low) printf 'false\n' ;;
    *)
      printf 'missing or invalid truth_impact in design: %s\n' "$design_file" >&2
      return 1
      ;;
  esac
}

execution_task_catalog() {
  local plan_file="$1"

  validate_execution_plan "$plan_file" >/dev/null
  task_catalog_json "$plan_file"
}

execution_task_ledger() {
  local plan_file="$1"

  validate_execution_plan "$plan_file" >/dev/null
  task_ledger_json "$plan_file"
}

execution_next_ready_task() {
  local ledger_file="$1"
  task_ledger_next_ready_task_id "$ledger_file"
}

build_execution_result_json() {
  build_execution_result "$@"
}

build_execute_gate_result() {
  local review_status="$1"
  local verify_status="$2"
  local truth_sync_required="$3"
  local truth_sync_completed="$4"

  build_evaluation_verdict "$review_status" "$verify_status" "$truth_sync_required" "$truth_sync_completed"
}

execute_rollback_target() {
  local failure_kind="$1"
  local failure_count="$2"

  resolve_rollback_target "$failure_kind" "$failure_count"
}

usage() {
  cat <<'EOF'
Usage:
  execute-runner.sh entry-phase
  execute-runner.sh approval-status <plan-file>
  execute-runner.sh validate <plan-file>
  execute-runner.sh mode <plan-file>
  execute-runner.sh workspace-mode
  execute-runner.sh worktree-preflight-required <current-checkout|isolated-worktree> <decision-recorded>
  execute-runner.sh verification-commands <plan-file>
  execute-runner.sh allowed-touch-set <plan-file>
  execute-runner.sh truth-sync-required <plan-file>
  execute-runner.sh task-catalog <plan-file>
  execute-runner.sh task-ledger <plan-file>
  execute-runner.sh next-ready-task <ledger-json>
  execute-runner.sh execution-result <plan-path> <ledger-json> <current-phase> <active-task-id-or-empty> <stop-reason> <review-status> <verify-status> <next-entry> <next-phase> <human-input-required> [workspace-mode]
  execute-runner.sh gate-result <review-status> <verify-status> <truth-sync-required> <truth-sync-completed>
  execute-runner.sh rollback-target <failure-kind> <failure-count>
EOF
}

main() {
  local command="${1:-}"

  case "$command" in
    entry-phase)
      execute_entry_phase
      ;;
    approval-status)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      execution_plan_approval_status "$2"
      ;;
    validate)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      validate_execution_plan "$2"
      ;;
    mode)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      execution_plan_mode "$2"
      ;;
    workspace-mode)
      [[ $# -eq 1 ]] || { usage >&2; return 1; }
      execution_workspace_mode
      ;;
    worktree-preflight-required)
      [[ $# -eq 3 ]] || { usage >&2; return 1; }
      execution_worktree_preflight_required "$2" "$3"
      ;;
    verification-commands)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      execution_verification_commands "$2"
      ;;
    allowed-touch-set)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      execution_allowed_touch_set "$2"
      ;;
    truth-sync-required)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      execution_truth_sync_required "$2"
      ;;
    task-catalog)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      execution_task_catalog "$2"
      ;;
    task-ledger)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      execution_task_ledger "$2"
      ;;
    next-ready-task)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      execution_next_ready_task "$2"
      ;;
    execution-result)
      [[ $# -ge 11 ]] || { usage >&2; return 1; }
      build_execution_result_json "${@:2}"
      ;;
    gate-result)
      [[ $# -eq 5 ]] || { usage >&2; return 1; }
      build_execute_gate_result "$2" "$3" "$4" "$5"
      ;;
    rollback-target)
      [[ $# -eq 3 ]] || { usage >&2; return 1; }
      execute_rollback_target "$2" "$3"
      ;;
    *)
      usage >&2
      return 1
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
