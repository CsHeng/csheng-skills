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
  assert_contains "commands/review-change.md" '--timeout <seconds>' "review command should expose timeout control"
  assert_contains "commands/review-change.md" 'args\+=\(--timeout "\{timeout_seconds\}"\)|Bash tool.*timeout' "review command should apply the same timeout to Bash tool and lower-plane review"
  assert_contains "commands/review-change.md" 'validate_review_gate_output|review-runner\.sh validate-output' "review command should validate lower-plane review output"
  assert_contains "commands/review-change.md" 'build_review_gate_result|normalized gate result' "review command should normalize lower-plane review into harness verdict"
  assert_contains "commands/review-change.md" 'machine-checkable gate|Do NOT ask whether to continue' "review command should report deterministic stop states"

  assert_contains "commands/review-plan.md" '--timeout <seconds>' "review-plan command should expose timeout control"
  assert_contains "commands/review-plan.md" 'args\+=\(--timeout "\$timeout_seconds"\)|Bash tool.*timeout' "review-plan command should apply the same timeout to Bash tool and shared runner"
  assert_contains "commands/review-design.md" '--timeout <seconds>' "review-design command should expose timeout control"
  assert_contains "commands/review-design.md" 'args\+=\(--timeout "\$timeout_seconds"\)|Bash tool.*timeout' "review-design command should apply the same timeout to Bash tool and shared runner"
  assert_contains "commands/review-implementation.md" '--timeout <seconds>' "review-implementation command should expose timeout control"
  assert_contains "commands/review-implementation.md" 'args\+=\(--timeout "\$timeout_seconds"\)|Bash tool.*timeout' "review-implementation command should apply the same timeout to Bash tool and shared runner"

  assert_contains "commands/implement-change.md" 'execute-runner\.sh' "execute command should use execute runner"
  assert_contains "commands/implement-change.md" 'approval-status|approval_status:[[:space:]]*approved' "execute command should machine-check approved plan"
  assert_contains "commands/implement-change.md" 'implement-serial|serial-first' "execute command should stay serial-first by default"
  assert_contains "commands/implement-change.md" 'workspace-mode|worktree-preflight-required|git-worktrees' "execute command should perform one-time worktree preflight"
  assert_contains "commands/implement-change.md" 'allowed_touch_set|impl_file_refs|test_file_refs' "execute command should respect bounded touch set"
  assert_contains "commands/implement-change.md" 'task-catalog|task-ledger|current_task|completed_task_count|remaining_task_count' "execute command should materialize task progress from a task ledger"
  assert_contains "commands/implement-change.md" 'task-scoped review|coding:review-change|quick|thorough' "execute command should define task-level review cadence"
  assert_contains "commands/implement-change.md" 'coding:review-change|review-gate\.sh' "execute command should hand off to top-level review gate"
  assert_contains "commands/implement-change.md" 'verification_scope|build_evaluation_verdict|evaluation-gate' "execute command should combine review and verification before next phase"
  assert_contains "commands/implement-change.md" 'resolve_rollback_target|rollback target' "execute command should define rollback and escalation"
  assert_contains "commands/implement-change.md" 'sync-truth|close-change|manual gate|rollback' "execute command should emit explicit next state"
  assert_contains "commands/implement-change.md" 'machine-checkable gate|Do NOT ask whether to continue' "execute command should not hedge when gate state is known"
}

main "$@"
