#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=skills/_harness-libs/contracts.sh
source "$SCRIPT_DIR/contracts.sh"

is_valid_request_kind() {
  case "${1:-}" in
    state-query|change-definition|change-planning|change-execution|artifact-review|truth-maintenance|integration-closeout) return 0 ;;
    *) return 1 ;;
  esac
}

is_valid_impact_level() {
  case "${1:-}" in
    low|medium|high) return 0 ;;
    *) return 1 ;;
  esac
}

is_valid_boolean_flag() {
  case "${1:-}" in
    true|false) return 0 ;;
    *) return 1 ;;
  esac
}

request_kind_to_entry() {
  local request_kind="$1"

  case "$request_kind" in
    state-query) printf 'analyze-project\n' ;;
    change-definition) printf 'design-change\n' ;;
    change-planning) printf 'plan-change\n' ;;
    change-execution) printf 'implement-change\n' ;;
    artifact-review) printf 'review-change\n' ;;
    truth-maintenance) printf 'sync-truth\n' ;;
    integration-closeout) printf 'close-change\n' ;;
    *) return 1 ;;
  esac
}

normalize_entry_for_request_and_phase() {
  local request_kind="$1"
  local recommended_next_phase="$2"

  case "$recommended_next_phase" in
    truth-scan) printf 'analyze-project\n' ;;
    clarify|design-lite|design-full) printf 'design-change\n' ;;
    truth-sync) printf 'sync-truth\n' ;;
    close) printf 'close-change\n' ;;
    *) request_kind_to_entry "$request_kind" ;;
  esac
}

base_phase_for_request_kind() {
  local request_kind="$1"

  case "$request_kind" in
    state-query) printf 'truth-scan\n' ;;
    change-definition) printf 'clarify\n' ;;
    change-planning) printf 'plan\n' ;;
    change-execution) printf 'implement-serial\n' ;;
    artifact-review) printf 'review\n' ;;
    truth-maintenance) printf 'truth-sync\n' ;;
    integration-closeout) printf 'close\n' ;;
    *) return 1 ;;
  esac
}

classify_change() {
  local request_kind="$1"
  local truth_impact="$2"
  local boundary_impact="$3"
  local truth_repair="$4"
  local recommended_entry change_class design_strength truth_sync_required parallel_candidate recommended_next_phase

  is_valid_request_kind "$request_kind" || return 1
  is_valid_impact_level "$truth_impact" || return 1
  is_valid_impact_level "$boundary_impact" || return 1
  is_valid_boolean_flag "$truth_repair" || return 1

  recommended_entry="$(request_kind_to_entry "$request_kind")"
  recommended_next_phase="$(base_phase_for_request_kind "$request_kind")"
  change_class="A"
  design_strength="no-design"
  truth_sync_required=false
  parallel_candidate=false

  if [[ "$truth_repair" == "true" ]]; then
    change_class="D"
    design_strength="design-lite"
    truth_sync_required=true
    recommended_next_phase="design-lite"
  elif [[ "$boundary_impact" == "high" || "$truth_impact" == "high" ]]; then
    change_class="C"
    design_strength="design-full"
    truth_sync_required=true
    parallel_candidate=false
    recommended_next_phase="design-full"
  elif [[ "$boundary_impact" == "medium" || "$truth_impact" == "medium" ]]; then
    change_class="B"
    design_strength="design-lite"
    truth_sync_required=true
    parallel_candidate=true
    recommended_next_phase="design-lite"
  fi

  recommended_entry="$(normalize_entry_for_request_and_phase "$request_kind" "$recommended_next_phase")"

  jq -n \
    --arg request_kind "$request_kind" \
    --arg recommended_entry "$recommended_entry" \
    --arg change_class "$change_class" \
    --arg design_strength "$design_strength" \
    --arg truth_impact "$truth_impact" \
    --arg boundary_impact "$boundary_impact" \
    --arg recommended_next_phase "$recommended_next_phase" \
    --argjson truth_repair "$truth_repair" \
    --argjson truth_sync_required "$truth_sync_required" \
    --argjson parallel_candidate "$parallel_candidate" \
    '{
      request_kind: $request_kind,
      recommended_entry: $recommended_entry,
      change_class: $change_class,
      design_strength: $design_strength,
      truth_impact: $truth_impact,
      boundary_impact: $boundary_impact,
      truth_repair: $truth_repair,
      truth_sync_required: $truth_sync_required,
      parallel_candidate: $parallel_candidate,
      recommended_next_phase: $recommended_next_phase
    }'
}
