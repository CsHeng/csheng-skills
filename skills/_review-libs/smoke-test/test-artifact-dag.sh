#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# shellcheck source=skills/_review-libs/artifact-dag.sh
source "$ROOT_DIR/skills/_review-libs/artifact-dag.sh"

PLAN_FILE="$ROOT_DIR/skills/_review-libs/smoke-test/fixtures/sample-plan.md"
DESIGN_FILE="$ROOT_DIR/skills/_review-libs/smoke-test/fixtures/sample-design.md"

fail() {
  printf 'test-artifact-dag: %s\n' "$*" >&2
  exit 1
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
}

main "$@"
