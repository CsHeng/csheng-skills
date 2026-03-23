#!/usr/bin/env bash
# output-validator.sh - Output normalization and validation for review orchestrator
#
# Exports:
#   normalize_output()
#   validate_reviewer_output()
#   validate_run_output()
#   build_scope_json()
#   build_run_output()

normalize_output() {
  local output_file="$1"
  local normalized_file="${output_file}.normalized"
  if jq -e . "$output_file" >/dev/null 2>&1; then
    return
  fi
  # Strip leading/trailing blank lines, markdown code fences, and trailing whitespace
  sed -e '/^[[:space:]]*$/d' -e '/^```[[:alpha:]]*$/d' -e '/^```$/d' "$output_file" > "$normalized_file"
  if jq -e . "$normalized_file" >/dev/null 2>&1; then
    mv "$normalized_file" "$output_file"
    return
  fi
  rm -f "$normalized_file"
  die $EXIT_SCHEMA_VALIDATION_FAILED "reviewer output is not valid JSON: $output_file"
}

validate_reviewer_output() {
  local output_file="$1"
  jq -e . "$output_file" >/dev/null || return 1
  jq -e '
    def nonempty: type == "string" and length > 0;
    type == "object"
    and (.lens | nonempty)
    and (.verdict == "PASS" or .verdict == "FAIL")
    and (.summary | nonempty)
    and (.pass_rationale | type == "string")
    and (.findings | type == "array")
    and (all(.findings[]?;
      type == "object"
      and (.severity == "Critical" or .severity == "Important" or .severity == "Minor")
      and (.location | nonempty)
      and (.evidence | nonempty)
      and (.impact | nonempty)
      and (.fix | nonempty)
      and (.confidence == "high" or .confidence == "medium" or .confidence == "low")
    ))
  ' "$output_file" >/dev/null || return 1
}

validate_run_output() {
  local output_file="$1"
  jq -e '
    def nonempty: type == "string" and length > 0;
    type == "object"
    and (.mode == "design" or .mode == "plan" or .mode == "code-impl")
    and (.host | nonempty)
    and (.reviewer | nonempty)
    and (.reviewer_model | nonempty)
    and (.review_mode == "cross-driver" or .review_mode == "same-driver")
    and (.status == "pass" or .status == "needs_fixes" or .status == "manual_review_required")
    and (.next_action == "stop_passed" or .next_action == "host_fix_then_rerun" or .next_action == "human_decision_required")
    and (.manual_intervention_required | type == "boolean")
    and (.batch | type == "number")
    and (.round | type == "number")
    and (.max_rounds | type == "number")
    and (.suggested_next_batch | type == "number")
    and (.suggested_next_round | type == "number")
    and (.blocking_findings | type == "array")
    and (.scope | type == "object")
    and (.scope.workspace_root | nonempty)
    and (.scope.workspace_mode == "isolated")
    and (.scope.spec_baseline == "design" or .scope.spec_baseline == "plan" or .scope.spec_baseline == "inferred")
    and (.result | type == "object")
  ' "$output_file" >/dev/null || return 1
  jq -e --argfile schema "$RUN_SCHEMA_PATH" '.' "$output_file" >/dev/null 2>&1 || true
}

build_scope_json() {
  local scope_file="$1"
  local file_list_json="[]"
  if [[ "$MODE" == "code-impl" ]]; then
    file_list_json="$(printf '%s\n' "${CODE_IMPL_SCOPE[@]}" | jq -R . | jq -s .)"
  fi

  jq -n \
    --arg mode "$MODE" \
    --arg workspace_root "$WORKSPACE_ROOT" \
    --arg spec_baseline "$SPEC_BASELINE" \
    --arg plan_path "${WORKSPACE_PLAN_PATH:-}" \
    --argjson files "$file_list_json" '
      {
        mode: $mode,
        workspace_root: $workspace_root,
        workspace_mode: "isolated",
        spec_baseline: $spec_baseline,
        plan_path: $plan_path,
        files: $files
      }
    ' > "$scope_file"
}

build_run_output() {
  local reviewer_json="$1" scope_json="$2" run_output="$3" review_mode="$4" reviewer="$5" reviewer_model="$6"
  local blocking_findings_json verdict blocking_count
  local status next_action manual_required suggested_next_round suggested_next_batch
  local reconciliation_note=""

  blocking_findings_json="$(jq '[.findings[] | select(.severity == "Critical" or .severity == "Important")]' "$reviewer_json")"
  verdict="$(jq -r '.verdict' "$reviewer_json")"
  blocking_count="$(jq 'length' <<< "$blocking_findings_json")"
  if ! [[ "$blocking_count" =~ ^[0-9]+$ ]]; then
    die $EXIT_SCHEMA_VALIDATION_FAILED "failed to compute blocking_findings count"
  fi

  if [[ "$verdict" == "PASS" ]]; then
    status="pass"
    next_action="stop_passed"
    manual_required="false"
    suggested_next_round="$ROUND_NUMBER"
    suggested_next_batch="$BATCH_NUMBER"
  elif [[ "$ROUND_NUMBER" -lt "$MAX_ROUNDS" ]]; then
    status="needs_fixes"
    next_action="host_fix_then_rerun"
    manual_required="false"
    suggested_next_round=$((ROUND_NUMBER + 1))
    suggested_next_batch="$BATCH_NUMBER"
  else
    status="manual_review_required"
    next_action="human_decision_required"
    manual_required="true"
    suggested_next_round=1
    suggested_next_batch=$((BATCH_NUMBER + 1))
  fi

  # severity-gated findings are authoritative; bare verdict string is advisory
  if [[ "$verdict" == "FAIL" && "$blocking_count" -eq 0 ]]; then
    log "[run-review] step=reconcile verdict=FAIL blocking_count=0 action=override_to_pass"
    status="pass"
    next_action="stop_passed"
    manual_required="false"
    suggested_next_round="$ROUND_NUMBER"
    suggested_next_batch="$BATCH_NUMBER"
    reconciliation_note="Reviewer returned FAIL with no Critical/Important findings; reconciled to PASS"
  elif [[ "$verdict" == "PASS" && "$blocking_count" -gt 0 ]]; then
    log "[run-review] step=reconcile verdict=PASS blocking_count=$blocking_count action=override_to_fail"
    if [[ "$ROUND_NUMBER" -ge "$MAX_ROUNDS" ]]; then
      status="manual_review_required"
      next_action="human_decision_required"
      manual_required="true"
      suggested_next_round=1
      suggested_next_batch=$((BATCH_NUMBER + 1))
      reconciliation_note="Reviewer returned PASS with Critical/Important findings; reconciled to FAIL; rounds exhausted"
    else
      status="needs_fixes"
      next_action="host_fix_then_rerun"
      manual_required="false"
      suggested_next_round=$((ROUND_NUMBER + 1))
      suggested_next_batch="$BATCH_NUMBER"
      reconciliation_note="Reviewer returned PASS with Critical/Important findings; reconciled to FAIL"
    fi
  fi

  jq -n \
    --arg mode "$MODE" \
    --arg host "$HOST" \
    --arg reviewer "$reviewer" \
    --arg reviewer_model "$reviewer_model" \
    --arg review_mode "$review_mode" \
    --arg status "$status" \
    --arg next_action "$next_action" \
    --argjson manual_intervention_required "$manual_required" \
    --argjson batch "$BATCH_NUMBER" \
    --argjson round "$ROUND_NUMBER" \
    --argjson max_rounds "$MAX_ROUNDS" \
    --argjson suggested_next_batch "$suggested_next_batch" \
    --argjson suggested_next_round "$suggested_next_round" \
    --argjson blocking_findings "$blocking_findings_json" \
    --arg reconciliation_note "$reconciliation_note" \
    --slurpfile scope "$scope_json" \
    --slurpfile result "$reviewer_json" '
      {
        mode: $mode,
        host: $host,
        reviewer: $reviewer,
        reviewer_model: $reviewer_model,
        review_mode: $review_mode,
        status: $status,
        next_action: $next_action,
        manual_intervention_required: $manual_intervention_required,
        batch: $batch,
        round: $round,
        max_rounds: $max_rounds,
        suggested_next_batch: $suggested_next_batch,
        suggested_next_round: $suggested_next_round,
        blocking_findings: $blocking_findings,
        reconciliation_note: $reconciliation_note,
        scope: $scope[0],
        result: $result[0]
      }
    ' > "$run_output"
}
