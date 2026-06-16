#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=skills/_review-libs/artifact-dag.sh
source "$SCRIPT_DIR/../_review-libs/artifact-dag.sh"
# shellcheck source=skills/_harness-libs/phase-engine.sh
source "$SCRIPT_DIR/phase-engine.sh"
# shellcheck source=skills/_harness-libs/evaluation-gate.sh
source "$SCRIPT_DIR/evaluation-gate.sh"

truth_sync_slugify_topic() {
  local topic="${1:-}"

  topic="$(printf '%s' "$topic" | tr '[:upper:]' '[:lower:]')"
  topic="$(printf '%s' "$topic" | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g')"
  [[ -n "$topic" ]] || topic="truth-sync"
  printf '%s\n' "$topic"
}

default_truth_sync_artifact_path() {
  local topic="$1"
  local artifact_date="${2:-$(date -u +%F)}"
  local slug=""

  slug="$(truth_sync_slugify_topic "$topic")"
  printf 'docs/plans/changes/%s-%s-truth-sync.md\n' "$artifact_date" "$slug"
}

truth_sync_entry_phase() {
  next_phase_for_entry "sync-truth"
}

truth_sync_approval_status() {
  local artifact_file="$1"

  [[ -f "$artifact_file" ]] || {
    printf 'missing truth-sync artifact: %s\n' "$artifact_file" >&2
    return 1
  }

  rg -o 'approval_status:[[:space:]]*(pending|approved)' "$artifact_file" \
    | head -n 1 \
    | sed -E 's/^approval_status:[[:space:]]*//'
}

validate_stable_truth_refs() {
  local artifact_file="$1"
  local ref=""
  local -a stable_truth_refs=()

  mapfile -t stable_truth_refs < <(extract_markdown_list "$artifact_file" "Stable Truth Updates" "stable_truth_refs")
  [[ "${#stable_truth_refs[@]}" -gt 0 ]] || {
    printf 'truth-sync artifact requires at least one stable_truth_refs entry\n' >&2
    return 1
  }

  for ref in "${stable_truth_refs[@]}"; do
    [[ -n "$ref" ]] || continue
    case "$ref" in
      docs/plans/*|*/docs/plans/*)
        printf 'stable truth ref must not point at stage artifact root: %s\n' "$ref" >&2
        return 1
        ;;
    esac
  done
}

validate_truth_sync_artifact() {
  local artifact_file="$1"
  local pattern=""

  [[ -f "$artifact_file" ]] || {
    printf 'missing truth-sync artifact: %s\n' "$artifact_file" >&2
    return 1
  }

  for pattern in \
    '^# ' \
    '^## Evidence$' \
    '^## Stable Truth Updates$' \
    '^## Human Gate$'
  do
    rg -n "$pattern" "$artifact_file" >/dev/null || {
      printf 'truth-sync artifact missing required section: %s\n' "$pattern" >&2
      return 1
    }
  done

  for pattern in \
    'approved_design_ref:' \
    'approved_plan_ref:' \
    'review_gate_ref:' \
    'verification_ref:' \
    'truth_sync_required:' \
    'stable_truth_refs:' \
    'stage_artifact_refs:' \
    'summary:' \
    'approval_required:' \
    'approval_status:' \
    'next_entry:'
  do
    rg -n "$pattern" "$artifact_file" >/dev/null || {
      printf 'truth-sync artifact missing required field: %s\n' "$pattern" >&2
      return 1
    }
  done

  rg -n 'truth_sync_required:[[:space:]]*true' "$artifact_file" >/dev/null || {
    printf 'truth-sync artifact truth_sync_required must be true\n' >&2
    return 1
  }

  rg -n 'approval_status:[[:space:]]*(pending|approved)' "$artifact_file" >/dev/null || {
    printf 'truth-sync artifact approval_status must be pending or approved\n' >&2
    return 1
  }

  rg -n 'next_entry:[[:space:]]*close-change' "$artifact_file" >/dev/null || {
    printf 'truth-sync artifact next_entry must be close-change\n' >&2
    return 1
  }

  validate_stable_truth_refs "$artifact_file"
}

build_truth_sync_gate_result() {
  local artifact_file="$1"
  local review_status="$2"
  local verify_status="$3"
  local approval_status=""
  local truth_sync_completed="false"
  local gate_json=""

  validate_truth_sync_artifact "$artifact_file"
  approval_status="$(truth_sync_approval_status "$artifact_file")"
  [[ "$approval_status" == "approved" ]] && truth_sync_completed="true"

  gate_json="$(build_evaluation_verdict "$review_status" "$verify_status" "true" "$truth_sync_completed")"
  jq \
    --arg artifact_file "$artifact_file" \
    --arg approval_status "$approval_status" \
    '. + {
      artifact_file: $artifact_file,
      approval_status: $approval_status,
      next_entry: (
        if .ready_for_close then
          "close-change"
        elif .verdict == "pass" then
          "sync-truth"
        else
          "execute-change"
        end
      )
    }' <<<"$gate_json"
}

usage() {
  cat <<'EOF'
Usage:
  truth-sync-runner.sh default-path <topic> [date]
  truth-sync-runner.sh entry-phase
  truth-sync-runner.sh validate <truth-sync-artifact>
  truth-sync-runner.sh approval-status <truth-sync-artifact>
  truth-sync-runner.sh gate-result <truth-sync-artifact> <review-status> <verify-status>
EOF
}

main() {
  local command="${1:-}"

  case "$command" in
    default-path)
      [[ $# -ge 2 ]] || { usage >&2; return 1; }
      default_truth_sync_artifact_path "$2" "${3:-}"
      ;;
    entry-phase)
      truth_sync_entry_phase
      ;;
    validate)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      validate_truth_sync_artifact "$2"
      ;;
    approval-status)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      truth_sync_approval_status "$2"
      ;;
    gate-result)
      [[ $# -eq 4 ]] || { usage >&2; return 1; }
      build_truth_sync_gate_result "$2" "$3" "$4"
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
