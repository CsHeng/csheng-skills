#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# shellcheck source=skills/_harness-libs/plan-runner.sh
source "$ROOT_DIR/skills/_harness-libs/plan-runner.sh"

fail() {
  printf 'test-plan-runner: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local path="$1"
  local pattern="$2"
  local message="$3"
  rg -n "$pattern" "$path" >/dev/null || fail "$message"
}

main() {
  local tmp_dir legacy_plan strict_plan partial_plan design_file

  [[ "$(default_plan_artifact_path "docs/plans/harness-kernel/2026-04-06-add-tier-entitlement-design.md")" == "docs/plans/harness-kernel/2026-04-06-add-tier-entitlement-plan.md" ]] \
    || fail "default plan path drifted"
  [[ "$(plan_entry_phase)" == "plan" ]] || fail "plan entry phase should be plan"

  tmp_dir="$(mktemp -d)"
  legacy_plan="$tmp_dir/legacy-plan.md"
  strict_plan="$tmp_dir/strict-plan.md"
  partial_plan="$tmp_dir/partial-plan.md"
  design_file="$tmp_dir/design.md"

  cat >"$design_file" <<'EOF'
# Sample Design

## Implementation Surface

- impl_file_refs:
  - src/example
  - src/example-helper
- test_file_refs:
  - tests/example
  - tests/example-integration
EOF

  cat >"$legacy_plan" <<'EOF'
# Legacy Sample Plan

## Upstream Design

- design_ref: design.md
- design_version: 2026-04-06-initial

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
- approval_status: pending
- next_entry: implement-change

## Task 1: Example

- [ ] Step 1: Do work
- [ ] Step 2: Run verification

## Rollback

- failure_kind: plan-incompleteness
- rollback_entry: design-change
EOF

  cat >"$strict_plan" <<'EOF'
# Strict Sample Plan

## Upstream Design

- design_ref: design.md
- design_version: 2026-04-06-initial

## Implementation Scope

- impl_file_refs:
  - src/example
  - src/example-helper
- test_file_refs:
  - tests/example
  - tests/example-integration
- verification_scope:
  - `bash test.sh`

## Work Package Readiness

- milestone_objective: validate the strict example flow
- non_goals:
  - no production rollout
- future_phase:
  - no follow-up phase
- decision_status: ready_for_review
- oracle_strategy: TDD for local behavior plus integration smoke verification
- acceptance_oracles:
  - `bash test.sh`
- max_review_batches: 2
- subagent_ready: true

## Review Gate

- required_entry: review-change
- required_mode: review-only

## Human Gate

- approval_required: true
- approval_status: pending
- next_entry: implement-change

## Task 1: Example Core

- task_id: task-1
- depends_on:
  - root
- scope_slice: core example flow
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
- [ ] Step 1: Do work

## Task 2: Example Integration

- task_id: task-2
- depends_on:
  - task-1
- scope_slice: integration follow-up
- impl_file_refs:
  - src/example-helper
- test_file_refs:
  - tests/example-integration
- verification_scope:
  - `bash test.sh`
- executor_mode: inline-serial
- task_review_depth: quick
- done_when:
  - helper and integration verification pass
- rollback_on_failure: plan-incompleteness
- [ ] Step 1: Extend the integration

## Rollback

- failure_kind: plan-incompleteness
- rollback_entry: design-change
EOF

  cat >"$partial_plan" <<'EOF'
# Partial Sample Plan

## Upstream Design

- design_ref: design.md
- design_version: 2026-04-06-initial

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
- approval_status: pending
- next_entry: implement-change

## Task 1: Partial

- task_id: task-1
- scope_slice: partial task metadata
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
- [ ] Step 1: Do work

## Rollback

- failure_kind: plan-incompleteness
- rollback_entry: design-change
EOF

  validate_plan_artifact "$legacy_plan"
  validate_plan_artifact "$strict_plan"
  [[ "$(plan_approval_status "$strict_plan")" == "pending" ]] || fail "plan approval status should resolve"

  if validate_plan_artifact "$partial_plan" >/dev/null 2>&1; then
    fail "partial task metadata should fail validation in compat mode once metadata appears"
  fi

  if (export PLAN_RUNNER_TASK_METADATA_MODE=strict; validate_plan_artifact "$legacy_plan") >/dev/null 2>&1; then
    fail "legacy prose-only plan should fail in strict task metadata mode"
  fi

  assert_contains "$ROOT_DIR/commands/plan-change.md" 'skills/_harness-libs/plan-runner.sh' "plan command should use plan runner"
  assert_contains "$ROOT_DIR/commands/plan-change.md" 'approved design|design approval' "plan command should require approved design"
  assert_contains "$ROOT_DIR/commands/plan-change.md" 'Work Package Readiness' "plan command should require work package readiness"
  assert_contains "$ROOT_DIR/commands/plan-change.md" 'Execution Continuity' "plan command should require execution continuity"
  assert_contains "$ROOT_DIR/commands/plan-change.md" 'confirmation_clearance' "plan command should require confirmation clearance"
  assert_contains "$ROOT_DIR/commands/plan-change.md" 'continuous_after_plan_approval' "plan command should state continuous execution mode"
  assert_contains "$ROOT_DIR/commands/plan-change.md" 'C0' "plan command should summarize whether approvals are cleared"
  assert_contains "$ROOT_DIR/commands/plan-change.md" 'executable-oracle-architecture-selector' "plan command should route non-trivial behavior to oracle selection"
  assert_contains "$ROOT_DIR/commands/plan-change.md" 'review-change|run-review\.sh --mode plan' "plan command should route through top-level review gate"
  assert_contains "$ROOT_DIR/commands/plan-change.md" 'repair-review|suggested_next_round|max-rounds' "plan command should define bounded repair loop"
  assert_contains "$ROOT_DIR/commands/plan-change.md" 'explicit human approval|human approval|approval_status:' "plan command should stop for human approval"
}

main "$@"
