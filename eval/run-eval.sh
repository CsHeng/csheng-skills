#!/usr/bin/env bash
# Eval runner for the cross-model review plugin.
# Discovers golden test cases for a given mode, runs the review script N times,
# and emits a JSON result matching eval/schema/eval-result.schema.json.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'USAGE'
Usage:
  eval/run-eval.sh --mode <plan|design|code-impl|all> --reviewer <claude|codex|gemini> [options]

Options:
  --mode <plan|design|code-impl|all>   Review mode to evaluate. Required.
  --reviewer <claude|codex|gemini>     Reviewer CLI to use. Required.
  --runs <N>                           Number of runs per case. Default: 1.
  --timeout <seconds>                  Per-run timeout in seconds. Default: 1800.
  --min-detection-rate <rate>          Minimum detection rate threshold (0.0-1.0). Default: 0.0.
  -h, --help                           Show this help.
USAGE
}

log() {
  printf '[eval] %s\n' "$*" >&2
}

die() {
  printf '[eval] error: %s\n' "$*" >&2
  exit 1
}

MODE=""
REVIEWER=""
RUNS=1
TIMEOUT_SECONDS=1800
MIN_DETECTION_RATE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="$2"
      shift 2
      ;;
    --reviewer)
      REVIEWER="$2"
      shift 2
      ;;
    --runs)
      RUNS="$2"
      shift 2
      ;;
    --timeout)
      TIMEOUT_SECONDS="$2"
      shift 2
      ;;
    --min-detection-rate)
      MIN_DETECTION_RATE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[[ -n "$MODE" ]]     || die "--mode is required"
[[ -n "$REVIEWER" ]] || die "--reviewer is required"

case "$MODE" in
  plan|design|code-impl|all) ;;
  *) die "invalid mode: $MODE. Must be plan, design, code-impl, or all" ;;
esac

case "$REVIEWER" in
  claude|codex|gemini) ;;
  *) die "invalid reviewer: $REVIEWER. Must be claude, codex, or gemini" ;;
esac

[[ "$RUNS" =~ ^[0-9]+$ && "$RUNS" -ge 1 ]] || die "--runs must be a positive integer"

GOLDEN_DIR="$SCRIPT_DIR/golden"
[[ -d "$GOLDEN_DIR" ]] || die "golden directory not found: $GOLDEN_DIR"

# resolve_review_script maps a mode to the run-review.sh path under skills/
resolve_review_script() {
  local mode="$1"
  case "$mode" in
    plan)      printf '%s\n' "$ROOT_DIR/skills/review-plan/scripts/run-review.sh" ;;
    design)    printf '%s\n' "$ROOT_DIR/skills/review-design/scripts/run-review.sh" ;;
    code-impl) printf '%s\n' "$ROOT_DIR/skills/review-code-impl/scripts/run-review.sh" ;;
    *) die "resolve_review_script: unsupported mode: $mode" ;;
  esac
}

# discover_cases lists manifest JSON files for a given mode
discover_cases() {
  local mode="$1"
  local manifest=""
  for manifest in "$GOLDEN_DIR"/"${mode}"-*.json; do
    [[ -f "$manifest" ]] && printf '%s\n' "$manifest"
  done
}

# run_single_case runs the review script once for a case manifest, writes raw JSON to output_file.
# Returns 0 on success (valid JSON produced), 1 otherwise.
run_single_case() {
  local case_mode="$1"
  local input_file="$2"
  local output_file="$3"
  local review_script
  review_script="$(resolve_review_script "$case_mode")"
  [[ -f "$review_script" ]] || { log "review script not found: $review_script"; return 1; }

  local input_abs="$GOLDEN_DIR/$input_file"
  [[ -f "$input_abs" ]] || { log "input file not found: $input_abs"; return 1; }

  local invoke_rc=0
  if [[ "$case_mode" == "code-impl" ]]; then
    timeout "$TIMEOUT_SECONDS" bash "$review_script" \
      --host claude \
      --file "$input_abs" \
      --reviewer "$REVIEWER" \
      --allow-same-model-fallback \
      > "$output_file" 2>/dev/null || invoke_rc=$?
  else
    timeout "$TIMEOUT_SECONDS" bash "$review_script" \
      --host claude \
      --plan "$input_abs" \
      --reviewer "$REVIEWER" \
      --allow-same-model-fallback \
      > "$output_file" 2>/dev/null || invoke_rc=$?
  fi

  if [[ "$invoke_rc" -ne 0 ]]; then
    log "review script exited with code=$invoke_rc for input=$input_file"
    return 1
  fi

  if ! jq -e . "$output_file" >/dev/null 2>&1; then
    log "output is not valid JSON for input=$input_file"
    return 1
  fi

  return 0
}

# pattern_found checks whether any blocking_findings field in the JSON output matches the pattern
pattern_found() {
  local output_file="$1"
  local pattern="$2"
  local combined
  combined="$(jq -r '[.blocking_findings[]? | .evidence, .location, .fix] | join(" ")' "$output_file" 2>/dev/null || true)"
  if printf '%s' "$combined" | grep -iqE "$pattern" 2>/dev/null; then
    return 0
  fi
  # also check result.findings for broader coverage
  combined="$(jq -r '[.result.findings[]? | .evidence, .location, .fix] | join(" ")' "$output_file" 2>/dev/null || true)"
  if printf '%s' "$combined" | grep -iqE "$pattern" 2>/dev/null; then
    return 0
  fi
  return 1
}

# eval_case runs a single golden case N times and returns a JSON case result object
eval_case() {
  local manifest="$1"
  local case_id case_mode input_file expected_verdict
  case_id="$(jq -r '.id' "$manifest")"
  case_mode="$(jq -r '.mode' "$manifest")"
  input_file="$(jq -r '.input_file' "$manifest")"
  expected_verdict="$(jq -r '.expected_verdict' "$manifest")"

  local expected_patterns_json
  expected_patterns_json="$(jq -c '[.expected_findings[]?.match_pattern // empty]' "$manifest" 2>/dev/null || printf '[]')"

  local TMP_CASE
  TMP_CASE="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '$TMP_CASE'" RETURN

  local run_idx actual_verdict_first=""
  local verdicts_json="[]"
  local found_patterns_set=()
  local detection_hits=0
  local false_positive_hits=0
  local consistency_matches=0

  for run_idx in $(seq 1 "$RUNS"); do
    log "case=$case_id run=$run_idx/$RUNS status=starting"
    local out_file="$TMP_CASE/run-${run_idx}.json"
    local run_ok=0
    run_single_case "$case_mode" "$input_file" "$out_file" || run_ok=1

    if [[ "$run_ok" -ne 0 ]]; then
      log "case=$case_id run=$run_idx/$RUNS status=error"
      continue
    fi

    local actual_verdict
    actual_verdict="$(jq -r '.result.verdict // "FAIL"' "$out_file")"
    verdicts_json="$(printf '%s' "$verdicts_json" | jq --arg v "$actual_verdict" '. + [$v]')"

    if [[ -z "$actual_verdict_first" ]]; then
      actual_verdict_first="$actual_verdict"
    fi

    # consistency: same verdict as first run
    if [[ "$actual_verdict" == "$actual_verdict_first" ]]; then
      consistency_matches=$((consistency_matches + 1))
    fi

    # detection: for FAIL cases, check if expected patterns appear in findings
    local pattern_hit=0
    if [[ "$expected_verdict" == "FAIL" ]]; then
      local pat
      while IFS= read -r pat; do
        [[ -n "$pat" ]] || continue
        if pattern_found "$out_file" "$pat"; then
          pattern_hit=1
          # track which patterns were found (deduplicated by accumulating into array)
          local already=0
          local fp
          for fp in "${found_patterns_set[@]:-}"; do
            [[ "$fp" == "$pat" ]] && already=1 && break
          done
          [[ "$already" -eq 0 ]] && found_patterns_set+=("$pat")
        fi
      done < <(printf '%s' "$expected_patterns_json" | jq -r '.[]')
      [[ "$pattern_hit" -eq 1 ]] && detection_hits=$((detection_hits + 1))
    fi

    # false positive: PASS case scored FAIL
    if [[ "$expected_verdict" == "PASS" && "$actual_verdict" == "FAIL" ]]; then
      false_positive_hits=$((false_positive_hits + 1))
    fi

    local run_status="pass"
    [[ "$actual_verdict" == "$expected_verdict" ]] || run_status="fail"
    log "case=$case_id run=$run_idx/$RUNS status=$run_status verdict=$actual_verdict expected=$expected_verdict"
  done

  local actual_verdict_final="${actual_verdict_first:-FAIL}"
  local verdict_match="false"
  [[ "$actual_verdict_final" == "$expected_verdict" ]] && verdict_match="true"

  local det_rate fp_rate cons_rate
  if [[ "$expected_verdict" == "FAIL" && "$RUNS" -gt 0 ]]; then
    det_rate="$(printf '%s %s' "$detection_hits" "$RUNS" | awk '{printf "%.6f", $1/$2}')"
  else
    det_rate="1.0"
  fi

  if [[ "$expected_verdict" == "PASS" && "$RUNS" -gt 0 ]]; then
    fp_rate="$(printf '%s %s' "$false_positive_hits" "$RUNS" | awk '{printf "%.6f", $1/$2}')"
  else
    fp_rate="0.0"
  fi

  if [[ "$RUNS" -gt 0 ]]; then
    cons_rate="$(printf '%s %s' "$consistency_matches" "$RUNS" | awk '{printf "%.6f", $1/$2}')"
  else
    cons_rate="1.0"
  fi

  local found_patterns_json="[]"
  local fp
  for fp in "${found_patterns_set[@]:-}"; do
    found_patterns_json="$(printf '%s' "$found_patterns_json" | jq --arg p "$fp" '. + [$p]')"
  done

  jq -n \
    --arg id "$case_id" \
    --arg mode "$case_mode" \
    --arg expected_verdict "$expected_verdict" \
    --arg actual_verdict "$actual_verdict_final" \
    --argjson verdict_match "$verdict_match" \
    --argjson expected_patterns "$expected_patterns_json" \
    --argjson found_patterns "$found_patterns_json" \
    --argjson detection_rate "$det_rate" \
    --argjson false_positive_rate "$fp_rate" \
    --argjson runs "$RUNS" \
    '{
      id: $id,
      mode: $mode,
      expected_verdict: $expected_verdict,
      actual_verdict: $actual_verdict,
      verdict_match: $verdict_match,
      expected_patterns: $expected_patterns,
      found_patterns: $found_patterns,
      detection_rate: $detection_rate,
      false_positive_rate: $false_positive_rate,
      runs: $runs
    }'
}

# collect_modes returns the list of concrete modes to evaluate
collect_modes() {
  local mode="$1"
  if [[ "$mode" == "all" ]]; then
    printf '%s\n' plan design code-impl
  else
    printf '%s\n' "$mode"
  fi
}

main() {
  local eval_id="eval-${MODE}-${REVIEWER}-$(date -u +%Y%m%dT%H%M%SZ)"
  local cases_json="[]"
  local total_detection_hits=0
  local total_detection_cases=0
  local total_fp_hits=0
  local total_fp_cases=0
  local total_consistency=0
  local total_runs_count=0
  local overall_verdict_correct="true"

  local mode_iter
  while IFS= read -r mode_iter; do
    local manifest
    local found_any=0
    while IFS= read -r manifest; do
      [[ -f "$manifest" ]] || continue
      found_any=1
      log "case=$(jq -r '.id' "$manifest") mode=$mode_iter discovering"
      local case_result
      case_result="$(eval_case "$manifest")"
      cases_json="$(printf '%s' "$cases_json" | jq --argjson c "$case_result" '. + [$c]')"

      local expected_v actual_v det_r fp_r
      expected_v="$(printf '%s' "$case_result" | jq -r '.expected_verdict')"
      actual_v="$(printf '%s' "$case_result" | jq -r '.actual_verdict')"
      det_r="$(printf '%s' "$case_result" | jq -r '.detection_rate')"
      fp_r="$(printf '%s' "$case_result" | jq -r '.false_positive_rate')"

      if [[ "$actual_v" != "$expected_v" ]]; then
        overall_verdict_correct="false"
      fi

      if [[ "$expected_v" == "FAIL" ]]; then
        total_detection_cases=$((total_detection_cases + 1))
        local det_hits
        det_hits="$(printf '%s %s' "$det_r" "$RUNS" | awk '{printf "%d", $1 * $2 + 0.5}')"
        total_detection_hits=$((total_detection_hits + det_hits))
      fi

      if [[ "$expected_v" == "PASS" ]]; then
        total_fp_cases=$((total_fp_cases + 1))
        local fp_hits
        fp_hits="$(printf '%s %s' "$fp_r" "$RUNS" | awk '{printf "%d", $1 * $2 + 0.5}')"
        total_fp_hits=$((total_fp_hits + fp_hits))
      fi

      total_consistency=$((total_consistency + RUNS))
      total_runs_count=$((total_runs_count + RUNS))
    done < <(discover_cases "$mode_iter")

    [[ "$found_any" -eq 1 ]] || log "no golden cases found for mode=$mode_iter"
  done < <(collect_modes "$MODE")

  local agg_detection_rate agg_fp_rate agg_consistency_rate
  if [[ "$total_detection_cases" -gt 0 ]]; then
    agg_detection_rate="$(printf '%s %s' "$total_detection_hits" "$((total_detection_cases * RUNS))" | awk '{printf "%.6f", ($2>0)?$1/$2:1.0}')"
  else
    agg_detection_rate="1.0"
  fi

  if [[ "$total_fp_cases" -gt 0 ]]; then
    agg_fp_rate="$(printf '%s %s' "$total_fp_hits" "$((total_fp_cases * RUNS))" | awk '{printf "%.6f", ($2>0)?$1/$2:0.0}')"
  else
    agg_fp_rate="0.0"
  fi

  if [[ "$total_runs_count" -gt 0 ]]; then
    local cons_matches
    cons_matches="$(printf '%s' "$cases_json" | jq '[.[].runs] | add // 0')"
    agg_consistency_rate="$(printf '%s %s' "$cons_matches" "$total_runs_count" | awk '{printf "%.6f", ($2>0)?$1/$2:1.0}')"
  else
    agg_consistency_rate="1.0"
  fi

  local result_json
  result_json="$(jq -n \
    --arg id "$eval_id" \
    --arg mode "$MODE" \
    --arg reviewer "$REVIEWER" \
    --argjson runs "$RUNS" \
    --argjson verdict_correct "$overall_verdict_correct" \
    --argjson detection_rate "$agg_detection_rate" \
    --argjson false_positive_rate "$agg_fp_rate" \
    --argjson consistency_rate "$agg_consistency_rate" \
    --argjson cases "$cases_json" \
    '{
      id: $id,
      mode: $mode,
      reviewer: $reviewer,
      runs: $runs,
      verdict_correct: $verdict_correct,
      detection_rate: $detection_rate,
      false_positive_rate: $false_positive_rate,
      consistency_rate: $consistency_rate,
      cases: $cases
    }')"

  printf '%s\n' "$result_json"

  log "eval complete id=$eval_id mode=$MODE reviewer=$REVIEWER detection_rate=$agg_detection_rate false_positive_rate=$agg_fp_rate"

  local threshold_ok=1
  local actual_det
  actual_det="$(printf '%s' "$result_json" | jq -r '.detection_rate')"
  threshold_ok="$(printf '%s %s' "$actual_det" "$MIN_DETECTION_RATE" | awk '{print ($1 >= $2) ? 1 : 0}')"
  if [[ "$threshold_ok" -eq 0 ]]; then
    log "FAIL detection_rate=$actual_det below min-detection-rate=$MIN_DETECTION_RATE"
    exit 1
  fi
  log "PASS detection_rate=$actual_det meets min-detection-rate=$MIN_DETECTION_RATE"
  exit 0
}

main
