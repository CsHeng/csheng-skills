#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# shellcheck source=skills/_harness-libs/task-ledger.sh
source "$ROOT_DIR/skills/_harness-libs/task-ledger.sh"

fail() {
  printf 'test-task-ledger: %s\n' "$*" >&2
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
  local tmp_dir design_file plan_file legacy_plan ledger_file result_json next_ready
  local ledger_json=""
  local updated_json=""

  tmp_dir="$(mktemp -d)"
  design_file="$tmp_dir/design.md"
  plan_file="$tmp_dir/plan.md"
  legacy_plan="$tmp_dir/legacy-plan.md"
  ledger_file="$tmp_dir/ledger.json"

  cat >"$design_file" <<'EOF'
# Sample Design

## Status

- approval_status: approved

## Problem

Problem.

## Goals

- Goal

## Non-Goals

- Non-goal

## Change Classification

- request_kind: change-definition
- change_class: B
- design_strength: design-lite
- truth_impact: low
- boundary_impact: medium
- recommended_next_phase: plan

## Boundaries

- in_scope:
  - src/example

## Human Gate

- approval_required: true
- approval_status: approved
- next_entry: plan-change

## Implementation Surface

- impl_file_refs:
  - src/example
  - src/helper
- test_file_refs:
  - tests/example
  - tests/helper
EOF

cat >"$plan_file" <<'EOF'
# Sample Task-Ledger Plan

## Upstream Design

- design_ref: design.md
- design_version: 2026-04-09-initial

## Implementation Scope

- impl_file_refs:
  - src/example
  - src/helper
- test_file_refs:
  - tests/example
  - tests/helper
- verification_scope:
  - `bash test.sh`

## Review Gate

- required_entry: review-change
- required_mode: review-only

## Human Gate

- approval_required: true
- approval_status: approved
- next_entry: execute-change

## Task 1: Core Example

- task_id: task-1
- depends_on:
  - root
- scope_slice: core example work
- impl_file_refs:
  - src/example
- test_file_refs:
  - tests/example
- verification_scope:
  - `bash test.sh`
- executor_mode: inline-serial
- task_review_depth: quick
- done_when:
  - `bash test.sh` succeeds
- rollback_on_failure: plan-incompleteness
- [ ] Step 1: Implement core example

## Task 2: Helper Follow-up

- task_id: task-2
- depends_on:
  - task-1
- scope_slice: helper follow-up
- impl_file_refs:
  - src/helper
- test_file_refs:
  - tests/helper
- verification_scope:
  - `bash test.sh`
- executor_mode: inline-serial
- task_review_depth: quick
- done_when:
  - helper verification passes
- rollback_on_failure: plan-incompleteness
- [ ] Step 1: Implement helper

## Rollback

- failure_kind: plan-incompleteness
- rollback_entry: design-change
EOF

  cat >"$legacy_plan" <<'EOF'
# Legacy Task-Ledger Plan

## Upstream Design

- design_ref: design.md
- design_version: 2026-04-09-initial

## Implementation Scope

- impl_file_refs:
  - src/example
- test_file_refs:
  - tests/example
- verification_scope:
  - `bash test.sh`

## Review Gate

- required_entry: review-change
- required_mode: review-only

## Human Gate

- approval_required: true
- approval_status: approved
- next_entry: execute-change

## Task 1: Legacy Example

- [ ] Step 1: Do work

## Rollback

- failure_kind: plan-incompleteness
- rollback_entry: design-change
EOF

  ledger_json="$(task_ledger_json "$plan_file")"
  assert_json "$ledger_json" 'length == 2' "task ledger should include both tasks"
  assert_json "$ledger_json" '.[0].task_id == "task-1" and .[0].status == "ready"' "first task should start ready"
  assert_json "$ledger_json" '.[1].task_id == "task-2" and .[1].status == "pending"' "dependent task should start pending"

  printf '%s\n' "$ledger_json" >"$ledger_file"
  next_ready="$(task_ledger_next_ready_task_id "$ledger_file")"
  [[ "$next_ready" == "task-1" ]] || fail "next ready task should be task-1"

  updated_json="$(task_ledger_set_status "$ledger_file" "task-1" "in_progress")"
  assert_json "$updated_json" '.[] | select(.task_id == "task-1") | .status == "in_progress"' "task-1 should enter in_progress"
  printf '%s\n' "$updated_json" >"$ledger_file"

  updated_json="$(task_ledger_set_status "$ledger_file" "task-1" "in_review")"
  assert_json "$updated_json" '.[] | select(.task_id == "task-1") | .status == "in_review"' "task-1 should enter in_review"
  printf '%s\n' "$updated_json" >"$ledger_file"

  updated_json="$(task_ledger_set_status "$ledger_file" "task-1" "done")"
  assert_json "$updated_json" '.[] | select(.task_id == "task-1") | .status == "done" and (.completed_at != null)' "task-1 should complete with timestamp"
  printf '%s\n' "$updated_json" >"$ledger_file"

  updated_json="$(task_ledger_refresh_ready_states "$ledger_file")"
  assert_json "$updated_json" '.[] | select(.task_id == "task-2") | .status == "ready"' "task-2 should become ready once dependency is done"
  printf '%s\n' "$updated_json" >"$ledger_file"

  if task_ledger_json "$legacy_plan" >/dev/null 2>&1; then
    fail "legacy prose-only plan should not materialize a task ledger"
  fi

  result_json="$(build_execution_result "$plan_file" "$ledger_file" "implement-serial" "task-2" "task_blocked_requires_human" "pending" "pending" "execute-change" "implement-serial" "true" "current-checkout")"
  assert_json "$result_json" '.completed_task_count == 1' "execution result should report completed task count"
  assert_json "$result_json" '.remaining_task_count == 1' "execution result should report remaining task count"
  assert_json "$result_json" '.stop_reason == "task_blocked_requires_human"' "execution result should preserve stop reason"
  assert_json "$result_json" '.human_input_required == true' "execution result should preserve human-input flag"
}

main "$@"
