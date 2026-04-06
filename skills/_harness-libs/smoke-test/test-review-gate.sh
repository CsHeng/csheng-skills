#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# shellcheck source=skills/_harness-libs/review-gate.sh
source "$ROOT_DIR/skills/_harness-libs/review-gate.sh"

fail() {
  printf 'test-review-gate: %s\n' "$*" >&2
  exit 1
}

main() {
  [[ "$(review_mode_for_artifact design)" == "design" ]] || fail "design artifact should route to design mode"
  [[ "$(review_mode_for_artifact plan)" == "plan" ]] || fail "plan artifact should route to plan mode"
  [[ "$(review_mode_for_artifact code-impl)" == "code-impl" ]] || fail "code artifact should route to code-impl mode"

  if review_mode_for_artifact unknown >/dev/null 2>&1; then
    fail "unknown artifact should fail"
  fi

  runner="$(default_review_runner_path)"
  [[ -n "$runner" ]] || fail "review gate should resolve shared review runner path"
  [[ "$runner" == */skills/_review-libs/run-review.sh ]] || fail "review gate should point at shared review runner"
}

main "$@"
