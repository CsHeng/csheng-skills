#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [[ "${1:-}" == "--check" ]]; then
  exec bash scripts/check.sh
fi

PYTHONDONTWRITEBYTECODE=1 \
PYTHONPYCACHEPREFIX="$HOME/.cache/python/market-csheng" \
python3 scripts/flatten-skills.py "$@"
