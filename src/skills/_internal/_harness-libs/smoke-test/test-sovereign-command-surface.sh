#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

fail() {
  printf 'test-sovereign-command-surface: %s\n' "$*" >&2
  exit 1
}

assert_file() {
  local path="$1"
  [[ -f "$ROOT_DIR/$path" ]] || fail "missing file: $path"
}

assert_contains() {
  local path="$1"
  local pattern="$2"
  local message="$3"

  rg -n "$pattern" "$ROOT_DIR/$path" >/dev/null || fail "$message"
}

main() {
  local command=""
  local commands=(
    analyze-project
    design-change
    plan-change
    execute-change
    review-change
    sync-truth
    close-change
  )

  for command in "${commands[@]}"; do
    assert_file "commands/${command}.md"
    assert_contains "commands/${command}.md" "^---$" "missing frontmatter in commands/${command}.md"
    assert_contains "commands/${command}.md" "coding:${command}" "command ${command} should invoke matching skill"
  done

  assert_contains "README.md" "/analyze-project|/design-change|/plan-change|/execute-change|/review-change|/sync-truth|/close-change" "README should document top-level slash commands"
  assert_contains "AGENTS.md" "commands mirror the seven top-level harness entries|/analyze-project" "AGENTS should document command surface"

  if rg -n "~/.codex|/(home|Users)/[^/]+/.codex" "$ROOT_DIR/README.md" "$ROOT_DIR/AGENTS.md" "$ROOT_DIR/commands" >/dev/null; then
    fail "plugin command surface should not depend on ~/.codex paths"
  fi
}

main "$@"
