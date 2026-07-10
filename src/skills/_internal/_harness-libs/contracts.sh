#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${HARNESS_CONTRACTS_SH_LOADED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi

readonly HARNESS_ENTRIES=(
  analyze-project
  design-change
  plan-change
  implement-change
  review-change
  sync-truth
  close-change
)

readonly HARNESS_PHASES=(
  intake
  truth-scan
  clarify
  design-lite
  design-full
  plan
  dependency-freeze
  implement-serial
  implement-parallel
  converge
  review
  verify
  truth-sync
  close
)

readonly HARNESS_CHANGE_CLASSES=(A B C D)
readonly HARNESS_DESIGN_STRENGTHS=(no-design design-lite design-full)
readonly HARNESS_VERDICTS=(pass needs-fixes needs-rollback manual-decision-required)
readonly HARNESS_ARTIFACT_CLASSES=(truth design plan implementation evaluation history)
readonly HARNESS_FAILURE_KINDS=(
  classification-failure
  truth-conflict
  requirement-ambiguity
  boundary-mismatch
  plan-incompleteness
  dependency-churn
  parallel-conflict
  convergence-failure
  review-blocking-failure
  verification-failure
  truth-sync-failure
)
readonly HARNESS_TASK_STATUSES=(pending ready in_progress in_review blocked done)
readonly HARNESS_EXECUTION_STOP_REASONS=(
  worktree_decision_required
  task_blocked_requires_human
  scope_violation_requires_replan
  rollback_required
  plan_incomplete
  final_review_failed
  final_verification_failed
  truth_sync_required
  ready_for_close
)

contains_value() {
  local needle="$1"
  shift || true

  local item=""
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done

  return 1
}

is_valid_entry() { contains_value "$1" "${HARNESS_ENTRIES[@]}"; }
is_valid_phase() { contains_value "$1" "${HARNESS_PHASES[@]}"; }
is_valid_change_class() { contains_value "$1" "${HARNESS_CHANGE_CLASSES[@]}"; }
is_valid_design_strength() { contains_value "$1" "${HARNESS_DESIGN_STRENGTHS[@]}"; }
is_valid_verdict() { contains_value "$1" "${HARNESS_VERDICTS[@]}"; }
is_valid_artifact_class() { contains_value "$1" "${HARNESS_ARTIFACT_CLASSES[@]}"; }
is_valid_failure_kind() { contains_value "$1" "${HARNESS_FAILURE_KINDS[@]}"; }
is_valid_task_status() { contains_value "$1" "${HARNESS_TASK_STATUSES[@]}"; }
is_valid_execution_stop_reason() { contains_value "$1" "${HARNESS_EXECUTION_STOP_REASONS[@]}"; }

harness_default_phase() {
  printf 'intake\n'
}

readonly HARNESS_CONTRACTS_SH_LOADED=1
