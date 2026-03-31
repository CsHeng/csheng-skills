#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# shellcheck source=skills/_review-libs/artifact-dag.sh
source "$ROOT_DIR/skills/_review-libs/artifact-dag.sh"
# shellcheck source=skills/_review-libs/output-validator.sh
source "$ROOT_DIR/skills/_review-libs/output-validator.sh"

PLAN_FILE="$ROOT_DIR/skills/_review-libs/smoke-test/fixtures/sample-plan.md"
DESIGN_FILE="$ROOT_DIR/skills/_review-libs/smoke-test/fixtures/sample-design.md"

fail() {
  printf 'test-artifact-dag: %s\n' "$*" >&2
  exit 1
}

log() {
  :
}

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"
  if [[ "$actual" != "$expected" ]]; then
    fail "$message (expected=$expected actual=$actual)"
  fi
}

assert_contains_line() {
  local haystack="$1"
  local needle="$2"
  local message="$3"
  if ! grep -Fqx "$needle" <<<"$haystack"; then
    fail "$message (missing=$needle)"
  fi
}

main() {
  local -a resolved
  mapfile -t resolved < <(resolve_plan_design_ref "$ROOT_DIR" "$PLAN_FILE")
  assert_eq "${#resolved[@]}" "2" "resolve_plan_design_ref should output 2 lines"
  assert_eq "${resolved[0]}" "$DESIGN_FILE" "resolved design path mismatch"
  assert_eq "${resolved[1]}" "f203ff0" "resolved design version mismatch"

  local fake_root_with_spaces
  fake_root_with_spaces="$ROOT_DIR/tmp root with spaces"
  mapfile -t resolved < <(resolve_plan_design_ref "$fake_root_with_spaces" "$PLAN_FILE")
  assert_eq "${#resolved[@]}" "2" "resolve_plan_design_ref should output 2 lines with spaced root"
  assert_eq "${resolved[0]}" "$fake_root_with_spaces/skills/_review-libs/smoke-test/fixtures/sample-design.md" "resolved design path with spaces mismatch"
  assert_eq "${resolved[1]}" "f203ff0" "resolved design version with spaces mismatch"

  local plan_impl_refs plan_test_refs
  plan_impl_refs="$(extract_markdown_list "$PLAN_FILE" "Implementation Scope" "impl_file_refs")"
  plan_test_refs="$(extract_markdown_list "$PLAN_FILE" "Implementation Scope" "test_file_refs")"
  assert_contains_line "$plan_impl_refs" "skills/_review-libs/workspace.sh" "plan impl_refs should include workspace.sh"
  assert_contains_line "$plan_test_refs" "skills/_review-libs/smoke-test/test-artifact-dag.sh" "plan test_refs should include this test"

  local allowed_touch_set
  allowed_touch_set="$(build_allowed_touch_set "$PLAN_FILE" "$DESIGN_FILE")"
  assert_contains_line "$allowed_touch_set" "skills/_review-libs/workspace.sh" "allowed touch set should include workspace.sh"
  assert_contains_line "$allowed_touch_set" "skills/_review-libs/smoke-test/test-artifact-dag.sh" "allowed touch set should include test-artifact-dag.sh"

  local design_out_of_scope_refs
  design_out_of_scope_refs="$(extract_markdown_list "$DESIGN_FILE" "Implementation Surface" "out_of_scope_file_refs")"
  assert_contains_line "$design_out_of_scope_refs" "skills/_review-libs/drivers/gemini.sh" "design should include out of scope file refs"

  assert_plan_refs_within_design "$PLAN_FILE" "$DESIGN_FILE"

  local rogue_plan
  rogue_plan="$(mktemp)"
  cp "$PLAN_FILE" "$rogue_plan"
  cat >>"$rogue_plan" <<'EOF'
  - skills/_review-libs/drivers/gemini.sh
EOF

  if build_allowed_touch_set "$rogue_plan" "$DESIGN_FILE" >/dev/null 2>&1; then
    rm -f "$rogue_plan"
    fail "build_allowed_touch_set should fail when plan refs exceed design ceiling"
  fi
  rm -f "$rogue_plan"

  local reviewer_schema run_schema
  reviewer_schema="$ROOT_DIR/skills/_review-libs/schemas/adversarial-reviewer-output.schema.json"
  run_schema="$ROOT_DIR/skills/_review-libs/schemas/review-run-output.schema.json"

  jq -e '.["$defs"].finding.required | index("scope_class") != null' "$reviewer_schema" >/dev/null \
    || fail "reviewer schema should require finding.scope_class"
  jq -e '.["$defs"].finding.properties.scope_class.enum | index("in_scope_blocking") != null' "$reviewer_schema" >/dev/null \
    || fail "reviewer schema should define scope_class enum with in_scope_blocking"

  jq -e '.properties.scope.properties | has("design_path")' "$run_schema" >/dev/null \
    || fail "run schema scope should include design_path"
  jq -e '.properties.scope.properties | has("design_version")' "$run_schema" >/dev/null \
    || fail "run schema scope should include design_version"
  jq -e '.properties.scope.properties | has("allowed_touch_set")' "$run_schema" >/dev/null \
    || fail "run schema scope should include allowed_touch_set"
  jq -e '.properties.scope.properties | has("out_of_scope_touched_files")' "$run_schema" >/dev/null \
    || fail "run schema scope should include out_of_scope_touched_files"

  local scope_json run_output_json
  local reviewer_output_json
  scope_json="$(mktemp)"
  reviewer_output_json="$(mktemp)"
  run_output_json="$(mktemp)"
  RUN_SCHEMA_PATH="$run_schema"
  MODE="design"
  WORKSPACE_ROOT="$ROOT_DIR"
  SPEC_BASELINE="design"
  WORKSPACE_PLAN_PATH=""
  DESIGN_PATH="skills/_review-libs/smoke-test/fixtures/sample-design.md"
  DESIGN_VERSION="f203ff0"
  local -a ALLOWED_TOUCH_SET=()
  local -a OUT_OF_SCOPE_TOUCHED_FILES=()
  build_scope_json "$scope_json"

  jq -e '.allowed_touch_set == [] and .out_of_scope_touched_files == []' "$scope_json" >/dev/null \
    || fail "build_scope_json should serialize declared empty arrays as []"

  jq -n '
    {
      lens: "code-correctness",
      verdict: "PASS",
      summary: "Looks good",
      findings: [
        {
          severity: "Important",
          location: "skills/_review-libs/output-validator.sh:1",
          evidence: "checked",
          impact: "none",
          fix: "none",
          confidence: "high",
          scope_class: "in_scope_blocking"
        }
      ],
      pass_rationale: "All required checks passed."
    }
  ' > "$reviewer_output_json"
  validate_reviewer_output "$reviewer_output_json" \
    || fail "validate_reviewer_output should accept valid reviewer payload"

  jq -n --slurpfile scope "$scope_json" --slurpfile reviewer "$reviewer_output_json" '
    {
      mode: "design",
      host: "codex",
      reviewer: "claude",
      reviewer_model: "claude-opus-4-6",
      review_mode: "cross-driver",
      status: "pass",
      next_action: "stop_passed",
      manual_intervention_required: false,
      batch: 1,
      round: 1,
      max_rounds: 3,
      suggested_next_batch: 1,
      suggested_next_round: 1,
      blocking_findings: [$reviewer[0].findings[0]],
      scope: $scope[0],
      result: $reviewer[0]
    }
  ' > "$run_output_json"
  validate_run_output "$run_output_json" \
    || fail "validate_run_output should accept a valid run payload"

  local bad_reviewer_json
  bad_reviewer_json="$(mktemp)"
  jq '.pass_rationale = ""' "$reviewer_output_json" > "$bad_reviewer_json"
  if validate_reviewer_output "$bad_reviewer_json"; then
    rm -f "$bad_reviewer_json"
    fail "validate_reviewer_output should reject PASS with empty pass_rationale"
  fi
  jq '.unexpected = true' "$reviewer_output_json" > "$bad_reviewer_json"
  if validate_reviewer_output "$bad_reviewer_json"; then
    rm -f "$bad_reviewer_json"
    fail "validate_reviewer_output should reject undeclared top-level reviewer fields"
  fi
  jq '.findings[0].unexpected = true' "$reviewer_output_json" > "$bad_reviewer_json"
  if validate_reviewer_output "$bad_reviewer_json"; then
    rm -f "$bad_reviewer_json"
    fail "validate_reviewer_output should reject undeclared finding fields"
  fi
  rm -f "$bad_reviewer_json"

  local bad_run_json
  bad_run_json="$(mktemp)"
  jq '.blocking_findings = [{"severity":"Important"}]' "$run_output_json" > "$bad_run_json"
  if validate_run_output "$bad_run_json"; then
    rm -f "$bad_run_json"
    fail "validate_run_output should reject malformed blocking_findings entries"
  fi
  jq '.batch = 1.5' "$run_output_json" > "$bad_run_json"
  if validate_run_output "$bad_run_json"; then
    rm -f "$bad_run_json"
    fail "validate_run_output should reject non-integer counters"
  fi
  jq '.result.pass_rationale = ""' "$run_output_json" > "$bad_run_json"
  if validate_run_output "$bad_run_json"; then
    rm -f "$bad_run_json"
    fail "validate_run_output should reject PASS result with empty pass_rationale"
  fi
  jq '.unexpected = true' "$run_output_json" > "$bad_run_json"
  if validate_run_output "$bad_run_json"; then
    rm -f "$bad_run_json"
    fail "validate_run_output should reject undeclared top-level run fields"
  fi
  jq '.reconciliation_note = "extra"' "$run_output_json" > "$bad_run_json"
  if validate_run_output "$bad_run_json"; then
    rm -f "$bad_run_json"
    fail "validate_run_output should reject reconciliation_note when schema disallows it"
  fi
  rm -f "$bad_run_json"

  local reviewer_fail_no_blocking reviewer_pass_with_blocking built_run_json
  reviewer_fail_no_blocking="$(mktemp)"
  reviewer_pass_with_blocking="$(mktemp)"
  built_run_json="$(mktemp)"

  jq -n '
    {
      lens: "code-correctness",
      verdict: "FAIL",
      summary: "No blocking severity findings",
      findings: [
        {
          severity: "Minor",
          location: "skills/_review-libs/output-validator.sh:1",
          evidence: "checked",
          impact: "low",
          fix: "none",
          confidence: "high",
          scope_class: "adjacent_debt"
        }
      ],
      pass_rationale: ""
    }
  ' > "$reviewer_fail_no_blocking"

  MODE="design"
  HOST="codex"
  BATCH_NUMBER=1
  ROUND_NUMBER=1
  MAX_ROUNDS=3
  build_run_output "$reviewer_fail_no_blocking" "$scope_json" "$built_run_json" "cross-driver" "claude" "claude-opus-4-6"
  validate_run_output "$built_run_json" || fail "build_run_output fail/no-blocking output should validate"
  jq -e '.status == "pass" and .next_action == "stop_passed" and .result.verdict == "PASS"' "$built_run_json" >/dev/null \
    || fail "build_run_output should reconcile FAIL+no-blocking to PASS consistently"

  jq -n '
    {
      lens: "code-correctness",
      verdict: "PASS",
      summary: "Contains blocking finding",
      findings: [
        {
          severity: "Important",
          location: "skills/_review-libs/output-validator.sh:1",
          evidence: "checked",
          impact: "high",
          fix: "fix",
          confidence: "high",
          scope_class: "in_scope_blocking"
        }
      ],
      pass_rationale: "Looks good."
    }
  ' > "$reviewer_pass_with_blocking"

  MODE="design"
  HOST="codex"
  BATCH_NUMBER=1
  ROUND_NUMBER=1
  MAX_ROUNDS=3
  build_run_output "$reviewer_pass_with_blocking" "$scope_json" "$built_run_json" "cross-driver" "claude" "claude-opus-4-6"
  validate_run_output "$built_run_json" || fail "build_run_output pass/with-blocking output should validate"
  jq -e '.status == "needs_fixes" and .next_action == "host_fix_then_rerun" and .result.verdict == "FAIL"' "$built_run_json" >/dev/null \
    || fail "build_run_output should reconcile PASS+blocking to FAIL/needs_fixes consistently"

  rm -f "$reviewer_fail_no_blocking" "$reviewer_pass_with_blocking" "$built_run_json"

  rm -f "$scope_json" "$reviewer_output_json" "$run_output_json"
}

main "$@"
