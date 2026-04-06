#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=skills/_harness-libs/contracts.sh
source "$SCRIPT_DIR/contracts.sh"

rollback_target_for_failure() {
  local failure_kind="$1"

  is_valid_failure_kind "$failure_kind" || return 1

  case "$failure_kind" in
    classification-failure|requirement-ambiguity) printf 'clarify\n' ;;
    truth-conflict) printf 'truth-scan\n' ;;
    boundary-mismatch) printf 'design-full\n' ;;
    plan-incompleteness) printf 'plan\n' ;;
    dependency-churn|parallel-conflict|convergence-failure) printf 'dependency-freeze\n' ;;
    review-blocking-failure|verification-failure) printf 'implement-serial\n' ;;
    truth-sync-failure) printf 'truth-sync\n' ;;
    *) return 1 ;;
  esac
}

escalate_rollback_target() {
  local target_phase="$1"
  local failure_count="$2"

  is_valid_phase "$target_phase" || return 1
  [[ "$failure_count" =~ ^[1-9][0-9]*$ ]] || return 1

  case "$target_phase" in
    implement-serial)
      case "$failure_count" in
        1) printf 'implement-serial\n' ;;
        2) printf 'dependency-freeze\n' ;;
        3) printf 'plan\n' ;;
        4) printf 'design-lite\n' ;;
        *) printf 'design-full\n' ;;
      esac
      ;;
    dependency-freeze)
      case "$failure_count" in
        1) printf 'dependency-freeze\n' ;;
        2) printf 'plan\n' ;;
        3) printf 'design-lite\n' ;;
        *) printf 'design-full\n' ;;
      esac
      ;;
    plan)
      case "$failure_count" in
        1) printf 'plan\n' ;;
        2) printf 'design-lite\n' ;;
        *) printf 'design-full\n' ;;
      esac
      ;;
    design-lite)
      case "$failure_count" in
        1) printf 'design-lite\n' ;;
        *) printf 'design-full\n' ;;
      esac
      ;;
    clarify|truth-scan|design-full|truth-sync) printf '%s\n' "$target_phase" ;;
    *) return 1 ;;
  esac
}

resolve_rollback_target() {
  local failure_kind="$1"
  local failure_count="$2"
  local base_target=""

  base_target="$(rollback_target_for_failure "$failure_kind")"
  escalate_rollback_target "$base_target" "$failure_count"
}
