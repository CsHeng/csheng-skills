#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

PYTHONDONTWRITEBYTECODE=1 \
PYTHONPYCACHEPREFIX="$HOME/.cache/python/market-csheng" \
python3 scripts/generate-skills-index.py --check

PYTHONDONTWRITEBYTECODE=1 \
PYTHONPYCACHEPREFIX="$HOME/.cache/python/market-csheng" \
python3 scripts/check-contracts.py

PYTHONDONTWRITEBYTECODE=1 \
PYTHONPYCACHEPREFIX="$HOME/.cache/python/market-csheng" \
python3 scripts/check-install-surface.py --target claude

PYTHONDONTWRITEBYTECODE=1 \
PYTHONPYCACHEPREFIX="$HOME/.cache/python/market-csheng" \
python3 scripts/check-install-surface.py --target codex

PYTHONDONTWRITEBYTECODE=1 \
PYTHONPYCACHEPREFIX="$HOME/.cache/python/market-csheng" \
python3 scripts/check-install-surface.py --target root-flat

PYTHONDONTWRITEBYTECODE=1 \
PYTHONPYCACHEPREFIX="$HOME/.cache/python/market-csheng" \
python3 scripts/check-fixtures.py

bash scripts/check-review-boundary.sh
