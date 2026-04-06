#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# shellcheck source=skills/_harness-libs/design-runner.sh
source "$ROOT_DIR/skills/_harness-libs/design-runner.sh"

fail() {
  printf 'test-design-runner: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local path="$1"
  local pattern="$2"
  local message="$3"
  rg -n "$pattern" "$path" >/dev/null || fail "$message"
}

main() {
  local tmp_dir design_file

  [[ "$(default_design_artifact_path "Add Tier Entitlement" "2026-04-06")" == "docs/superpowers/specs/2026-04-06-add-tier-entitlement-design.md" ]] \
    || fail "default design path drifted"
  [[ "$(design_entry_phase)" == "clarify" ]] || fail "design entry phase should be clarify"

  tmp_dir="$(mktemp -d)"
  design_file="$tmp_dir/design.md"

  cat >"$design_file" <<'EOF'
# Sample Design

## Status

Proposed.

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
- recommended_next_phase: design-lite

## Boundaries

- in_scope:
  - src/example
- out_of_scope:
  - src/other

## Human Gate

- approval_required: true
- approval_status: pending
- next_entry: plan-change

## Implementation Surface

- impl_file_refs:
  - src/example
- test_file_refs:
  - tests/example
EOF

  validate_design_artifact "$design_file"

  assert_contains "$ROOT_DIR/commands/design-change.md" 'skills/_harness-libs/design-runner.sh' "design command should use design runner"
  assert_contains "$ROOT_DIR/commands/design-change.md" 'classify_change|classification record' "design command should enforce classification"
  assert_contains "$ROOT_DIR/commands/design-change.md" 'review-change|run-review\.sh --mode design' "design command should route through top-level review gate"
  assert_contains "$ROOT_DIR/commands/design-change.md" 'repair-review|suggested_next_round|max-rounds' "design command should define bounded repair loop"
  assert_contains "$ROOT_DIR/commands/design-change.md" 'explicit human approval|human approval|approval_status:' "design command should stop for human approval"
}

main "$@"
