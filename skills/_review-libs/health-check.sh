#!/usr/bin/env bash
# Review system health check - validates components and reports availability.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Color codes (if terminal supports it)
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  YELLOW='\033[0;33m'
  NC='\033[0m'
else
  GREEN=''
  RED=''
  YELLOW=''
  NC=''
fi

log() { printf '%s\n' "$*"; }
success() { printf "${GREEN}%s${NC}\n" "$*"; }
warning() { printf "${YELLOW}%s${NC}\n" "$*"; }
error() { printf "${RED}%s${NC}\n" "$*"; }

# Check driver script
check_driver() {
  local driver="$1"
  local driver_path="$SCRIPT_DIR/drivers/${driver}.sh"

  if [[ ! -f "$driver_path" ]]; then
    error "  $driver:  missing"
    return 1
  fi

  if [[ ! -x "$driver_path" ]]; then
    error "  $driver:  not executable"
    return 1
  fi

  # Run probe to test availability
  if timeout 5 "$driver_path" --probe >/dev/null 2>&1; then
    success "  $driver:  available"
    return 0
  else
    warning "  $driver:  unreachable"
    return 1
  fi
}

# Check schema file
check_schema() {
  local schema_path="$SCRIPT_DIR/schemas/adversarial-reviewer-output.schema.json"

  if [[ ! -f "$schema_path" ]]; then
    error "  adversarial-reviewer-output: missing"
    return 1
  fi

  if jq . "$schema_path" >/dev/null 2>&1; then
    success "  adversarial-reviewer-output: valid"
    return 0
  else
    error "  adversarial-reviewer-output: invalid"
    return 1
  fi
}

# Check required tool
check_tool() {
  local tool="$1"

  if command -v "$tool" >/dev/null 2>&1; then
    success "  $tool:  present"
    return 0
  else
    error "  $tool:  absent"
    return 1
  fi
}

# Check pre-checks script
check_prechecks() {
  local prechecks_path="$SCRIPT_DIR/pre-checks.sh"

  if [[ ! -f "$prechecks_path" ]]; then
    error "  pre-checks.sh: missing"
    return 1
  fi

  if [[ ! -x "$prechecks_path" ]]; then
    warning "  pre-checks.sh: not executable"
    return 1
  fi

  success "  pre-checks.sh: available"
  return 0
}

# Main execution
log "Review System Health Check"
log "=========================="
log ""

# Check drivers
log "Drivers:"
AVAILABLE_REVIEWERS=0
TOTAL_REVIEWERS=3

check_driver "claude" && ((AVAILABLE_REVIEWERS++)) || true
check_driver "codex" && ((AVAILABLE_REVIEWERS++)) || true
check_driver "gemini" && ((AVAILABLE_REVIEWERS++)) || true

log ""

# Check schema
log "Schema:"
check_schema || true

log ""

# Check tools
log "Tools:"
check_tool "jq" || true
check_tool "bash" || true

log ""

# Check pre-checks
log "Pre-checks:"
check_prechecks || true

log ""

# Summary
log "Status: $AVAILABLE_REVIEWERS/$TOTAL_REVIEWERS reviewers available"

# Exit code: 0 if at least one reviewer available
if ((AVAILABLE_REVIEWERS > 0)); then
  exit 0
else
  exit 1
fi
