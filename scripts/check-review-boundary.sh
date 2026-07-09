#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

bad=0
patterns=(
  'cross-driver'
  'cross driver'
  'cross-model'
  'cross model'
  'multi-model review'
  'adversarial review'
  'opposite-driver'
  'opposing model'
  'approval-mode yolo'
)

search_paths=(
  README.md
  AGENTS.md
  commands
  contracts
  docs
  scripts
  src
)

for pattern in "${patterns[@]}"; do
  if rg -n --fixed-strings "$pattern" "${search_paths[@]}" \
    --glob '!docs/plans/**' \
    --glob '!docs/changelog/**' \
    --glob '!CHANGELOG.md' \
    --glob '!scripts/check-review-boundary.sh' \
    --glob '!skills/**' \
    --glob '!*.source-map.json' \
    2>/dev/null; then
    bad=1
  fi
done

if [[ "$bad" -ne 0 ]]; then
  echo "retired review-routing references remain outside historical docs" >&2
  exit 1
fi

echo "review routing references ok"
