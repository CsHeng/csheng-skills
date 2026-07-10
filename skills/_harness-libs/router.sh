#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=skills/_harness-libs/contracts.sh
source "$SCRIPT_DIR/contracts.sh"

route_request_kind() {
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

route_entry() {
  route_request_kind "$1"
}

route_classification_record() {
  local classification_record="$1"
  local recommended_entry=""
  local request_kind=""

  recommended_entry="$(jq -r '.recommended_entry // empty' <<<"$classification_record")"
  if [[ -n "$recommended_entry" ]]; then
    is_valid_entry "$recommended_entry" || return 1
    printf '%s\n' "$recommended_entry"
    return
  fi

  request_kind="$(jq -r '.request_kind // empty' <<<"$classification_record")"
  [[ -n "$request_kind" ]] || return 1

  route_request_kind "$request_kind"
}
