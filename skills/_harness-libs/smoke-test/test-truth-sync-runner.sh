#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# shellcheck source=skills/_harness-libs/truth-sync-runner.sh
source "$ROOT_DIR/skills/_harness-libs/truth-sync-runner.sh"

fail() {
  printf 'test-truth-sync-runner: %s\n' "$*" >&2
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
  local tmp_dir pending_artifact approved_artifact invalid_artifact gate_json

  [[ "$(default_truth_sync_artifact_path "Harness Tail Gates" "2026-04-07")" == "docs/plans/changes/2026-04-07-harness-tail-gates-truth-sync.md" ]] \
    || fail "default truth-sync path drifted"
  [[ "$(truth_sync_entry_phase)" == "truth-sync" ]] || fail "truth-sync entry phase should be truth-sync"

  tmp_dir="$(mktemp -d)"
  pending_artifact="$tmp_dir/truth-sync-pending.md"
  approved_artifact="$tmp_dir/truth-sync-approved.md"
  invalid_artifact="$tmp_dir/truth-sync-invalid.md"

  cat >"$pending_artifact" <<'EOF'
# Sample Truth Sync

## Evidence

- approved_design_ref: docs/plans/changes/example-design.md
- approved_plan_ref: docs/plans/changes/example-plan.md
- review_gate_ref: artifacts/review.json
- verification_ref: artifacts/verify.log
- truth_sync_required: true

## Stable Truth Updates

- stable_truth_refs:
  - README.md
  - AGENTS.md
- stage_artifact_refs:
  - docs/plans/changes/example-design.md
- summary: Update stable truth after verified harness behavior change.

## Human Gate

- approval_required: true
- approval_status: pending
- next_entry: close-change
EOF

  cp "$pending_artifact" "$approved_artifact"
  sed -i 's/approval_status: pending/approval_status: approved/' "$approved_artifact"

  cp "$pending_artifact" "$invalid_artifact"
  sed -i 's#README.md#docs/plans/changes/example-design.md#' "$invalid_artifact"

  validate_truth_sync_artifact "$pending_artifact"
  [[ "$(truth_sync_approval_status "$pending_artifact")" == "pending" ]] || fail "pending approval status should resolve"
  [[ "$(truth_sync_approval_status "$approved_artifact")" == "approved" ]] || fail "approved approval status should resolve"

  if validate_truth_sync_artifact "$invalid_artifact" >/dev/null 2>&1; then
    fail "stage artifact refs should be rejected from stable_truth_refs"
  fi

  gate_json="$(build_truth_sync_gate_result "$pending_artifact" "pass" "pass")"
  assert_json "$gate_json" '.verdict == "pass"' "truth-sync gate should preserve pass verdict"
  assert_json "$gate_json" '.truth_sync_completed == false' "pending truth-sync should not be complete"
  assert_json "$gate_json" '.ready_for_close == false' "pending truth-sync should block close"
  assert_json "$gate_json" '.next_entry == "sync-truth"' "pending truth-sync should remain at truth-sync"

  gate_json="$(build_truth_sync_gate_result "$approved_artifact" "pass" "pass")"
  assert_json "$gate_json" '.truth_sync_completed == true' "approved truth-sync should be complete"
  assert_json "$gate_json" '.ready_for_close == true' "approved truth-sync should unlock close"
  assert_json "$gate_json" '.next_entry == "close-change"' "approved truth-sync should route to close"

  assert_contains "$ROOT_DIR/commands/sync-truth.md" 'truth-sync-runner\.sh' "sync-truth command should use truth-sync runner"
  assert_contains "$ROOT_DIR/commands/sync-truth.md" 'stable_truth_refs' "sync-truth command should preserve stable truth refs"
  assert_contains "$ROOT_DIR/commands/sync-truth.md" 'approval-status|approval_status:' "sync-truth command should expose approval gate"
  assert_contains "$ROOT_DIR/commands/sync-truth.md" 'machine-checkable gate|Do NOT ask whether to continue' "sync-truth command should report deterministic gate state"
}

main "$@"
