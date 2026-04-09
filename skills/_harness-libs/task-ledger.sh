#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=skills/_harness-libs/contracts.sh
source "$SCRIPT_DIR/contracts.sh"
# shellcheck source=skills/_harness-libs/plan-runner.sh
source "$SCRIPT_DIR/plan-runner.sh"

strip_wrapping_backticks() {
  sed -E 's/^`(.*)`$/\1/'
}

extract_task_list_field() {
  local plan_file="$1"
  local section="$2"
  local key="$3"

  awk -v section="$section" -v key="$key" '
    BEGIN {
      in_section = 0
      in_key = 0
    }
    $0 ~ "^##[[:space:]]+" section "[[:space:]]*$" {
      in_section = 1
      in_key = 0
      next
    }
    in_section && $0 ~ "^##[[:space:]]+" {
      exit
    }
    in_section && $0 ~ "^[[:space:]]*-[[:space:]]*" key ":[[:space:]]*$" {
      in_key = 1
      next
    }
    in_section && in_key && $0 ~ "^[[:space:]]*-[[:space:]]*[A-Za-z0-9_-]+:[[:space:]]*.*$" {
      in_key = 0
      next
    }
    in_section && in_key && $0 ~ "^[[:space:]]*-[[:space:]]+" {
      line = $0
      sub(/^[[:space:]]*-[[:space:]]+/, "", line)
      print line
      next
    }
  ' "$plan_file"
}

task_title_from_section() {
  local section="$1"
  printf '%s\n' "${section#Task [0-9]*: }"
}

task_depends_on_json() {
  local plan_file="$1"
  local section="$2"

  extract_task_list_field "$plan_file" "$section" "depends_on" \
    | awk 'NF > 0' \
    | jq -R . \
    | jq -s .
}

task_list_field_json() {
  local plan_file="$1"
  local section="$2"
  local key="$3"

  extract_task_list_field "$plan_file" "$section" "$key" \
    | awk 'NF > 0' \
    | strip_wrapping_backticks \
    | jq -R . \
    | jq -s .
}

task_is_dependency_free() {
  local depends_on_json="$1"

  jq -e '
    length == 0 or
    all(.[]; . == "root" or . == "none")
  ' <<<"$depends_on_json" >/dev/null
}

task_catalog_json() {
  local plan_file="$1"
  local section=""
  local task_title=""
  local task_id=""
  local scope_slice=""
  local executor_mode=""
  local task_review_depth=""
  local rollback_on_failure=""
  local depends_on_json="[]"
  local impl_refs_json="[]"
  local test_refs_json="[]"
  local verification_json="[]"
  local done_when_json="[]"

  validate_execution_grade_plan_artifact "$plan_file" >/dev/null || return 1

  while IFS= read -r section; do
    [[ -n "$section" ]] || continue
    task_title="$(task_title_from_section "$section")"
    task_id="$(extract_markdown_scalar "$plan_file" "$section" "task_id")"
    scope_slice="$(extract_markdown_scalar "$plan_file" "$section" "scope_slice")"
    executor_mode="$(extract_markdown_scalar "$plan_file" "$section" "executor_mode")"
    task_review_depth="$(extract_markdown_scalar "$plan_file" "$section" "task_review_depth")"
    rollback_on_failure="$(extract_markdown_scalar "$plan_file" "$section" "rollback_on_failure")"
    depends_on_json="$(task_depends_on_json "$plan_file" "$section")"
    impl_refs_json="$(task_list_field_json "$plan_file" "$section" "impl_file_refs")"
    test_refs_json="$(task_list_field_json "$plan_file" "$section" "test_file_refs")"
    verification_json="$(task_list_field_json "$plan_file" "$section" "verification_scope")"
    done_when_json="$(task_list_field_json "$plan_file" "$section" "done_when")"

    jq -n \
      --arg section "$section" \
      --arg task_title "$task_title" \
      --arg task_id "$task_id" \
      --arg scope_slice "$scope_slice" \
      --arg executor_mode "$executor_mode" \
      --arg task_review_depth "$task_review_depth" \
      --arg rollback_on_failure "$rollback_on_failure" \
      --argjson depends_on "$depends_on_json" \
      --argjson impl_file_refs "$impl_refs_json" \
      --argjson test_file_refs "$test_refs_json" \
      --argjson verification_commands "$verification_json" \
      --argjson done_when "$done_when_json" \
      '{
        section: $section,
        title: $task_title,
        task_id: $task_id,
        depends_on: $depends_on,
        scope_slice: $scope_slice,
        impl_file_refs: $impl_file_refs,
        test_file_refs: $test_file_refs,
        verification_commands: $verification_commands,
        executor_mode: $executor_mode,
        task_review_depth: $task_review_depth,
        done_when: $done_when,
        rollback_on_failure: $rollback_on_failure
      }'
  done < <(list_plan_task_sections "$plan_file") | jq -s .
}

task_ledger_json() {
  local plan_file="$1"
  local catalog_json="[]"

  validate_execution_grade_plan_artifact "$plan_file" >/dev/null || return 1
  catalog_json="$(task_catalog_json "$plan_file")"

  jq '
    map(
      . as $task
      | $task + {
          status: (
            if (($task.depends_on | length) == 0) or
               ($task.depends_on | all(. == "root" or . == "none"))
            then "ready"
            else "pending"
            end
          ),
          attempt_count: 0,
          review_attempt_count: 0,
          failure_count: 0,
          last_failure_kind: "",
          active_impl_file_refs: $task.impl_file_refs,
          active_test_file_refs: $task.test_file_refs,
          started_at: null,
          completed_at: null,
          notes: ""
        }
    )
  ' <<<"$catalog_json"
}

task_ledger_next_ready_task_id() {
  local ledger_file="$1"

  jq -r '.[] | select(.status == "ready") | .task_id' "$ledger_file" | head -n 1
}

task_ledger_set_status() {
  local ledger_file="$1"
  local task_id="$2"
  local status="$3"
  local timestamp=""

  is_valid_task_status "$status" || {
    printf 'invalid task status: %s\n' "$status" >&2
    return 1
  }

  timestamp="$(date -u +%FT%TZ)"

  jq \
    --arg task_id "$task_id" \
    --arg status "$status" \
    --arg timestamp "$timestamp" \
    '
    map(
      if .task_id == $task_id then
        .status = $status
        | .started_at = (
            if $status == "in_progress" and .started_at == null then
              $timestamp
            else
              .started_at
            end
          )
        | .completed_at = (
            if $status == "done" then
              $timestamp
            else
              .completed_at
            end
          )
      else
        .
      end
    )
    ' "$ledger_file"
}

task_ledger_refresh_ready_states() {
  local ledger_file="$1"

  jq '
    def completed_task_ids:
      [ .[] | select(.status == "done") | .task_id ];

    . as $ledger
    | completed_task_ids as $done
    | map(
        if .status == "pending" then
          if ((.depends_on | length) == 0) or
             (.depends_on | all(. as $dep | $dep == "root" or $dep == "none" or ($done | index($dep))))
          then
            .status = "ready"
          else
            .
          end
        else
          .
        end
      )
  ' "$ledger_file"
}

build_execution_result() {
  local plan_path="$1"
  local ledger_file="$2"
  local current_phase="$3"
  local active_task_id="$4"
  local stop_reason="$5"
  local review_status="$6"
  local verify_status="$7"
  local next_entry="$8"
  local next_phase="$9"
  local human_input_required="${10}"
  local workspace_mode="${11:-current-checkout}"

  is_valid_execution_stop_reason "$stop_reason" || {
    printf 'invalid execution stop reason: %s\n' "$stop_reason" >&2
    return 1
  }

  case "$human_input_required" in
    true|false) ;;
    *)
      printf 'invalid human_input_required flag: %s\n' "$human_input_required" >&2
      return 1
      ;;
  esac

  jq -n \
    --arg execution_unit "plan" \
    --arg plan_path "$plan_path" \
    --arg current_phase "$current_phase" \
    --arg active_task_id "$active_task_id" \
    --arg stop_reason "$stop_reason" \
    --arg review_status "$review_status" \
    --arg verify_status "$verify_status" \
    --arg next_entry "$next_entry" \
    --arg next_phase "$next_phase" \
    --arg workspace_mode "$workspace_mode" \
    --argjson human_input_required "$human_input_required" \
    --argjson completed_task_count "$(jq '[.[] | select(.status == "done")] | length' "$ledger_file")" \
    --argjson remaining_task_count "$(jq '[.[] | select(.status != "done")] | length' "$ledger_file")" \
    --argjson total_task_count "$(jq 'length' "$ledger_file")" \
    '{
      execution_unit: $execution_unit,
      plan_path: $plan_path,
      current_phase: $current_phase,
      active_task_id: (if $active_task_id == "" then null else $active_task_id end),
      completed_task_count: $completed_task_count,
      remaining_task_count: $remaining_task_count,
      total_task_count: $total_task_count,
      stop_reason: $stop_reason,
      review_status: $review_status,
      verify_status: $verify_status,
      next_entry: $next_entry,
      next_phase: $next_phase,
      human_input_required: $human_input_required,
      workspace_mode: $workspace_mode
    }'
}

usage() {
  cat <<'EOF'
Usage:
  task-ledger.sh catalog <plan-file>
  task-ledger.sh init <plan-file>
  task-ledger.sh next-ready <ledger-json>
  task-ledger.sh set-status <ledger-json> <task-id> <status>
  task-ledger.sh refresh-ready <ledger-json>
  task-ledger.sh execution-result <plan-path> <ledger-json> <current-phase> <active-task-id-or-empty> <stop-reason> <review-status> <verify-status> <next-entry> <next-phase> <human-input-required> [workspace-mode]
EOF
}

main() {
  local command="${1:-}"

  case "$command" in
    catalog)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      task_catalog_json "$2"
      ;;
    init)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      task_ledger_json "$2"
      ;;
    next-ready)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      task_ledger_next_ready_task_id "$2"
      ;;
    set-status)
      [[ $# -eq 4 ]] || { usage >&2; return 1; }
      task_ledger_set_status "$2" "$3" "$4"
      ;;
    refresh-ready)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      task_ledger_refresh_ready_states "$2"
      ;;
    execution-result)
      [[ $# -ge 11 ]] || { usage >&2; return 1; }
      build_execution_result "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "${10}" "${11}" "${12:-current-checkout}"
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
