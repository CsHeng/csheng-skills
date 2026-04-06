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
  local tmp_dir plan_file design_file

  [[ "$(default_plan_artifact_path "docs/superpowers/specs/2026-04-06-add-tier-entitlement-design.md")" == "docs/superpowers/plans/2026-04-06-add-tier-entitlement.md" ]] \
    || fail "default plan path drifted"
  [[ "$(plan_entry_phase)" == "plan" ]] || fail "plan entry phase should be plan"

  tmp_dir="$(mktemp -d)"
  plan_file="$tmp_dir/plan.md"
  design_file="$tmp_dir/design.md"

  cat >"$design_file" <<'EOF'
# Sample Design

## Implementation Surface

- impl_file_refs:
  - src/example
- test_file_refs:
  - tests/example
EOF

  cat >"$plan_file" <<'EOF'
# Sample Plan

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
- next_entry: execute-change

## Task 1: Example

- [ ] Step 1: Do work
- [ ] Step 2: Run verification

## Rollback

- failure_kind: plan-incompleteness
- rollback_entry: design-change
EOF

  validate_plan_artifact "$plan_file"

  assert_contains "$ROOT_DIR/commands/plan-change.md" 'skills/_harness-libs/plan-runner.sh' "plan command should use plan runner"
  assert_contains "$ROOT_DIR/commands/plan-change.md" 'approved design|design approval' "plan command should require approved design"
  assert_contains "$ROOT_DIR/commands/plan-change.md" 'review-change|run-review\.sh --mode plan' "plan command should route through top-level review gate"
  assert_contains "$ROOT_DIR/commands/plan-change.md" 'repair-review|suggested_next_round|max-rounds' "plan command should define bounded repair loop"
  assert_contains "$ROOT_DIR/commands/plan-change.md" 'explicit human approval|human approval|approval_status:' "plan command should stop for human approval"
}

main "$@"
