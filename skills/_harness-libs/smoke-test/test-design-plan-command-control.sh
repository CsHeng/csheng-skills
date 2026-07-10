#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

fail() {
  printf 'test-design-plan-command-control: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local path="$1"
  local pattern="$2"
  local message="$3"
  rg -n "$pattern" "$ROOT_DIR/$path" >/dev/null || fail "$message"
}

main() {
  assert_contains "commands/design-change.md" 'JSON_BEGIN|STDERR_BEGIN|EXIT_CODE=' "design command should use structured subagent runner output"
  assert_contains "commands/design-change.md" 'validate_design_artifact|design-runner\.sh validate' "design command should validate artifact before review"
  assert_contains "commands/design-change.md" 'review-gate\.sh|coding:review-change' "design command should route through top-level review gate"
  assert_contains "commands/design-change.md" 'approval_status:[[:space:]]*pending|approval_status:[[:space:]]*approved' "design command should carry approval status gate"
  assert_contains "commands/design-change.md" 'coding:plan-change|next_entry: plan-change' "design command should hand off explicitly"
  assert_contains "commands/design-change.md" 'Do NOT ask whether to continue|explicit human approval gate' "design command should report deterministic human gate state"

  assert_contains "commands/plan-change.md" 'JSON_BEGIN|STDERR_BEGIN|EXIT_CODE=' "plan command should use structured subagent runner output"
  assert_contains "commands/plan-change.md" 'validate_plan_artifact|plan-runner\.sh validate' "plan command should validate artifact before review"
  assert_contains "commands/plan-change.md" 'review-gate\.sh|coding:review-change' "plan command should route through top-level review gate"
  assert_contains "commands/plan-change.md" 'approval-status|approval_status:[[:space:]]*approved' "plan command should machine-check approved upstream design"
  assert_contains "commands/plan-change.md" 'approval_status:[[:space:]]*pending|approval_status:[[:space:]]*approved' "plan command should carry approval status gate"
  assert_contains "commands/plan-change.md" 'coding:implement-change|next_entry: implement-change' "plan command should hand off explicitly"
  assert_contains "commands/plan-change.md" 'Do NOT ask whether to continue|explicit human approval gate' "plan command should report deterministic human gate state"
}

main "$@"
