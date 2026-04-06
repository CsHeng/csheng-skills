#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=skills/_harness-libs/classifier.sh
source "$SCRIPT_DIR/classifier.sh"
# shellcheck source=skills/_harness-libs/phase-engine.sh
source "$SCRIPT_DIR/phase-engine.sh"

slugify_topic() {
  local topic="${1:-}"

  topic="$(printf '%s' "$topic" | tr '[:upper:]' '[:lower:]')"
  topic="$(printf '%s' "$topic" | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g')"
  [[ -n "$topic" ]] || topic="change"
  printf '%s\n' "$topic"
}

default_design_artifact_path() {
  local topic="$1"
  local artifact_date="${2:-$(date -u +%F)}"
  local slug=""

  slug="$(slugify_topic "$topic")"
  printf 'docs/superpowers/specs/%s-%s-design.md\n' "$artifact_date" "$slug"
}

design_entry_phase() {
  next_phase_for_entry "design-change"
}

build_design_classification_record() {
  local request_kind="$1"
  local truth_impact="$2"
  local boundary_impact="$3"
  local truth_repair="$4"

  classify_change "$request_kind" "$truth_impact" "$boundary_impact" "$truth_repair"
}

validate_design_artifact() {
  local design_file="$1"
  local pattern=""

  [[ -f "$design_file" ]] || {
    printf 'missing design file: %s\n' "$design_file" >&2
    return 1
  }

  for pattern in \
    '^# ' \
    '^## Status$' \
    '^## Problem$' \
    '^## Goals$' \
    '^## Non-Goals$' \
    '^## Change Classification$' \
    '^## Boundaries$' \
    '^## Human Gate$' \
    '^## Implementation Surface$'
  do
    rg -n "$pattern" "$design_file" >/dev/null || {
      printf 'design artifact missing required section: %s\n' "$pattern" >&2
      return 1
    }
  done

  for pattern in \
    'request_kind:' \
    'change_class:' \
    'design_strength:' \
    'truth_impact:' \
    'boundary_impact:' \
    'recommended_next_phase:' \
    'approval_required:' \
    'approval_status:' \
    'next_entry:' \
    'impl_file_refs:' \
    'test_file_refs:'
  do
    rg -n "$pattern" "$design_file" >/dev/null || {
      printf 'design artifact missing required field: %s\n' "$pattern" >&2
      return 1
    }
  done

  rg -n 'approval_status:[[:space:]]*(pending|approved)' "$design_file" >/dev/null || {
    printf 'design artifact approval_status must be pending or approved\n' >&2
    return 1
  }
}

design_approval_status() {
  local design_file="$1"

  [[ -f "$design_file" ]] || {
    printf 'missing design file: %s\n' "$design_file" >&2
    return 1
  }

  rg -o 'approval_status:[[:space:]]*(pending|approved)' "$design_file" \
    | head -n 1 \
    | sed -E 's/^approval_status:[[:space:]]*//'
}

usage() {
  cat <<'EOF'
Usage:
  design-runner.sh default-path <topic> [date]
  design-runner.sh entry-phase
  design-runner.sh classify <request-kind> <truth-impact> <boundary-impact> <truth-repair>
  design-runner.sh validate <design-file>
  design-runner.sh approval-status <design-file>
EOF
}

main() {
  local command="${1:-}"

  case "$command" in
    default-path)
      [[ $# -ge 2 ]] || { usage >&2; return 1; }
      default_design_artifact_path "$2" "${3:-}"
      ;;
    entry-phase)
      design_entry_phase
      ;;
    classify)
      [[ $# -eq 5 ]] || { usage >&2; return 1; }
      build_design_classification_record "$2" "$3" "$4" "$5"
      ;;
    validate)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      validate_design_artifact "$2"
      ;;
    approval-status)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      design_approval_status "$2"
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
