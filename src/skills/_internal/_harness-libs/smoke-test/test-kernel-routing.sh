#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# shellcheck source=skills/_harness-libs/classifier.sh
source "$ROOT_DIR/skills/_harness-libs/classifier.sh"
# shellcheck source=skills/_harness-libs/router.sh
source "$ROOT_DIR/skills/_harness-libs/router.sh"

fail() {
  printf 'test-kernel-routing: %s\n' "$*" >&2
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
  local record

  record="$(classify_change "change-execution" "low" "low" "false")"
  assert_json "$record" '.request_kind == "change-execution"' "leaf request kind mismatch"
  assert_json "$record" '.change_class == "A"' "leaf change should stay class A"
  assert_json "$record" '.design_strength == "no-design"' "leaf change should stay no-design"
  assert_json "$record" '.truth_sync_required == false' "leaf change should not require truth sync"
  assert_json "$record" '.parallel_candidate == false' "leaf change should stay serial-first"
  assert_json "$record" '.recommended_next_phase == "implement-serial"' "leaf change should start in implement-serial"
  assert_json "$record" '.recommended_entry == "execute-change"' "leaf change should route to execute-change"
  [[ "$(route_classification_record "$record")" == "execute-change" ]] || fail "classification record should route to execute-change"

  record="$(classify_change "change-definition" "medium" "low" "false")"
  assert_json "$record" '.change_class == "B"' "medium truth impact should become class B"
  assert_json "$record" '.design_strength == "design-lite"' "class B should trigger design-lite"
  assert_json "$record" '.truth_sync_required == true' "class B should require truth sync"
  assert_json "$record" '.parallel_candidate == true' "class B should only be a future parallel candidate"
  assert_json "$record" '.recommended_next_phase == "design-lite"' "class B should route into design-lite"
  assert_json "$record" '.recommended_entry == "design-change"' "class B definition work should route to design-change"
  [[ "$(route_classification_record "$record")" == "design-change" ]] || fail "classification record should route to design-change"

  record="$(classify_change "change-planning" "high" "high" "false")"
  assert_json "$record" '.change_class == "C"' "high boundary impact should become class C"
  assert_json "$record" '.design_strength == "design-full"' "class C should trigger design-full"
  assert_json "$record" '.truth_sync_required == true' "class C should require truth sync"
  assert_json "$record" '.parallel_candidate == false' "class C should not default to parallel"
  assert_json "$record" '.recommended_next_phase == "design-full"' "class C should route into design-full"
  assert_json "$record" '.recommended_entry == "design-change"' "design-required work should route to design-change first"
  [[ "$(route_classification_record "$record")" == "design-change" ]] || fail "classification record should route to design-change"

  record="$(classify_change "truth-maintenance" "high" "low" "true")"
  assert_json "$record" '.change_class == "D"' "truth repair should become class D"
  assert_json "$record" '.design_strength == "design-lite"' "truth repair should stay design-lite until a boundary break is proven"
  assert_json "$record" '.truth_sync_required == true' "truth repair should require truth sync"
  assert_json "$record" '.parallel_candidate == false' "truth repair should stay serial-first"
  assert_json "$record" '.recommended_next_phase == "design-lite"' "truth repair should re-enter the design spine before later truth sync"
  assert_json "$record" '.recommended_entry == "design-change"' "truth repair should route to design-change before sync-truth"
  [[ "$(route_classification_record "$record")" == "design-change" ]] || fail "classification record should route to design-change"

  [[ "$(route_request_kind "state-query")" == "analyze-project" ]] || fail "state-query should route to analyze-project"
  [[ "$(route_request_kind "artifact-review")" == "review-change" ]] || fail "artifact-review should route to review-change"
  [[ "$(route_request_kind "integration-closeout")" == "close-change" ]] || fail "integration-closeout should route to close-change"

  if route_request_kind "unknown-kind" >/dev/null 2>&1; then
    fail "unknown request kind should fail"
  fi

  if classify_change "state-query" "invalid" "low" "false" >/dev/null 2>&1; then
    fail "invalid truth impact should fail classification"
  fi
}

main "$@"
