#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=skills/_harness-libs/artifact-dag.sh
source "$SCRIPT_DIR/../_review-libs/artifact-dag.sh"
# shellcheck source=skills/_harness-libs/phase-engine.sh
source "$SCRIPT_DIR/phase-engine.sh"

default_plan_artifact_path() {
  local design_path="$1"
  local artifact_dir=""
  local base_name=""

  artifact_dir="$(dirname -- "$design_path")"
  base_name="$(basename -- "$design_path")"
  base_name="${base_name%-design.md}"
  base_name="${base_name%.md}"

  case "$artifact_dir" in
    docs/plans|docs/plans/*|*/docs/plans|*/docs/plans/*)
      printf '%s/%s-plan.md\n' "$artifact_dir" "$base_name"
      ;;
    *)
      printf 'docs/plans/changes/%s-plan.md\n' "$base_name"
      ;;
  esac
}

plan_entry_phase() {
  next_phase_for_entry "plan-change"
}

plan_task_metadata_mode() {
  case "${PLAN_RUNNER_TASK_METADATA_MODE:-compat}" in
    compat|strict) printf '%s\n' "${PLAN_RUNNER_TASK_METADATA_MODE:-compat}" ;;
    *)
      printf 'invalid PLAN_RUNNER_TASK_METADATA_MODE: %s\n' "${PLAN_RUNNER_TASK_METADATA_MODE:-}" >&2
      return 1
      ;;
  esac
}

validate_execution_grade_plan_artifact() {
  local plan_file="$1"

  (
    export PLAN_RUNNER_TASK_METADATA_MODE=strict
    validate_plan_artifact "$plan_file"
  )
}

list_plan_task_sections() {
  local plan_file="$1"

  awk '
    /^## Task [0-9]+:/ {
      sub(/^## /, "", $0)
      print $0
    }
  ' "$plan_file"
}

task_section_has_any_metadata() {
  local plan_file="$1"
  local section="$2"
  local key=""

  for key in \
    task_id \
    depends_on \
    scope_slice \
    impl_file_refs \
    test_file_refs \
    verification_scope \
    executor_mode \
    task_review_depth \
    done_when \
    rollback_on_failure
  do
    if [[ -n "$(extract_markdown_scalar "$plan_file" "$section" "$key")" ]]; then
      return 0
    fi

    if [[ -n "$(extract_markdown_list "$plan_file" "$section" "$key" | awk 'NF > 0')" ]]; then
      return 0
    fi
  done

  return 1
}

plan_has_task_metadata() {
  local plan_file="$1"
  local section=""
  local -a task_sections=()

  mapfile -t task_sections < <(list_plan_task_sections "$plan_file")

  for section in "${task_sections[@]}"; do
    if task_section_has_any_metadata "$plan_file" "$section"; then
      return 0
    fi
  done

  return 1
}

plan_requires_readiness_contract() {
  local plan_file="$1"
  local mode=""

  mode="$(plan_task_metadata_mode)"
  [[ "$mode" == "strict" ]] || plan_has_task_metadata "$plan_file"
}

validate_plan_readiness_contract() {
  local plan_file="$1"
  local field=""
  local decision_status=""
  local max_review_batches=""
  local subagent_ready=""

  if ! plan_requires_readiness_contract "$plan_file"; then
    return 0
  fi

  rg -n '^## Work Package Readiness$' "$plan_file" >/dev/null || {
    printf 'plan artifact missing required section: ^## Work Package Readiness$\n' >&2
    return 1
  }

  for field in milestone_objective decision_status oracle_strategy max_review_batches subagent_ready; do
    [[ -n "$(extract_markdown_scalar "$plan_file" "Work Package Readiness" "$field")" ]] || {
      printf 'plan readiness missing required scalar field: %s\n' "$field" >&2
      return 1
    }
  done

  for field in non_goals future_phase acceptance_oracles; do
    [[ -n "$(extract_markdown_list "$plan_file" "Work Package Readiness" "$field" | awk 'NF > 0')" ]] || {
      printf 'plan readiness missing required list field: %s\n' "$field" >&2
      return 1
    }
  done

  decision_status="$(extract_markdown_scalar "$plan_file" "Work Package Readiness" "decision_status")"
  case "$decision_status" in
    ready_for_review|needs_design_decision|split_scope|manual_checkpoint) ;;
    *)
      printf 'plan readiness decision_status must be ready_for_review, needs_design_decision, split_scope, or manual_checkpoint\n' >&2
      return 1
      ;;
  esac

  max_review_batches="$(extract_markdown_scalar "$plan_file" "Work Package Readiness" "max_review_batches")"
  [[ "$max_review_batches" =~ ^[0-9]+$ && "$max_review_batches" -ge 1 && "$max_review_batches" -le 2 ]] || {
    printf 'plan readiness max_review_batches must be an integer between 1 and 2\n' >&2
    return 1
  }

  subagent_ready="$(extract_markdown_scalar "$plan_file" "Work Package Readiness" "subagent_ready")"
  case "$subagent_ready" in
    true|false) ;;
    *)
      printf 'plan readiness subagent_ready must be true or false\n' >&2
      return 1
      ;;
  esac
}

validate_task_scalar_field() {
  local plan_file="$1"
  local section="$2"
  local key="$3"
  local value=""

  value="$(extract_markdown_scalar "$plan_file" "$section" "$key")"
  [[ -n "$value" ]] || {
    printf 'plan task missing required scalar field (%s) in section: %s\n' "$key" "$section" >&2
    return 1
  }
}

validate_task_list_field() {
  local plan_file="$1"
  local section="$2"
  local key="$3"
  local value=""

  value="$(extract_markdown_list "$plan_file" "$section" "$key" | awk 'NF > 0')"
  [[ -n "$value" ]] || {
    printf 'plan task missing required list field (%s) in section: %s\n' "$key" "$section" >&2
    return 1
  }
}

validate_plan_task_contracts() {
  local plan_file="$1"
  local mode=""
  local section=""
  local saw_task_metadata=0
  local -a task_sections=()

  mode="$(plan_task_metadata_mode)"
  mapfile -t task_sections < <(list_plan_task_sections "$plan_file")
  [[ "${#task_sections[@]}" -gt 0 ]] || {
    printf 'plan artifact must contain at least one task section\n' >&2
    return 1
  }

  for section in "${task_sections[@]}"; do
    if task_section_has_any_metadata "$plan_file" "$section"; then
      saw_task_metadata=1
      break
    fi
  done

  if [[ "$mode" == "compat" && "$saw_task_metadata" -eq 0 ]]; then
    return 0
  fi

  for section in "${task_sections[@]}"; do
    validate_task_scalar_field "$plan_file" "$section" "task_id" || return 1
    validate_task_list_field "$plan_file" "$section" "depends_on" || return 1
    validate_task_scalar_field "$plan_file" "$section" "scope_slice" || return 1
    validate_task_list_field "$plan_file" "$section" "impl_file_refs" || return 1
    validate_task_list_field "$plan_file" "$section" "test_file_refs" || return 1
    validate_task_list_field "$plan_file" "$section" "verification_scope" || return 1
    validate_task_scalar_field "$plan_file" "$section" "executor_mode" || return 1
    validate_task_scalar_field "$plan_file" "$section" "task_review_depth" || return 1
    validate_task_list_field "$plan_file" "$section" "done_when" || return 1
    validate_task_scalar_field "$plan_file" "$section" "rollback_on_failure" || return 1
  done
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

  validate_plan_task_contracts "$plan_file"
  validate_plan_readiness_contract "$plan_file"
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
