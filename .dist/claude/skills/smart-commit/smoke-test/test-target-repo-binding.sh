#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SKILL_FILE="$ROOT_DIR/skills/smart-commit/SKILL.md"
COMMAND_FILE="$ROOT_DIR/commands/smart-commit.md"

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local file_path="$1"
  local expected="$2"
  if ! grep -Fq -- "$expected" "$file_path"; then
    fail "$file_path missing expected text: $expected"
  fi
}

main() {
  assert_contains "$SKILL_FILE" 'TARGET_REPO'
  assert_contains "$SKILL_FILE" 'git -C "$TARGET_REPO"'
  assert_contains "$SKILL_FILE" 'Never use the plugin repository as the implicit target repository'

  assert_contains "$COMMAND_FILE" 'Bash(git -C:*)'
  assert_contains "$COMMAND_FILE" 'resolve the target repository from the invocation working directory'
}

main "$@"
