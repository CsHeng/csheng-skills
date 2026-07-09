#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# shellcheck source=skills/_harness-libs/review-runner.sh
source "$ROOT_DIR/skills/_harness-libs/review-runner.sh"

fail() {
  printf 'test-review-runner: %s\n' "$*" >&2
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
  local tmp_dir pass_json fail_json manual_json result

  [[ "$(review_entry_phase)" == "review" ]] || fail "review entry phase should be review"
  [[ "$(resolve_review_artifact_class "docs/specs/example-design.md" "")" == "design" ]] || fail "design input should route to design review"
  [[ "$(resolve_review_artifact_class "" "docs/plans/example.md")" == "plan" ]] || fail "plan input should route to plan review"
  [[ "$(resolve_review_artifact_class "" "docs/plans/example.md" "src/example.py")" == "code-impl" ]] || fail "plan plus files should route to code review"
  [[ "$(resolve_review_artifact_class "" "" "src/example.py")" == "code-impl" ]] || fail "file-only input should route to code review"

  tmp_dir="$(mktemp -d)"
  pass_json="$tmp_dir/pass.json"
  fail_json="$tmp_dir/fail.json"
  manual_json="$tmp_dir/manual.json"

  cat >"$pass_json" <<'EOF'
{
  "mode": "design",
  "host": "claude",
  "reviewer": "codex",
  "reviewer_model": "gpt-5.4",
  "review_mode": "same-driver",
  "status": "pass",
  "next_action": "stop_passed",
  "manual_intervention_required": false,
  "batch": 1,
  "round": 1,
  "max_rounds": 3,
  "suggested_next_batch": 1,
  "suggested_next_round": 1,
  "blocking_findings": [],
  "scope": {
    "mode": "design",
    "workspace_root": "/tmp/worktree",
    "workspace_mode": "isolated",
    "spec_baseline": "design",
    "plan_path": "",
    "design_path": "/tmp/worktree/docs/specs/example-design.md",
    "design_version": "2026-04-06-v1",
    "allowed_touch_set": [],
    "out_of_scope_touched_files": [],
    "files": []
  },
  "result": {
    "lens": "design",
    "verdict": "PASS",
    "summary": "Looks good.",
    "findings": [],
    "pass_rationale": "No blocking design findings remain."
  }
}
EOF

  cat >"$fail_json" <<'EOF'
{
  "mode": "plan",
  "host": "claude",
  "reviewer": "codex",
  "reviewer_model": "gpt-5.4",
  "review_mode": "same-driver",
  "status": "needs_fixes",
  "next_action": "host_fix_then_rerun",
  "manual_intervention_required": false,
  "batch": 1,
  "round": 1,
  "max_rounds": 3,
  "suggested_next_batch": 1,
  "suggested_next_round": 2,
  "blocking_findings": [
    {
      "severity": "Important",
      "location": "docs/plans/example.md:12",
      "evidence": "Missing rollback trigger.",
      "impact": "Execution can dead-end.",
      "fix": "Add rollback mapping.",
      "confidence": "high",
      "scope_class": "in_scope_blocking"
    }
  ],
  "scope": {
    "mode": "plan",
    "workspace_root": "/tmp/worktree",
    "workspace_mode": "isolated",
    "spec_baseline": "plan",
    "plan_path": "/tmp/worktree/docs/plans/example.md",
    "design_path": "/tmp/worktree/docs/specs/example-design.md",
    "design_version": "2026-04-06-v1",
    "allowed_touch_set": [],
    "out_of_scope_touched_files": [],
    "files": []
  },
  "result": {
    "lens": "plan",
    "verdict": "FAIL",
    "summary": "Blocking plan gap.",
    "findings": [
      {
        "severity": "Important",
        "location": "docs/plans/example.md:12",
        "evidence": "Missing rollback trigger.",
        "impact": "Execution can dead-end.",
        "fix": "Add rollback mapping.",
        "confidence": "high",
        "scope_class": "in_scope_blocking"
      }
    ],
    "pass_rationale": ""
  }
}
EOF

  cat >"$manual_json" <<'EOF'
{
  "mode": "code-impl",
  "host": "claude",
  "reviewer": "codex",
  "reviewer_model": "gpt-5.4",
  "review_mode": "same-driver",
  "status": "manual_review_required",
  "next_action": "human_decision_required",
  "manual_intervention_required": true,
  "batch": 1,
  "round": 3,
  "max_rounds": 3,
  "suggested_next_batch": 2,
  "suggested_next_round": 1,
  "blocking_findings": [
    {
      "severity": "Critical",
      "location": "src/example.py:10",
      "evidence": "Touched file is outside allowed touch set.",
      "impact": "Bounded repair fence is broken.",
      "fix": "Re-scope the implementation or update plan/design first.",
      "confidence": "high",
      "scope_class": "out_of_dag_issue"
    }
  ],
  "scope": {
    "mode": "code-impl",
    "workspace_root": "/tmp/worktree",
    "workspace_mode": "isolated",
    "spec_baseline": "plan",
    "plan_path": "/tmp/worktree/docs/plans/example.md",
    "design_path": "/tmp/worktree/docs/specs/example-design.md",
    "design_version": "2026-04-06-v1",
    "allowed_touch_set": [
      "src/allowed.py",
      "tests/test_allowed.py"
    ],
    "out_of_scope_touched_files": [
      "src/example.py"
    ],
    "files": [
      "src/example.py"
    ]
  },
  "result": {
    "lens": "code-impl",
    "verdict": "FAIL",
    "summary": "Implementation escaped the bounded plan surface.",
    "findings": [
      {
        "severity": "Critical",
        "location": "src/example.py:10",
        "evidence": "Touched file is outside allowed touch set.",
        "impact": "Bounded repair fence is broken.",
        "fix": "Re-scope the implementation or update plan/design first.",
        "confidence": "high",
        "scope_class": "out_of_dag_issue"
      }
    ],
    "pass_rationale": ""
  }
}
EOF

  validate_review_gate_output "$pass_json"
  validate_review_gate_output "$fail_json"
  validate_review_gate_output "$manual_json"

  [[ "$(normalize_review_gate_verdict "$pass_json")" == "pass" ]] || fail "PASS review should normalize to pass"
  [[ "$(normalize_review_gate_verdict "$fail_json")" == "needs-fixes" ]] || fail "needs_fixes review should normalize to needs-fixes"
  [[ "$(normalize_review_gate_verdict "$manual_json")" == "manual-decision-required" ]] || fail "manual review should normalize to manual decision"

  result="$(build_review_gate_result "design" "$pass_json")"
  assert_json "$result" '.artifact_class == "design"' "normalized gate result should record artifact class"
  assert_json "$result" '.verdict == "pass"' "normalized gate result should record pass verdict"
  assert_json "$result" '.blocking_findings_count == 0' "pass result should have zero blocking findings"

  result="$(build_review_gate_result "code-impl" "$manual_json")"
  assert_json "$result" '.artifact_class == "code-impl"' "normalized gate result should preserve code artifact"
  assert_json "$result" '.verdict == "manual-decision-required"' "manual review should require manual decision"
  assert_json "$result" '.manual_intervention_required == true' "manual review should be flagged"
  assert_json "$result" '.suggested_next_batch == 2 and .suggested_next_round == 1' "manual review should carry next batch controls"

  assert_contains "$ROOT_DIR/commands/review-change.md" 'skills/_harness-libs/review-runner.sh' "review command should use review runner"
  assert_contains "$ROOT_DIR/commands/review-change.md" 'JSON_BEGIN|STDERR_BEGIN|EXIT_CODE=' "review command should require structured subagent output"
  assert_contains "$ROOT_DIR/commands/review-change.md" 'validate_review_gate_output|review-runner\.sh validate-output' "review command should validate lower-plane review output"
  assert_contains "$ROOT_DIR/commands/review-change.md" 'build_review_gate_result|normalized gate result' "review command should normalize lower-plane verdicts"
  assert_contains "$ROOT_DIR/commands/review-change.md" 'batch <= 2|suggested_next_batch > 2|budget_exhausted' "review command should enforce review batch budget"
  assert_contains "$ROOT_DIR/commands/review-change.md" 'machine-checkable gate|Do NOT ask whether to continue' "review command should forbid hedging when gate state is clear"
}

main "$@"
