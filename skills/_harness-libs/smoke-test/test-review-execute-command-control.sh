#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

fail() {
  printf 'test-review-execute-command-control: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local path="$1"
  local pattern="$2"
  local message="$3"
  rg -n -- "$pattern" "$ROOT_DIR/$path" >/dev/null || fail "$message"
}

main() {
  assert_contains "commands/review-change.md" 'JSON_BEGIN|STDERR_BEGIN|EXIT_CODE=' "review command should use structured runner output"
  assert_contains "commands/review-change.md" 'review-runner\.sh' "review command should use review runner"
  assert_contains "commands/review-change.md" 'design|plan|code-impl' "review command should classify artifact types explicitly"
  assert_contains "commands/review-change.md" '--plan|--file' "review command should support plan-scoped code review"
  assert_contains "commands/review-change.md" 'validate_review_gate_output|review-runner\.sh validate-output' "review command should validate lower-plane review output"
  assert_contains "commands/review-change.md" 'build_review_gate_result|normalized gate result' "review command should normalize lower-plane review into harness verdict"
  assert_contains "commands/review-change.md" 'machine-checkable gate|Do NOT ask whether to continue' "review command should report deterministic stop states"

  assert_contains "commands/execute-change.md" 'execute-runner\.sh' "execute command should use execute runner"
  assert_contains "commands/execute-change.md" 'approval-status|approval_status:[[:space:]]*approved' "execute command should machine-check approved plan"
  assert_contains "commands/execute-change.md" 'implement-serial|serial-first' "execute command should stay serial-first by default"
  assert_contains "commands/execute-change.md" 'allowed_touch_set|impl_file_refs|test_file_refs' "execute command should respect bounded touch set"
  assert_contains "commands/execute-change.md" 'coding:review-change|review-gate\.sh' "execute command should hand off to top-level review gate"
  assert_contains "commands/execute-change.md" 'verification_scope|build_evaluation_verdict|evaluation-gate' "execute command should combine review and verification before next phase"
  assert_contains "commands/execute-change.md" 'resolve_rollback_target|rollback target' "execute command should define rollback and escalation"
  assert_contains "commands/execute-change.md" 'sync-truth|close-change|manual gate|rollback' "execute command should emit explicit next state"
  assert_contains "commands/execute-change.md" 'machine-checkable gate|Do NOT ask whether to continue' "execute command should not hedge when gate state is known"
}

main "$@"
