#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# shellcheck source=skills/_harness-libs/close-runner.sh
source "$ROOT_DIR/skills/_harness-libs/close-runner.sh"

fail() {
  printf 'test-close-runner: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local path="$1"
  local pattern="$2"
  local message="$3"

  rg -n -- "$pattern" "$path" >/dev/null || fail "$message"
}

assert_json() {
  local json="$1"
  local expr="$2"
  local message="$3"

  if ! jq -e "$expr" <<<"$json" >/dev/null; then
    fail "$message"
  fi
}

main() {
  local decision_json

  [[ "$(close_entry_phase)" == "close" ]] || fail "close entry phase should be close"
  is_valid_close_mode "merge" || fail "merge should be valid close mode"
  if is_valid_close_mode "destroy"; then
    fail "destroy should not be a valid close mode"
  fi

  decision_json="$(build_close_decision "merge" "pass" "pass" "true" "false")"
  assert_json "$decision_json" '.decision == "blocked"' "truth-sync pending should block close"
  assert_json "$decision_json" '.close_allowed == false' "truth-sync pending should not allow close"
  assert_json "$decision_json" '.next_entry == "sync-truth"' "truth-sync pending should route back to truth-sync"

  if validate_close_change "merge" "pass" "pass" "true" "false" >/dev/null 2>&1; then
    fail "close validation should fail when truth sync is pending"
  fi

  decision_json="$(build_close_decision "merge" "pass" "pass" "true" "true")"
  assert_json "$decision_json" '.decision == "approved"' "complete truth-sync should approve close decision"
  assert_json "$decision_json" '.close_allowed == true' "complete truth-sync should allow close"
  assert_json "$decision_json" '.next_entry == "close-change"' "complete truth-sync should stay at close"
  validate_close_change "merge" "pass" "pass" "true" "true"

  decision_json="$(build_close_decision "cleanup" "needs-fixes" "pass" "false" "false")"
  assert_json "$decision_json" '.decision == "blocked"' "review fixes should block close"
  assert_json "$decision_json" '.next_entry == "implement-change"' "review fixes should route back to execution"

  assert_contains "$ROOT_DIR/commands/close-change.md" 'close-runner\.sh' "close command should use close runner"
  assert_contains "$ROOT_DIR/commands/close-change.md" 'review-status|verify-status' "close command should require review and verify status"
  assert_contains "$ROOT_DIR/commands/close-change.md" 'truth-sync-required|truth_sync_required' "close command should check truth sync requirement"
  assert_contains "$ROOT_DIR/commands/close-change.md" 'machine-checkable gate|Do NOT ask whether to continue' "close command should report deterministic gate state"
}

main "$@"
