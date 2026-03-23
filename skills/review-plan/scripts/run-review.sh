#!/usr/bin/env bash
# Wrapper script for plan review mode
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/../../.." && pwd)"

exec bash "$ROOT_DIR/skills/_review-libs/run-review.sh" --mode plan "$@"
