#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

fail() {
  printf 'test-agent-native-review: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local path="$1" pattern="$2" message="$3"
  rg -n -- "$pattern" "$ROOT_DIR/$path" >/dev/null || fail "$message"
}

assert_absent() {
  local pattern="$1" message="$2"
  shift 2
  if rg -n -i -- "$pattern" "$@" >/dev/null; then
    fail "$message"
  fi
}

main() {
  local review_change="$ROOT_DIR/src/skills/workflows/review-change/SKILL.md"
  local implement_change="$ROOT_DIR/src/skills/workflows/implement-change/SKILL.md"
  local review_components="$ROOT_DIR/src/skills/review-components"
  local commands="$ROOT_DIR/commands"

  assert_contains "src/skills/workflows/review-change/SKILL.md" 'bounded review brief' "review-change must require a bounded review brief"
  assert_contains "src/skills/workflows/review-change/SKILL.md" 'main.*delegated|delegated.*main' "review-change must distinguish main and delegated actors"
  assert_contains "src/skills/workflows/review-change/SKILL.md" 'must not.*recurs|never.*recurs|do not.*recurs' "delegated review must not delegate recursively"

  for causal_class in introduced_by_change regressed_by_change activated_by_change pre_existing unrelated; do
    assert_contains "src/skills/review-components/review-implementation/SKILL.md" "$causal_class" "missing causal class: $causal_class"
  done

  for disposition in accepted rejected_no_causal_link rejected_pre_existing rejected_out_of_scope rejected_insufficient_evidence deferred_followup needs_plan_change; do
    assert_contains "src/skills/workflows/review-change/SKILL.md" "$disposition" "missing main-agent disposition: $disposition"
  done

  assert_contains "src/skills/review-components/review-implementation/SKILL.md" 'Moving|move|renam' "implementation review must cover mechanical move/rename causality"
  assert_contains "src/skills/review-components/review-implementation/SKILL.md" 'Low-confidence|low confidence' "low-confidence findings must be non-repairable"
  assert_contains "src/skills/workflows/implement-change/SKILL.md" 'only.*accepted|accepted.*only' "implement-change must repair accepted findings only"
  assert_contains "src/skills/workflows/implement-change/references/repair-loop.md" 'focused verification' "repair must use focused verification"

  assert_absent 'run-review\.sh|review-gate\.sh|review-runner\.sh|same-driver|cross-model|cross-provider|adversarial reviewer|codex exec|claude -p|gemini' \
    "active review surfaces must not invoke or select external reviewers" \
    "$review_change" "$implement_change" "$review_components" "$commands/review-change.md" "$commands/review-design.md" "$commands/review-plan.md" "$commands/review-implementation.md" "$commands/implement-change.md"

  printf 'test-agent-native-review: PASS\n'
}

main "$@"
