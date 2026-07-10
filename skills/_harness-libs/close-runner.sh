#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=skills/_harness-libs/phase-engine.sh
source "$SCRIPT_DIR/phase-engine.sh"
# shellcheck source=skills/_harness-libs/evaluation-gate.sh
source "$SCRIPT_DIR/evaluation-gate.sh"

is_valid_close_mode() {
  case "${1:-}" in
    merge|release|cleanup) return 0 ;;
    *) return 1 ;;
  esac
}

close_entry_phase() {
  next_phase_for_entry "close-change"
}

build_close_decision() {
  local close_mode="$1"
  local review_status="$2"
  local verify_status="$3"
  local truth_sync_required="$4"
  local truth_sync_completed="$5"
  local gate_json=""

  is_valid_close_mode "$close_mode" || {
    printf 'invalid close mode: %s\n' "$close_mode" >&2
    return 1
  }

  gate_json="$(build_evaluation_verdict "$review_status" "$verify_status" "$truth_sync_required" "$truth_sync_completed")"
  jq \
    --arg close_mode "$close_mode" \
    '. + {
      close_mode: $close_mode,
      close_allowed: .ready_for_close,
      decision: (if .ready_for_close then "approved" else "blocked" end),
      next_entry: (
        if .ready_for_close then
          "close-change"
        elif .verdict == "pass" and .truth_sync_required == true and .truth_sync_completed == false then
          "sync-truth"
        else
          "implement-change"
        end
      )
    }' <<<"$gate_json"
}

validate_close_change() {
  local close_mode="$1"
  local review_status="$2"
  local verify_status="$3"
  local truth_sync_required="$4"
  local truth_sync_completed="$5"
  local decision_json=""

  decision_json="$(build_close_decision "$close_mode" "$review_status" "$verify_status" "$truth_sync_required" "$truth_sync_completed")"
  jq -e '.close_allowed == true' <<<"$decision_json" >/dev/null || {
    printf 'close gate blocked\n' >&2
    return 1
  }
}

usage() {
  cat <<'EOF'
Usage:
  close-runner.sh entry-phase
  close-runner.sh validate <merge|release|cleanup> <review-status> <verify-status> <truth-sync-required> <truth-sync-completed>
  close-runner.sh decision <merge|release|cleanup> <review-status> <verify-status> <truth-sync-required> <truth-sync-completed>
EOF
}

main() {
  local command="${1:-}"

  case "$command" in
    entry-phase)
      close_entry_phase
      ;;
    validate)
      [[ $# -eq 6 ]] || { usage >&2; return 1; }
      validate_close_change "$2" "$3" "$4" "$5" "$6"
      ;;
    decision)
      [[ $# -eq 6 ]] || { usage >&2; return 1; }
      build_close_decision "$2" "$3" "$4" "$5" "$6"
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
