#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./install-codex.sh

Registers this repository as a local Codex marketplace and installs coding@csheng.
EOF
}

if [[ "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 0 ]]; then
  echo "Unknown arguments: $*" >&2
  usage >&2
  exit 2
fi

if ! command -v codex >/dev/null 2>&1; then
  echo "codex CLI not found in PATH" >&2
  exit 1
fi

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MARKETPLACE_ROOT="$REPO_ROOT/.codex-marketplace"
readonly MARKETPLACE_ROOT

EXISTING_ROOT="$(codex plugin marketplace list | awk 'NR > 1 && $1 == "csheng" { print $2; exit }')"
readonly EXISTING_ROOT

if [[ "$EXISTING_ROOT" == "$MARKETPLACE_ROOT" ]]; then
  echo "Codex marketplace already registered: csheng"
elif [[ -n "$EXISTING_ROOT" ]]; then
  echo "Codex marketplace 'csheng' already points at: $EXISTING_ROOT" >&2
  echo "Remove or rename that marketplace before registering: $MARKETPLACE_ROOT" >&2
  exit 1
else
  codex plugin marketplace add "$MARKETPLACE_ROOT"
fi

codex plugin add coding@csheng

echo "Codex plugin installed: coding@csheng"
