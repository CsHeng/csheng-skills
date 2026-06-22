#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# shellcheck source=skills/_review-libs/output-validator.sh
source "$ROOT_DIR/skills/_review-libs/output-validator.sh"
# shellcheck source=skills/_review-libs/prompt-builder.sh
source "$ROOT_DIR/skills/_review-libs/prompt-builder.sh"

fail() {
  printf 'test-review-gating: %s\n' "$*" >&2
  exit 1
}

log() {
  :
}

die() {
  local code=1
  if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
    code="$1"
    shift
  fi
  fail "$*"
  exit "$code"
}

assert_run_field() {
  local run_output="$1"
  local jq_expr="$2"
  local message="$3"
  if ! jq -e "$jq_expr" "$run_output" >/dev/null; then
    fail "$message"
  fi
}

assert_run_field_with_scope_class() {
  local run_output="$1"
  local expected_scope_class="$2"
  local message="$3"
  if ! jq -e --arg scope_class "$expected_scope_class" \
    '.status == "manual_review_required" and .next_action == "human_decision_required" and .manual_intervention_required == true and .result.verdict == "FAIL" and (.blocking_findings | length) == 1 and .blocking_findings[0].scope_class == $scope_class' \
    "$run_output" >/dev/null; then
    fail "$message"
  fi
}

assert_file_contains() {
  local path="$1"
  local needle="$2"
  local message="$3"
  if ! grep -Fq "$needle" "$path"; then
    fail "$message"
  fi
}

pick_reviewer_with_mocked_drivers() {
  local host="$1"
  local reviewer="$2"
  local cross_mode="$3"

  RUN_REVIEW_SOURCE_ONLY=1 bash -s "$ROOT_DIR/skills/_review-libs/run-review.sh" "$host" "$reviewer" "$cross_mode" <<'BASH'
set -euo pipefail
source "$1"
driver_is_available() {
  case "$1" in
    claude|codex|gemini) return 0 ;;
    *) return 1 ;;
  esac
}
HOST="$2"
REVIEWER="$3"
REVIEW_STRATEGY="$4"
ALLOW_FALLBACK=0
pick_reviewer
BASH
}

assert_reviewer_selection_contract() {
  local selected

  selected="$(pick_reviewer_with_mocked_drivers "codex" "auto" "same")" \
    || fail "same-model default reviewer selection should succeed"
  [[ "$selected" == "codex" ]] || fail "auto reviewer should default to same driver; got $selected"

  selected="$(pick_reviewer_with_mocked_drivers "codex" "auto" "cross")" \
    || fail "explicit cross-model reviewer selection should succeed"
  [[ "$selected" == "claude" ]] || fail "cross-model reviewer should select opposite driver; got $selected"

  selected="$(pick_reviewer_with_mocked_drivers "codex" "auto" "adversarial")" \
    || fail "explicit adversarial reviewer selection should succeed"
  [[ "$selected" == "claude" ]] || fail "adversarial reviewer should select opposite driver; got $selected"

  if pick_reviewer_with_mocked_drivers "codex" "claude" "same" >/dev/null 2>&1; then
    fail "explicit opposite reviewer should require --cross-model or --adversarial"
  fi
}

write_reviewer_output() {
  local target="$1"
  local verdict="$2"
  local scope_class="$3"

  jq -n \
    --arg verdict "$verdict" \
    --arg scope_class "$scope_class" '
      {
        lens: "requirements,architecture,test-strategy",
        verdict: $verdict,
        summary: "Synthetic reviewer output for gating test",
        findings: [
          {
            severity: "Important",
            location: "Section 2.1",
            evidence: "The baseline artifact does not match the reviewed change.",
            impact: "The host could repair against the wrong baseline.",
            fix: "Escalate to a human before any repair loop continues.",
            confidence: "high",
            scope_class: $scope_class
          }
        ],
        pass_rationale: (if $verdict == "PASS" then "Reviewer claimed pass." else "" end)
      }
    ' > "$target"
}

write_mixed_reviewer_output() {
  local target="$1"

  jq -n '
      {
        lens: "requirements,architecture,test-strategy",
        verdict: "FAIL",
        summary: "Synthetic mixed reviewer output for gating test",
        findings: [
          {
            severity: "Important",
            location: "Section 2.1",
            evidence: "The baseline artifact does not match the reviewed change.",
            impact: "The host could repair against the wrong baseline.",
            fix: "Escalate to a human before any repair loop continues.",
            confidence: "high",
            scope_class: "baseline_mismatch"
          },
          {
            severity: "Important",
            location: "skills/_review-libs/output-validator.sh:300",
            evidence: "A fix exists inside the approved file set.",
            impact: "The code remains incorrect until the host applies the patch.",
            fix: "Patch the implementation in the approved file.",
            confidence: "high",
            scope_class: "in_scope_blocking"
          }
        ],
        pass_rationale: ""
      }
    ' > "$target"
}

main() {
  local scope_json baseline_reviewer in_scope_reviewer mixed_reviewer run_output prompt_output design_prompt_output
  local scope_class
  scope_json="$(mktemp)"
  baseline_reviewer="$(mktemp)"
  in_scope_reviewer="$(mktemp)"
  mixed_reviewer="$(mktemp)"
  run_output="$(mktemp)"
  prompt_output="$(mktemp)"
  design_prompt_output="$(mktemp)"

  MODE="code-impl"
  HOST="codex"
  BATCH_NUMBER=3
  ROUND_NUMBER=1
  MAX_ROUNDS=3
  WORKSPACE_ROOT="$ROOT_DIR"
  SPEC_BASELINE="plan"
  WORKSPACE_PLAN_PATH="tmp/isolated/plan.md"
  WORKSPACE_DESIGN_PATH="tmp/isolated/design.md"
  DESIGN_PATH="$WORKSPACE_DESIGN_PATH"
  DESIGN_VERSION="abc1234"
  CODE_IMPL_SCOPE=("skills/_review-libs/output-validator.sh")
  ALLOWED_TOUCH_SET=("skills/_review-libs/output-validator.sh")
  OUT_OF_SCOPE_TOUCHED_FILES=()
  build_scope_json "$scope_json"

  SKILLS_DIR="$ROOT_DIR/skills"
  PRE_CHECK_FINDINGS=""
  DEPTH="thorough"
  PRIOR_FINDINGS_PATH=""
  assert_reviewer_selection_contract

  make_code_impl_prompt "$prompt_output" "skills/_review-libs/output-validator.sh"
  assert_file_contains \
    "$prompt_output" \
    'Use scope_class "baseline_mismatch" only when the approved baseline is internally inconsistent or cannot be satisfied by code changes alone.' \
    "code-impl prompt should reserve baseline_mismatch for unsatisfiable approved baselines"
  assert_file_contains \
    "$prompt_output" \
    'Use scope_class "in_scope_blocking" for defects that can be fixed within the approved code scope without changing the design or plan.' \
    "code-impl prompt should reserve in_scope_blocking for fixable in-scope defects"

  make_design_prompt "$design_prompt_output" "tmp/isolated/design.md"
  assert_file_contains \
    "$design_prompt_output" \
    'If the design is intended for downstream plan/code review, it must declare `## Implementation Surface` with `impl_file_refs` and `test_file_refs`.' \
    "design prompt should require implementation surface refs for downstream review"
  assert_file_contains \
    "$design_prompt_output" \
    'Treat missing or empty downstream Implementation Surface refs as a blocking issue because later artifact-DAG linkage cannot be validated.' \
    "design prompt should treat missing downstream implementation surface refs as blocking"

  assert_file_contains \
    "$ROOT_DIR/skills/review-plan/references/good-finding-example.md" \
    'A well-formed finding includes concrete evidence quoted or closely paraphrased from the source text.' \
    "plan good example should allow quoted or closely paraphrased evidence"
  assert_file_contains \
    "$ROOT_DIR/skills/review-plan/references/bad-finding-example.md" \
    'confidence: low' \
    "plan bad example should include confidence: low"
  assert_file_contains \
    "$ROOT_DIR/skills/review-plan/references/bad-finding-example.md" \
    'confidence is required even for bad examples' \
    "plan bad example should explain that confidence is still required"
  assert_file_contains \
    "$ROOT_DIR/skills/review-code-impl/references/bad-finding-example.md" \
    'confidence: low' \
    "code-impl bad example should include confidence: low"
  assert_file_contains \
    "$ROOT_DIR/skills/review-code-impl/references/bad-finding-example.md" \
    'confidence is required even for bad examples' \
    "code-impl bad example should explain that confidence is still required"
  assert_file_contains \
    "$ROOT_DIR/skills/review-design/references/bad-finding-example.md" \
    'confidence: low' \
    "design bad example should include confidence: low"
  assert_file_contains \
    "$ROOT_DIR/skills/review-design/references/bad-finding-example.md" \
    'confidence is required even for bad examples' \
    "design bad example should explain that confidence is still required"

  for scope_class in baseline_mismatch adjacent_debt out_of_dag_issue external_verification_failure; do
    write_reviewer_output "$baseline_reviewer" "FAIL" "$scope_class"
    build_run_output "$baseline_reviewer" "$scope_json" "$run_output" "cross-driver" "claude" "claude-opus-4-6"
    validate_run_output "$run_output" || fail "$scope_class run output should validate"
    assert_run_field_with_scope_class \
      "$run_output" \
      "$scope_class" \
      "$scope_class blocking finding should force manual review"
  done

  write_reviewer_output "$in_scope_reviewer" "FAIL" "in_scope_blocking"
  build_run_output "$in_scope_reviewer" "$scope_json" "$run_output" "cross-driver" "claude" "claude-opus-4-6"
  validate_run_output "$run_output" || fail "in_scope_blocking run output should validate"
  assert_run_field \
    "$run_output" \
    '.status == "needs_fixes" and .next_action == "host_fix_then_rerun" and .manual_intervention_required == false and .suggested_next_round == 2 and .result.verdict == "FAIL"' \
    "in_scope_blocking finding should stay auto-repairable while rounds remain"

  write_mixed_reviewer_output "$mixed_reviewer"
  build_run_output "$mixed_reviewer" "$scope_json" "$run_output" "cross-driver" "claude" "claude-opus-4-6"
  validate_run_output "$run_output" || fail "mixed run output should validate"
  assert_run_field \
    "$run_output" \
    '.status == "manual_review_required" and .next_action == "human_decision_required" and .manual_intervention_required == true and (.blocking_findings | length) == 2' \
    "manual-only blocking findings should win over in_scope_blocking in mixed results"

  rm -f "$scope_json" "$baseline_reviewer" "$in_scope_reviewer" "$mixed_reviewer" "$run_output" "$prompt_output" "$design_prompt_output"
}

main "$@"
