#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DOCS_DIR="$ROOT_DIR/docs"

cd "$ROOT_DIR"

[[ -f "$DOCS_DIR/.ignore" ]] || { echo "missing docs/.ignore" >&2; exit 1; }
rg -qx 'plans/' "$DOCS_DIR/.ignore"
rg -qx 'superpowers/' "$DOCS_DIR/.ignore"

[[ -f "$DOCS_DIR/AGENTS.md" ]] || { echo "missing docs/AGENTS.md" >&2; exit 1; }
[[ -f "$DOCS_DIR/README.md" ]] || { echo "missing docs/README.md" >&2; exit 1; }

rg -n "stable truth|stage artifacts|search tools|root \`.gitignore\`|git add -f" \
  "$DOCS_DIR/AGENTS.md" >/dev/null

rg -n "avoid \`docs/plans/\` and \`docs/superpowers/\`|docs/superpowers|--no-ignore" \
  "$DOCS_DIR/README.md" >/dev/null

git check-ignore -q docs/superpowers/example.md
git check-ignore -q docs/plans/example.md

if rg --files docs | rg -q '^docs/superpowers/'; then
  echo "default docs file search unexpectedly listed stage artifacts" >&2
  exit 1
fi

rg --files --no-ignore docs | rg -q '^docs/superpowers/'
