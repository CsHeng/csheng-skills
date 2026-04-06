#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=skills/_harness-libs/contracts.sh
source "$SCRIPT_DIR/contracts.sh"

normalize_evaluation_verdict() {
  local review_status="$1"
  local verify_status="$2"

  is_valid_verdict "$review_status" || return 1
  is_valid_verdict "$verify_status" || return 1

  if [[ "$review_status" == "pass" && "$verify_status" == "pass" ]]; then
    printf 'pass\n'
    return
  fi

  if [[ "$review_status" == "needs-rollback" || "$verify_status" == "needs-rollback" ]]; then
    printf 'needs-rollback\n'
    return
  fi

  if [[ "$review_status" == "manual-decision-required" || "$verify_status" == "manual-decision-required" ]]; then
    printf 'manual-decision-required\n'
    return
  fi

  printf 'needs-fixes\n'
}

build_evaluation_verdict() {
  local review_status="$1"
  local verify_status="$2"
  local truth_sync_required="$3"
  local truth_sync_completed="$4"
  local verdict=""

  is_valid_boolean_flag "$truth_sync_required" || return 1
  is_valid_boolean_flag "$truth_sync_completed" || return 1

  verdict="$(normalize_evaluation_verdict "$review_status" "$verify_status")"

  jq -n \
    --arg review_status "$review_status" \
    --arg verify_status "$verify_status" \
    --arg verdict "$verdict" \
    --argjson truth_sync_required "$truth_sync_required" \
    --argjson truth_sync_completed "$truth_sync_completed" \
    '{
      review_status: $review_status,
      verify_status: $verify_status,
      verdict: $verdict,
      truth_sync_required: $truth_sync_required,
      truth_sync_completed: $truth_sync_completed,
      ready_for_close: (
        $verdict == "pass" and (
          ($truth_sync_required == false) or
          ($truth_sync_required == true and $truth_sync_completed == true)
        )
      )
    }'
}
