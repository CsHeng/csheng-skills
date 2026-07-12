#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

fail() {
  printf 'test-review-execute-command-control: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local path="$1" pattern="$2" message="$3"
  rg -n -- "$pattern" "$ROOT_DIR/$path" >/dev/null || fail "$message"
}

main() {
  assert_contains "commands/review-change.md" 'bounded review brief' "review command should build a bounded brief"
  assert_contains "commands/review-change.md" 'reviewer subagent' "review command should prefer subagent review"
  assert_contains "commands/review-change.md" 'review directly' "review command should allow main-agent review"
  assert_contains "commands/review-change.md" 'accepted' "review command should expose main-agent adjudication"
  assert_contains "commands/review-change.md" 'machine-checkable' "review command should return typed verdicts"

  assert_contains "commands/review-design.md" 'bounded' "design review command should stay bounded"
  assert_contains "commands/review-plan.md" 'bounded' "plan review command should stay bounded"
  assert_contains "commands/review-implementation.md" 'causal' "implementation review command should require causality"

  assert_contains "commands/implement-change.md" 'execute-runner\.sh' "execute command should retain deterministic execution runner"
  assert_contains "commands/implement-change.md" 'approval_status:[[:space:]]*approved' "execute command should require plan approval"
  assert_contains "commands/implement-change.md" 'serial-first' "execute command should remain serial-first"
  assert_contains "commands/implement-change.md" 'allowed_touch_set' "execute command should preserve touch-set enforcement"
  assert_contains "commands/implement-change.md" 'task ledger' "execute command should retain task progress"
  assert_contains "commands/implement-change.md" 'coding:review-change' "execute command should use top-level review semantics"
  assert_contains "commands/implement-change.md" 'accepted' "execute command should repair accepted findings only"
  assert_contains "commands/implement-change.md" 'evaluation gate' "execute command should combine review and verification"
  assert_contains "commands/implement-change.md" 'machine-checkable' "execute command should return typed states"

  bash "$ROOT_DIR/src/skills/_internal/_harness-libs/smoke-test/test-agent-native-review.sh"
}

main "$@"
