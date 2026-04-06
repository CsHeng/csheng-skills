#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# shellcheck source=skills/_harness-libs/rollback.sh
source "$ROOT_DIR/skills/_harness-libs/rollback.sh"

fail() {
  printf 'test-kernel-rollback: %s\n' "$*" >&2
  exit 1
}

main() {
  [[ "$(rollback_target_for_failure "requirement-ambiguity")" == "clarify" ]] || fail "requirement ambiguity should roll back to clarify"
  [[ "$(rollback_target_for_failure "truth-conflict")" == "truth-scan" ]] || fail "truth conflict should roll back to truth-scan"
  [[ "$(rollback_target_for_failure "boundary-mismatch")" == "design-full" ]] || fail "boundary mismatch should roll back to design-full"
  [[ "$(rollback_target_for_failure "plan-incompleteness")" == "plan" ]] || fail "plan incompleteness should roll back to plan"
  [[ "$(rollback_target_for_failure "parallel-conflict")" == "dependency-freeze" ]] || fail "parallel conflict should roll back to dependency-freeze"
  [[ "$(rollback_target_for_failure "verification-failure")" == "implement-serial" ]] || fail "verification failure should roll back to implement-serial"
  [[ "$(rollback_target_for_failure "truth-sync-failure")" == "truth-sync" ]] || fail "truth-sync failure should roll back to truth-sync"

  [[ "$(resolve_rollback_target "verification-failure" 1)" == "implement-serial" ]] || fail "first local failure should stay in implement-serial"
  [[ "$(resolve_rollback_target "verification-failure" 2)" == "dependency-freeze" ]] || fail "second local failure should escalate to dependency-freeze"
  [[ "$(resolve_rollback_target "verification-failure" 3)" == "plan" ]] || fail "third local failure should escalate to plan"
  [[ "$(resolve_rollback_target "verification-failure" 4)" == "design-lite" ]] || fail "fourth local failure should escalate to design-lite"
  [[ "$(resolve_rollback_target "verification-failure" 5)" == "design-full" ]] || fail "fifth local failure should escalate to design-full"

  [[ "$(resolve_rollback_target "plan-incompleteness" 2)" == "design-lite" ]] || fail "repeated plan incompleteness should escalate to design-lite"
  [[ "$(resolve_rollback_target "boundary-mismatch" 3)" == "design-full" ]] || fail "design-full should remain terminal in policy"

  if resolve_rollback_target "verification-failure" 0 >/dev/null 2>&1; then
    fail "failure count 0 should be rejected"
  fi
}

main "$@"
