#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# shellcheck source=skills/_harness-libs/phase-engine.sh
source "$ROOT_DIR/skills/_harness-libs/phase-engine.sh"
# shellcheck source=skills/_harness-libs/evaluation-gate.sh
source "$ROOT_DIR/skills/_harness-libs/evaluation-gate.sh"

fail() {
  printf 'test-kernel-phase: %s\n' "$*" >&2
  exit 1
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
  local verdict

  [[ "$(next_phase_for_entry "analyze-project")" == "truth-scan" ]] || fail "analyze-project should start at truth-scan"
  [[ "$(next_phase_for_entry "design-change")" == "clarify" ]] || fail "design-change should start at clarify"
  [[ "$(next_phase_for_entry "implement-change")" == "implement-serial" ]] || fail "implement-change should stay serial-first"
  [[ "$(next_phase_for_entry "close-change")" == "close" ]] || fail "close-change should route to close"

  phase_requires_human_approval "plan" || fail "plan should require approval"
  phase_requires_human_approval "truth-sync" || fail "truth-sync should require approval"
  if phase_requires_human_approval "verify"; then
    fail "verify should not require human approval"
  fi

  [[ "$(resolve_next_phase "clarify" "no-design" "false" "false")" == "plan" ]] || fail "no-design path should move clarify to plan"
  [[ "$(resolve_next_phase "clarify" "design-full" "false" "false")" == "design-full" ]] || fail "design-full path should stay explicit"
  [[ "$(resolve_next_phase "dependency-freeze" "design-lite" "false" "false")" == "implement-serial" ]] || fail "dependency freeze should default to implement-serial"
  [[ "$(resolve_next_phase "dependency-freeze" "design-lite" "false" "true")" == "implement-parallel" ]] || fail "parallel should require explicit approval"
  [[ "$(resolve_next_phase "verify" "design-lite" "true" "false")" == "truth-sync" ]] || fail "truth impact should force truth-sync after verify"
  [[ "$(resolve_next_phase "verify" "design-lite" "false" "false")" == "close" ]] || fail "no truth impact should close after verify"

  [[ "$(normalize_evaluation_verdict "pass" "pass")" == "pass" ]] || fail "pass/pass should normalize to pass"
  [[ "$(normalize_evaluation_verdict "needs-fixes" "pass")" == "needs-fixes" ]] || fail "needs-fixes should hold the gate"
  [[ "$(normalize_evaluation_verdict "pass" "needs-rollback")" == "needs-rollback" ]] || fail "needs-rollback should outrank pass"
  [[ "$(normalize_evaluation_verdict "manual-decision-required" "pass")" == "manual-decision-required" ]] || fail "manual decision should survive normalization"

  verdict="$(build_evaluation_verdict "needs-fixes" "pass" "false" "false")"
  assert_json "$verdict" '.verdict == "needs-fixes"' "verdict json should include normalized verdict"
  assert_json "$verdict" '.review_status == "needs-fixes"' "verdict json should include review status"
  assert_json "$verdict" '.verify_status == "pass"' "verdict json should include verify status"
  assert_json "$verdict" '.truth_sync_required == false and .truth_sync_completed == false' "verdict json should record truth-sync state"
  assert_json "$verdict" '.ready_for_close == false' "needs-fixes verdict should not be close-ready"

  verdict="$(build_evaluation_verdict "pass" "pass" "true" "false")"
  assert_json "$verdict" '.verdict == "pass"' "pass verdict should preserve pass"
  assert_json "$verdict" '.truth_sync_required == true and .truth_sync_completed == false' "truth-sync state should be visible"
  assert_json "$verdict" '.ready_for_close == false' "truth-affecting changes should not be close-ready before truth sync"

  verdict="$(build_evaluation_verdict "pass" "pass" "true" "true")"
  assert_json "$verdict" '.verdict == "pass" and .ready_for_close == true' "pass verdict should be close-ready after truth sync"
}

main "$@"
