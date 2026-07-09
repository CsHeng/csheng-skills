#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=skills/_harness-libs/contracts.sh
source "$SCRIPT_DIR/contracts.sh"

is_valid_boolean_flag() {
  case "${1:-}" in
    true|false) return 0 ;;
    *) return 1 ;;
  esac
}

next_phase_for_entry() {
  local entry="$1"

  case "$entry" in
    analyze-project) printf 'truth-scan\n' ;;
    design-change) printf 'clarify\n' ;;
    plan-change) printf 'plan\n' ;;
    execute-change) printf 'implement-serial\n' ;;
    review-change) printf 'review\n' ;;
    sync-truth) printf 'truth-sync\n' ;;
    close-change) printf 'close\n' ;;
    *) return 1 ;;
  esac
}

phase_requires_human_approval() {
  local phase="$1"

  case "$phase" in
    clarify|design-lite|design-full|plan|dependency-freeze|truth-sync|close) return 0 ;;
    *) return 1 ;;
  esac
}

resolve_next_phase() {
  local current_phase="$1"
  local design_strength="$2"
  local truth_sync_required="$3"
  local parallel_approved="$4"

  is_valid_phase "$current_phase" || return 1
  is_valid_design_strength "$design_strength" || return 1
  is_valid_boolean_flag "$truth_sync_required" || return 1
  is_valid_boolean_flag "$parallel_approved" || return 1

  case "$current_phase" in
    intake) printf 'truth-scan\n' ;;
    truth-scan) printf 'clarify\n' ;;
    clarify)
      case "$design_strength" in
        no-design) printf 'plan\n' ;;
        design-lite) printf 'design-lite\n' ;;
        design-full) printf 'design-full\n' ;;
        *) return 1 ;;
      esac
      ;;
    design-lite|design-full) printf 'plan\n' ;;
    plan) printf 'dependency-freeze\n' ;;
    dependency-freeze)
      # Parallel remains opt-in even after dependency freeze.
      if [[ "$parallel_approved" == "true" ]]; then
        printf 'implement-parallel\n'
      else
        printf 'implement-serial\n'
      fi
      ;;
    implement-serial|implement-parallel) printf 'converge\n' ;;
    converge) printf 'review\n' ;;
    review) printf 'verify\n' ;;
    verify)
      if [[ "$truth_sync_required" == "true" ]]; then
        printf 'truth-sync\n'
      else
        printf 'close\n'
      fi
      ;;
    truth-sync) printf 'close\n' ;;
    close) printf 'close\n' ;;
    *) return 1 ;;
  esac
}
