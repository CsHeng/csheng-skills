#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=skills/_harness-libs/artifact-dag.sh
source "$SCRIPT_DIR/../_review-libs/artifact-dag.sh"
# shellcheck source=skills/_harness-libs/phase-engine.sh
source "$SCRIPT_DIR/phase-engine.sh"

default_plan_artifact_path() {
  local design_path="$1"
  local base_name=""

  base_name="$(basename -- "$design_path")"
  base_name="${base_name%-design.md}"
  base_name="${base_name%.md}"
  printf 'docs/superpowers/plans/%s.md\n' "$base_name"
}

plan_entry_phase() {
  next_phase_for_entry "plan-change"
}

validate_plan_artifact() {
  local plan_file="$1"
  local pattern=""

  [[ -f "$plan_file" ]] || {
    printf 'missing plan file: %s\n' "$plan_file" >&2
    return 1
  }

  for pattern in \
    '^# ' \
    '^## Upstream Design$' \
    '^## Implementation Scope$' \
    '^## Review Gate$' \
    '^## Human Gate$' \
    '^## Task [0-9]+:' \
    '^## Rollback$'
  do
    rg -n "$pattern" "$plan_file" >/dev/null || {
      printf 'plan artifact missing required section: %s\n' "$pattern" >&2
      return 1
    }
  done

  for pattern in \
    'design_ref:' \
    'design_version:' \
    'impl_file_refs:' \
    'test_file_refs:' \
    'verification_scope:' \
    'required_entry:' \
    'approval_required:' \
    'approval_status:' \
    'next_entry:' \
    'rollback_entry:'
  do
    rg -n "$pattern" "$plan_file" >/dev/null || {
      printf 'plan artifact missing required field: %s\n' "$pattern" >&2
      return 1
    }
  done

  rg -n 'approval_status:[[:space:]]*(pending|approved)' "$plan_file" >/dev/null || {
    printf 'plan artifact approval_status must be pending or approved\n' >&2
    return 1
  }

  resolve_plan_design_ref "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" "$plan_file" >/dev/null || {
    printf 'plan artifact has invalid upstream design linkage\n' >&2
    return 1
  }
}

plan_approval_status() {
  local plan_file="$1"

  [[ -f "$plan_file" ]] || {
    printf 'missing plan file: %s\n' "$plan_file" >&2
    return 1
  }

  rg -o 'approval_status:[[:space:]]*(pending|approved)' "$plan_file" \
    | head -n 1 \
    | sed -E 's/^approval_status:[[:space:]]*//'
}

usage() {
  cat <<'EOF'
Usage:
  plan-runner.sh default-path <design-path>
  plan-runner.sh entry-phase
  plan-runner.sh validate <plan-file>
  plan-runner.sh approval-status <plan-file>
EOF
}

main() {
  local command="${1:-}"

  case "$command" in
    default-path)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      default_plan_artifact_path "$2"
      ;;
    entry-phase)
      plan_entry_phase
      ;;
    validate)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      validate_plan_artifact "$2"
      ;;
    approval-status)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      plan_approval_status "$2"
      ;;
    *)
      usage >&2
      return 1
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
