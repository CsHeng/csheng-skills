#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=skills/_harness-libs/design-runner.sh
source "$SCRIPT_DIR/design-runner.sh"
# shellcheck source=skills/_harness-libs/plan-runner.sh
source "$SCRIPT_DIR/plan-runner.sh"
# shellcheck source=skills/_harness-libs/phase-engine.sh
source "$SCRIPT_DIR/phase-engine.sh"
# shellcheck source=skills/_review-libs/output-validator.sh
source "$SCRIPT_DIR/../_review-libs/output-validator.sh"

review_entry_phase() {
  next_phase_for_entry "review-change"
}

resolve_review_artifact_class() {
  local design_path="${1:-}"
  local plan_path="${2:-}"
  shift 2 || true

  if [[ -n "$design_path" ]]; then
    printf 'design\n'
    return
  fi

  if [[ -n "$plan_path" ]] && [[ $# -eq 0 ]]; then
    printf 'plan\n'
    return
  fi

  if [[ -n "$plan_path" || $# -gt 0 ]]; then
    printf 'code-impl\n'
    return
  fi

  printf 'code-impl\n'
}

validate_review_target() {
  local artifact_class="$1"
  local target_path="${2:-}"
  shift 2 || true

  case "$artifact_class" in
    design)
      [[ -n "$target_path" ]] || {
        printf 'design review requires a design path\n' >&2
        return 1
      }
      validate_design_artifact "$target_path"
      ;;
    plan)
      [[ -n "$target_path" ]] || {
        printf 'plan review requires a plan path\n' >&2
        return 1
      }
      validate_plan_artifact "$target_path"
      ;;
    code-impl)
      if [[ -n "$target_path" ]]; then
        validate_plan_artifact "$target_path"
      fi

      while [[ $# -gt 0 ]]; do
        [[ -f "$1" ]] || {
          printf 'code review file not found: %s\n' "$1" >&2
          return 1
        }
        shift
      done
      ;;
    *)
      printf 'unknown review artifact class: %s\n' "$artifact_class" >&2
      return 1
      ;;
  esac
}

validate_review_gate_output() {
  local output_file="$1"
  validate_run_output "$output_file"
}

normalize_review_gate_verdict() {
  local output_file="$1"
  local status=""

  validate_review_gate_output "$output_file"
  status="$(jq -r '.status' "$output_file")"

  case "$status" in
    pass) printf 'pass\n' ;;
    needs_fixes) printf 'needs-fixes\n' ;;
    manual_review_required) printf 'manual-decision-required\n' ;;
    *)
      printf 'unknown review status: %s\n' "$status" >&2
      return 1
      ;;
  esac
}

build_review_gate_result() {
  local artifact_class="$1"
  local output_file="$2"
  local verdict=""

  validate_review_gate_output "$output_file"
  verdict="$(normalize_review_gate_verdict "$output_file")"

  jq -n \
    --arg artifact_class "$artifact_class" \
    --arg verdict "$verdict" \
    --arg status "$(jq -r '.status' "$output_file")" \
    --arg next_action "$(jq -r '.next_action' "$output_file")" \
    --arg reviewer "$(jq -r '.reviewer' "$output_file")" \
    --arg reviewer_model "$(jq -r '.reviewer_model' "$output_file")" \
    --arg review_mode "$(jq -r '.review_mode' "$output_file")" \
    --argjson manual_intervention_required "$(jq '.manual_intervention_required' "$output_file")" \
    --argjson batch "$(jq '.batch' "$output_file")" \
    --argjson round "$(jq '.round' "$output_file")" \
    --argjson max_rounds "$(jq '.max_rounds' "$output_file")" \
    --argjson suggested_next_batch "$(jq '.suggested_next_batch' "$output_file")" \
    --argjson suggested_next_round "$(jq '.suggested_next_round' "$output_file")" \
    --argjson blocking_findings_count "$(jq '.blocking_findings | length' "$output_file")" \
    --argjson blocking_findings "$(jq '.blocking_findings' "$output_file")" \
    --argjson scope "$(jq '.scope' "$output_file")" \
    --argjson result "$(jq '.result' "$output_file")" \
    '{
      artifact_class: $artifact_class,
      verdict: $verdict,
      status: $status,
      next_action: $next_action,
      reviewer: $reviewer,
      reviewer_model: $reviewer_model,
      review_mode: $review_mode,
      manual_intervention_required: $manual_intervention_required,
      batch: $batch,
      round: $round,
      max_rounds: $max_rounds,
      suggested_next_batch: $suggested_next_batch,
      suggested_next_round: $suggested_next_round,
      blocking_findings_count: $blocking_findings_count,
      blocking_findings: $blocking_findings,
      scope: $scope,
      result: $result
    }'
}

usage() {
  cat <<'EOF'
Usage:
  review-runner.sh entry-phase
  review-runner.sh artifact-class <design-path-or-empty> <plan-path-or-empty> [files...]
  review-runner.sh validate-target <design|plan|code-impl> <target-path-or-empty> [files...]
  review-runner.sh validate-output <review-json>
  review-runner.sh verdict <review-json>
  review-runner.sh gate-result <design|plan|code-impl> <review-json>
EOF
}

main() {
  local command="${1:-}"

  case "$command" in
    entry-phase)
      review_entry_phase
      ;;
    artifact-class)
      [[ $# -ge 3 ]] || { usage >&2; return 1; }
      resolve_review_artifact_class "$2" "$3" "${@:4}"
      ;;
    validate-target)
      [[ $# -ge 3 ]] || { usage >&2; return 1; }
      validate_review_target "$2" "$3" "${@:4}"
      ;;
    validate-output)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      validate_review_gate_output "$2"
      ;;
    verdict)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      normalize_review_gate_verdict "$2"
      ;;
    gate-result)
      [[ $# -eq 3 ]] || { usage >&2; return 1; }
      build_review_gate_result "$2" "$3"
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
