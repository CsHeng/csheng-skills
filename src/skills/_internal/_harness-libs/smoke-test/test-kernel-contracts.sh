#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# shellcheck source=skills/_harness-libs/contracts.sh
source "$ROOT_DIR/skills/_harness-libs/contracts.sh"

fail() {
  printf 'test-kernel-contracts: %s\n' "$*" >&2
  exit 1
}

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  [[ "$actual" == "$expected" ]] || fail "$message: expected=$expected actual=$actual"
}

assert_invalid() {
  local fn="$1"
  local value="$2"

  if "$fn" "$value"; then
    fail "$fn unexpectedly accepted $value"
  fi
}

assert_sequence() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  [[ "$actual" == "$expected" ]] || fail "$message"
}

main() {
  local entries phases classes design_strengths verdicts artifact_classes failure_kinds

  entries="$(printf '%s\n' "${HARNESS_ENTRIES[@]}")"
  phases="$(printf '%s\n' "${HARNESS_PHASES[@]}")"
  classes="$(printf '%s\n' "${HARNESS_CHANGE_CLASSES[@]}")"
  design_strengths="$(printf '%s\n' "${HARNESS_DESIGN_STRENGTHS[@]}")"
  verdicts="$(printf '%s\n' "${HARNESS_VERDICTS[@]}")"
  artifact_classes="$(printf '%s\n' "${HARNESS_ARTIFACT_CLASSES[@]}")"
  failure_kinds="$(printf '%s\n' "${HARNESS_FAILURE_KINDS[@]}")"

  assert_sequence "$entries" "$(cat <<'EOF'
analyze-project
design-change
plan-change
implement-change
review-change
sync-truth
close-change
EOF
)" "entry order drifted"

  assert_sequence "$phases" "$(cat <<'EOF'
intake
truth-scan
clarify
design-lite
design-full
plan
dependency-freeze
implement-serial
implement-parallel
converge
review
verify
truth-sync
close
EOF
)" "phase order drifted"

  assert_sequence "$classes" "$(cat <<'EOF'
A
B
C
D
EOF
)" "change classes drifted"

  assert_sequence "$design_strengths" "$(cat <<'EOF'
no-design
design-lite
design-full
EOF
)" "design strengths drifted"

  assert_sequence "$verdicts" "$(cat <<'EOF'
pass
needs-fixes
needs-rollback
manual-decision-required
EOF
)" "verdicts drifted"

  assert_sequence "$artifact_classes" "$(cat <<'EOF'
truth
design
plan
implementation
evaluation
history
EOF
)" "artifact classes drifted"

  assert_sequence "$failure_kinds" "$(cat <<'EOF'
classification-failure
truth-conflict
requirement-ambiguity
boundary-mismatch
plan-incompleteness
dependency-churn
parallel-conflict
convergence-failure
review-blocking-failure
verification-failure
truth-sync-failure
EOF
)" "failure kinds drifted"

  is_valid_entry "analyze-project" || fail "analyze-project should be valid"
  is_valid_entry "close-change" || fail "close-change should be valid"
  assert_invalid is_valid_entry "smart-commit"

  is_valid_phase "truth-scan" || fail "truth-scan should be valid"
  is_valid_phase "implement-parallel" || fail "implement-parallel should remain a declared phase"
  assert_invalid is_valid_phase "implement"

  is_valid_change_class "A" || fail "A should be valid"
  is_valid_change_class "D" || fail "D should be valid"
  assert_invalid is_valid_change_class "Z"

  is_valid_design_strength "no-design" || fail "no-design should be valid"
  is_valid_design_strength "design-full" || fail "design-full should be valid"
  assert_invalid is_valid_design_strength "full-design"

  is_valid_verdict "pass" || fail "pass should be valid"
  is_valid_verdict "needs-rollback" || fail "needs-rollback should be valid"
  assert_invalid is_valid_verdict "ok"

  is_valid_artifact_class "truth" || fail "truth should be valid"
  is_valid_artifact_class "evaluation" || fail "evaluation should be valid"
  assert_invalid is_valid_artifact_class "code"

  is_valid_failure_kind "classification-failure" || fail "classification-failure should be valid"
  is_valid_failure_kind "truth-sync-failure" || fail "truth-sync-failure should be valid"
  assert_invalid is_valid_failure_kind "git-conflict"

  assert_eq "$(harness_default_phase)" "intake" "default phase should stay intake"
}

main "$@"
