#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# shellcheck source=skills/_harness-libs/execute-runner.sh
source "$ROOT_DIR/skills/_harness-libs/execute-runner.sh"

fail() {
  printf 'test-execute-runner: %s\n' "$*" >&2
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
  local tmp_dir design_file approved_plan pending_plan verdict
  local -a commands allowed_touch_set

  [[ "$(execute_entry_phase)" == "implement-serial" ]] || fail "execute entry phase should stay implement-serial"

  tmp_dir="$(mktemp -d)"
  design_file="$tmp_dir/design.md"
  approved_plan="$tmp_dir/approved-plan.md"
  pending_plan="$tmp_dir/pending-plan.md"

  cat >"$design_file" <<'EOF'
# Sample Design

## Status

Approved.

## Problem

Problem text.

## Goals

- Goal

## Non-Goals

- Non-goal

## Change Classification

- request_kind: change-definition
- change_class: B
- design_strength: design-lite
- truth_impact: medium
- boundary_impact: low
- recommended_next_phase: plan

## Boundaries

- in_scope:
  - src/example.py
- out_of_scope:
  - src/other.py

## Human Gate

- approval_required: true
- approval_status: approved
- next_entry: plan-change

## Implementation Surface

- impl_file_refs:
  - src/example.py
- test_file_refs:
  - tests/test_example.py
EOF

  cat >"$approved_plan" <<'EOF'
# Approved Plan

## Upstream Design

- design_ref: design.md
- design_version: 2026-04-06-v1

## Implementation Scope

- impl_file_refs:
  - src/example.py
- test_file_refs:
  - tests/test_example.py
- verification_scope:
  - `bash test.sh`
  - `python -m pytest tests/test_example.py`

## Review Gate

- required_entry: review-change
- required_mode: review-only

## Human Gate

- approval_required: true
- approval_status: approved
- next_entry: execute-change

## Task 1: Implement Example

- [ ] Update `src/example.py`
- [ ] Run verification

## Rollback

- failure_kind: verification-failure
- rollback_entry: plan-change
EOF

  cat >"$pending_plan" <<'EOF'
# Pending Plan

## Upstream Design

- design_ref: design.md
- design_version: 2026-04-06-v1

## Implementation Scope

- impl_file_refs:
  - src/example.py
- test_file_refs:
  - tests/test_example.py
- verification_scope:
  - `bash test.sh`

## Review Gate

- required_entry: review-change
- required_mode: review-only

## Human Gate

- approval_required: true
- approval_status: pending
- next_entry: execute-change

## Task 1: Implement Example

- [ ] Update `src/example.py`

## Rollback

- failure_kind: verification-failure
- rollback_entry: plan-change
EOF

  validate_execution_plan "$approved_plan"
  if validate_execution_plan "$pending_plan" >/dev/null 2>&1; then
    fail "pending plan should not pass execution validation"
  fi

  [[ "$(execution_plan_approval_status "$approved_plan")" == "approved" ]] || fail "approved plan status should resolve"
  [[ "$(execution_plan_mode "$approved_plan")" == "serial-first" ]] || fail "execution should default to serial-first"
  [[ "$(execution_truth_sync_required "$approved_plan")" == "true" ]] || fail "medium truth impact should require truth sync"

  mapfile -t commands < <(execution_verification_commands "$approved_plan")
  [[ "${#commands[@]}" -eq 2 ]] || fail "verification commands should be extracted"
  [[ "${commands[0]}" == "bash test.sh" ]] || fail "verification commands should strip markdown quoting"
  [[ "${commands[1]}" == "python -m pytest tests/test_example.py" ]] || fail "verification commands should preserve command text"

  mapfile -t allowed_touch_set < <(execution_allowed_touch_set "$approved_plan")
  [[ "${#allowed_touch_set[@]}" -eq 2 ]] || fail "allowed touch set should come from approved plan"
  [[ " ${allowed_touch_set[*]} " == *" src/example.py "* ]] || fail "allowed touch set should include impl refs"
  [[ " ${allowed_touch_set[*]} " == *" tests/test_example.py "* ]] || fail "allowed touch set should include test refs"

  verdict="$(build_execute_gate_result "pass" "pass" "true" "false")"
  assert_json "$verdict" '.verdict == "pass"' "execute gate should preserve pass verdict"
  assert_json "$verdict" '.ready_for_close == false' "truth sync pending should block close"

  verdict="$(build_execute_gate_result "pass" "pass" "true" "true")"
  assert_json "$verdict" '.ready_for_close == true' "truth sync completion should unlock close"

  [[ "$(execute_rollback_target "verification-failure" 1)" == "implement-serial" ]] || fail "first verification failure should stay in implement-serial"
  [[ "$(execute_rollback_target "verification-failure" 2)" == "dependency-freeze" ]] || fail "repeated verification failure should escalate rollback"

  assert_contains "$ROOT_DIR/commands/execute-change.md" 'skills/_harness-libs/execute-runner.sh' "execute command should use execute runner"
  assert_contains "$ROOT_DIR/commands/execute-change.md" 'approval-status|approval_status:[[:space:]]*approved' "execute command should require approved plan"
  assert_contains "$ROOT_DIR/commands/execute-change.md" 'verification_scope|run verification' "execute command should execute verification from the plan"
  assert_contains "$ROOT_DIR/commands/execute-change.md" 'coding:review-change|review-gate\.sh' "execute command should route code review through top-level review gate"
  assert_contains "$ROOT_DIR/commands/execute-change.md" 'build_evaluation_verdict|evaluation-gate' "execute command should normalize review and verification before closure"
  assert_contains "$ROOT_DIR/commands/execute-change.md" 'resolve_rollback_target|rollback target' "execute command should define rollback behavior"
  assert_contains "$ROOT_DIR/commands/execute-change.md" 'machine-checkable gate|Do NOT ask whether to continue' "execute command should forbid hedging when gate state is clear"
}

main "$@"
