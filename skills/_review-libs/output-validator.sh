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
    def has_only($allowed): keys_unsorted | all(. as $k | $allowed | index($k) != null);
    def finding_valid:
      type == "object"
      and has_only(["severity", "location", "evidence", "impact", "fix", "confidence", "scope_class"])
      and (.severity == "Critical" or .severity == "Important" or .severity == "Minor")
      and (.location | nonempty)
      and (.evidence | nonempty)
      and (.impact | nonempty)
      and (.fix | nonempty)
      and (.confidence == "high" or .confidence == "medium" or .confidence == "low")
      and (
        .scope_class == "baseline_mismatch"
        or .scope_class == "in_scope_blocking"
        or .scope_class == "adjacent_debt"
        or .scope_class == "out_of_dag_issue"
        or .scope_class == "external_verification_failure"
      );
    type == "object"
    and has_only(["lens", "verdict", "summary", "findings", "pass_rationale"])
    and has("lens")
    and has("verdict")
    and has("summary")
    and has("findings")
    and has("pass_rationale")
    and (.lens | nonempty)
    and (.verdict == "PASS" or .verdict == "FAIL")
    and (.summary | nonempty)
    and (.pass_rationale | type == "string")
    and ((.verdict == "PASS" and (.pass_rationale | nonempty)) or .verdict == "FAIL")
    and (.findings | type == "array")
    and (all(.findings[]?; finding_valid))
  ' "$output_file" >/dev/null || return 1
}

validate_run_output() {
  local output_file="$1"
  jq -e '
    def nonempty: type == "string" and length > 0;
    def positive_int: type == "number" and floor == . and . >= 1;
    def has_only($allowed): keys_unsorted | all(. as $k | $allowed | index($k) != null);
    def finding_valid:
      type == "object"
      and has_only(["severity", "location", "evidence", "impact", "fix", "confidence", "scope_class"])
      and (.severity == "Critical" or .severity == "Important" or .severity == "Minor")
      and (.location | nonempty)
      and (.evidence | nonempty)
      and (.impact | nonempty)
      and (.fix | nonempty)
      and (.confidence == "high" or .confidence == "medium" or .confidence == "low")
      and (
        .scope_class == "baseline_mismatch"
        or .scope_class == "in_scope_blocking"
        or .scope_class == "adjacent_debt"
        or .scope_class == "out_of_dag_issue"
        or .scope_class == "external_verification_failure"
      );
    def reviewer_valid:
      type == "object"
      and has_only(["lens", "verdict", "summary", "findings", "pass_rationale"])
      and has("lens")
      and has("verdict")
      and has("summary")
      and has("findings")
      and has("pass_rationale")
      and (.lens | nonempty)
      and (.verdict == "PASS" or .verdict == "FAIL")
      and (.summary | nonempty)
      and (.pass_rationale | type == "string")
      and ((.verdict == "PASS" and (.pass_rationale | nonempty)) or .verdict == "FAIL")
      and (.findings | type == "array")
      and (all(.findings[]?; finding_valid));
    def scope_valid:
      type == "object"
      and has_only([
        "mode",
        "workspace_root",
        "workspace_mode",
        "spec_baseline",
        "plan_path",
        "design_path",
        "design_version",
        "allowed_touch_set",
        "out_of_scope_touched_files",
        "files"
      ])
      and has("mode")
      and has("workspace_root")
      and has("workspace_mode")
      and has("spec_baseline")
      and has("plan_path")
      and has("design_path")
      and has("design_version")
      and has("allowed_touch_set")
      and has("out_of_scope_touched_files")
      and has("files")
      and (.mode == "design" or .mode == "plan" or .mode == "code-impl")
      and (.workspace_root | nonempty)
      and (.workspace_mode == "isolated")
      and (.spec_baseline == "design" or .spec_baseline == "plan" or .spec_baseline == "inferred")
      and (.plan_path | type == "string")
      and (.design_path | type == "string")
      and (.design_version | type == "string")
      and (.allowed_touch_set | type == "array")
      and (.out_of_scope_touched_files | type == "array")
      and (.files | type == "array")
      and (all(.allowed_touch_set[]?; nonempty))
      and (all(.out_of_scope_touched_files[]?; nonempty))
      and (all(.files[]?; nonempty));
    type == "object"
    and has_only([
      "mode",
      "host",
      "reviewer",
      "reviewer_model",
      "review_mode",
      "status",
      "next_action",
      "manual_intervention_required",
      "batch",
      "round",
      "max_rounds",
      "suggested_next_batch",
      "suggested_next_round",
      "blocking_findings",
      "scope",
      "result"
    ])
    and has("mode")
    and has("host")
    and has("reviewer")
    and has("reviewer_model")
    and has("review_mode")
    and has("status")
    and has("next_action")
    and has("manual_intervention_required")
    and has("batch")
    and has("round")
    and has("max_rounds")
    and has("suggested_next_batch")
    and has("suggested_next_round")
    and has("blocking_findings")
    and has("scope")
    and has("result")
    and (.mode == "design" or .mode == "plan" or .mode == "code-impl")
    and (.host | nonempty)
    and (.reviewer | nonempty)
    and (.reviewer_model | nonempty)
    and (.review_mode == "cross-driver" or .review_mode == "same-driver")
    and (.status == "pass" or .status == "needs_fixes" or .status == "manual_review_required")
    and (.next_action == "stop_passed" or .next_action == "host_fix_then_rerun" or .next_action == "human_decision_required")
    and (.manual_intervention_required | type == "boolean")
    and (.batch | positive_int)
    and (.round | positive_int)
    and (.max_rounds | positive_int)
    and (.suggested_next_batch | positive_int)
    and (.suggested_next_round | positive_int)
    and (.blocking_findings | type == "array")
    and (all(.blocking_findings[]?; finding_valid))
    and (.scope | scope_valid)
    and (.result | reviewer_valid)
  ' "$output_file" >/dev/null || return 1
}

build_scope_json() {
  local scope_file="$1"
  local file_list_json="[]"
  local allowed_touch_set_json="[]"
  local out_of_scope_touched_files_json="[]"
  if [[ "$MODE" == "code-impl" ]]; then
    file_list_json="$(printf '%s\n' "${CODE_IMPL_SCOPE[@]}" | jq -R . | jq -s .)"
    allowed_touch_set_json="$file_list_json"
  fi
  if declare -p ALLOWED_TOUCH_SET >/dev/null 2>&1; then
    if [[ "${#ALLOWED_TOUCH_SET[@]}" -eq 0 ]]; then
      allowed_touch_set_json="[]"
    else
      allowed_touch_set_json="$(printf '%s\n' "${ALLOWED_TOUCH_SET[@]}" | jq -R . | jq -s .)"
    fi
  fi
  if declare -p OUT_OF_SCOPE_TOUCHED_FILES >/dev/null 2>&1; then
    if [[ "${#OUT_OF_SCOPE_TOUCHED_FILES[@]}" -eq 0 ]]; then
      out_of_scope_touched_files_json="[]"
    else
      out_of_scope_touched_files_json="$(printf '%s\n' "${OUT_OF_SCOPE_TOUCHED_FILES[@]}" | jq -R . | jq -s .)"
    fi
  fi

  jq -n \
    --arg mode "$MODE" \
    --arg workspace_root "$WORKSPACE_ROOT" \
    --arg spec_baseline "$SPEC_BASELINE" \
    --arg plan_path "${WORKSPACE_PLAN_PATH:-}" \
    --arg design_path "${WORKSPACE_DESIGN_PATH:-${DESIGN_PATH:-}}" \
    --arg design_version "${DESIGN_VERSION:-}" \
    --argjson allowed_touch_set "$allowed_touch_set_json" \
    --argjson out_of_scope_touched_files "$out_of_scope_touched_files_json" \
    --argjson files "$file_list_json" '
      {
        mode: $mode,
        workspace_root: $workspace_root,
        workspace_mode: "isolated",
        spec_baseline: $spec_baseline,
        plan_path: $plan_path,
        design_path: $design_path,
        design_version: $design_version,
        allowed_touch_set: $allowed_touch_set,
        out_of_scope_touched_files: $out_of_scope_touched_files,
        files: $files
      }
    ' > "$scope_file"
}

build_run_output() {
  local reviewer_json="$1" scope_json="$2" run_output="$3" review_mode="$4" reviewer="$5" reviewer_model="$6"
  local blocking_findings_json verdict blocking_count reconciled_verdict
  local status next_action manual_required suggested_next_round suggested_next_batch
  local result_json pass_rationale

  blocking_findings_json="$(jq '[.findings[] | select(.severity == "Critical" or .severity == "Important")]' "$reviewer_json")"
  verdict="$(jq -r '.verdict' "$reviewer_json")"
  reconciled_verdict="$verdict"
  pass_rationale="$(jq -r '.pass_rationale' "$reviewer_json")"
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
    reconciled_verdict="PASS"
    pass_rationale="Reconciled to PASS: no Critical/Important findings were returned."
  elif [[ "$verdict" == "PASS" && "$blocking_count" -gt 0 ]]; then
    log "[run-review] step=reconcile verdict=PASS blocking_count=$blocking_count action=override_to_fail"
    reconciled_verdict="FAIL"
    pass_rationale=""
    if [[ "$ROUND_NUMBER" -ge "$MAX_ROUNDS" ]]; then
      status="manual_review_required"
      next_action="human_decision_required"
      manual_required="true"
      suggested_next_round=1
      suggested_next_batch=$((BATCH_NUMBER + 1))
    else
      status="needs_fixes"
      next_action="host_fix_then_rerun"
      manual_required="false"
      suggested_next_round=$((ROUND_NUMBER + 1))
      suggested_next_batch="$BATCH_NUMBER"
    fi
  fi

  result_json="$(jq \
    --arg verdict "$reconciled_verdict" \
    --arg pass_rationale "$pass_rationale" \
    '.verdict = $verdict | .pass_rationale = $pass_rationale' \
    "$reviewer_json")"

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
    --slurpfile scope "$scope_json" \
    --argjson result "$result_json" '
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
        scope: $scope[0],
        result: $result
      }
    ' > "$run_output"
}
