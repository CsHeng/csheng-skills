#!/usr/bin/env bash
# prompt-builder.sh - Prompt generation functions for review orchestrator
#
# Exports:
#   inject_reference_file()
#   emit_prior_findings_context()
#   inject_pre_check_findings()
#   emit_exhaustiveness_instructions()
#   make_design_prompt()
#   make_plan_prompt()
#   make_code_impl_prompt()

inject_reference_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    cat "$path"
  fi
}

inject_pre_check_findings() {
  local findings_file="$1"
  if [[ ! -f "$findings_file" ]]; then
    return
  fi

  local finding_count
  finding_count="$(jq '.findings | length' "$findings_file" 2>/dev/null || echo 0)"

  cat <<'PRECHECK_HEADER'

## Static Analysis Results (confirmed, not suggestions)
PRECHECK_HEADER

  if [[ "$finding_count" -eq 0 ]]; then
    printf 'No issues found by static analysis.\n'
    return
  fi

  jq -r '.findings[] | "- [\(.source)] \(.file):\(.line) - \(.message)"' "$findings_file" 2>/dev/null || printf 'No issues found by static analysis.\n'
}

emit_exhaustiveness_instructions() {
  if [[ "$DEPTH" == "thorough" ]]; then
    cat <<'EXHAUST'

IMPORTANT — Exhaustive single-pass review:
You MUST surface ALL Critical and Important issues in this single pass.
Do not hold back findings for subsequent review rounds.
A thorough single-pass review is far more valuable than multiple shallow passes.
If you are uncertain whether something is an issue, include it with the appropriate confidence level.
Err on the side of reporting more issues rather than fewer.
EXHAUST
  else
    cat <<'QUICK'

Focus on Critical issues only. Skip Important and Minor issues.
QUICK
  fi
}

emit_prior_findings_context() {
  if [[ -z "$PRIOR_FINDINGS_PATH" ]]; then
    return
  fi
  local count
  count="$(jq 'length' "$PRIOR_FINDINGS_PATH")"
  if [[ "$count" -eq 0 ]]; then
    return
  fi
  local findings_summary
  findings_summary="$(jq -r '.[] | "- [\(.severity)] \(.location): \(.evidence[0:120])"' "$PRIOR_FINDINGS_PATH")"
  cat <<PRIOR

CONTEXT — Previous review round found ${count} blocking issue(s) addressed by host:
${findings_summary}
Do NOT re-report fixed issues. Verify fixes are adequate and find new issues.
PRIOR
}

make_design_prompt() {
  local prompt_file="$1"
  local workspace_design="$2"
  local skill_refs="$SKILLS_DIR/review-design/references"
  {
    cat <<EOF2
## Role
You are the enforced reviewer CLI for a cross-tool design review. Review adversarially and exhaustively.

## Concern Lenses — Evaluate ALL THREE
You must address all three lenses. Set the "lens" field to all lenses evaluated (comma-separated).
1. Goals and scope — stated objectives, success criteria, out-of-scope boundaries, acceptance conditions
2. Architecture and boundaries — component ownership, service boundaries, data flow, dependency direction, coupling
3. Risks and operability — rollout reversibility, failure modes, observability, operational runbook gaps

## Severity Calibration
EOF2
    inject_reference_file "$skill_refs/severity-guide.md"
    cat <<'EOF2'

## Example: Well-Formed Finding
EOF2
    inject_reference_file "$skill_refs/good-finding-example.md"
    cat <<'EOF2'

## Anti-Pattern: Do NOT Produce This
EOF2
    inject_reference_file "$skill_refs/bad-finding-example.md"
    cat <<EOF2

## Evidence Standard
- location: specific section heading or paragraph reference, never "various"
- evidence: quoted or closely paraphrased text from the design, never a general assertion
- fix: a concrete, actionable design decision, never "consider improving"
- confidence: high (direct evidence), medium (reasonable inference), low (speculation)
EOF2
    inject_pre_check_findings "$PRE_CHECK_FINDINGS"
    cat <<EOF2

Only inspect the design file and any root context files in this isolated workspace.
If the design mentions repo paths not present here, treat them as out-of-scope references.

Review the design at "$workspace_design".
EOF2
    emit_prior_findings_context
    emit_exhaustiveness_instructions
    cat <<'EOF2'

Return JSON only matching this shape exactly:
{
  "lens": string,
  "verdict": "PASS" | "FAIL",
  "summary": string,
  "findings": [
    {
      "severity": "Critical" | "Important" | "Minor",
      "location": string,
      "evidence": string,
      "impact": string,
      "fix": string,
      "confidence": "high" | "medium" | "low"
    }
  ],
  "pass_rationale": string
}
Populate every finding with evidence, impact, fix, and confidence.
Only mark FAIL for issues explicitly present in the design as written.
Do not mark FAIL for hypothetical misuse by an external orchestrator that is not described here.
If there are no Critical or Important issues, return PASS and a non-empty pass_rationale.
EOF2
  } > "$prompt_file"
}

make_plan_prompt() {
  local prompt_file="$1"
  local workspace_plan="$2"
  local skill_refs="$SKILLS_DIR/review-plan/references"
  {
    cat <<'EOF2'
## Role
You are the enforced reviewer CLI for a cross-tool plan review. Review adversarially and exhaustively.

## Concern Lenses — Evaluate ALL THREE
You must address all three lenses. Set the "lens" field to all lenses evaluated (comma-separated).
1. Requirements and risk — missing scope, unclear success criteria, rollout/rollback, operational risk
2. Architecture and dependencies — layering, ownership, sequencing, coupling, dependency ordering
3. Test strategy and operations — test pyramid fit, acceptance criteria, observability, deployment/verification

## Severity Calibration
EOF2
    inject_reference_file "$skill_refs/severity-guide.md"
    cat <<'EOF2'

## Example: Well-Formed Finding
EOF2
    inject_reference_file "$skill_refs/good-finding-example.md"
    cat <<'EOF2'

## Anti-Pattern: Do NOT Produce This
EOF2
    inject_reference_file "$skill_refs/bad-finding-example.md"
    cat <<EOF2

## Evidence Standard
- location: specific section heading or paragraph reference, never "various"
- evidence: quoted or closely paraphrased text from the plan, never a general assertion
- fix: a concrete, actionable change, never "consider improving"
- confidence: high (direct evidence), medium (reasonable inference), low (speculation)
EOF2
    inject_pre_check_findings "$PRE_CHECK_FINDINGS"
    cat <<EOF2

Only inspect the plan file and any root context files in this isolated workspace.
If the plan mentions repo paths not present here, treat them as out-of-scope references.

Review the plan at "$workspace_plan".
EOF2
    emit_prior_findings_context
    emit_exhaustiveness_instructions
    cat <<'EOF2'

Return JSON only matching this shape exactly:
{
  "lens": string,
  "verdict": "PASS" | "FAIL",
  "summary": string,
  "findings": [
    {
      "severity": "Critical" | "Important" | "Minor",
      "location": string,
      "evidence": string,
      "impact": string,
      "fix": string,
      "confidence": "high" | "medium" | "low"
    }
  ],
  "pass_rationale": string
}
Populate every finding with evidence, impact, fix, and confidence.
Only mark FAIL for issues explicitly present in the plan as written.
Do not mark FAIL for hypothetical misuse by an external orchestrator that is not described here.
If there are no Critical or Important issues, return PASS and a non-empty pass_rationale.
EOF2
  } > "$prompt_file"
}

make_code_impl_prompt() {
  local prompt_file="$1"
  shift
  local files=("$@")
  local skill_refs="$SKILLS_DIR/review-code-impl/references"
  {
    cat <<'EOF2'
## Role
You are the enforced reviewer CLI for a cross-tool code implementation review. Review adversarially and exhaustively.

## Concern Lenses — Evaluate ALL THREE
You must address all three lenses. Set the "lens" field to all lenses evaluated (comma-separated).
1. Security and correctness — injection, auth bypass, secret exposure, nil/panic, data loss, logic errors
2. Testing and spec compliance — required test coverage, spec baseline adherence, missing behavior tests
3. Production readiness — error observability, structured logging, health signals, race conditions, resource leaks

## Severity Calibration
EOF2
    inject_reference_file "$skill_refs/severity-guide.md"
    cat <<'EOF2'

## Example: Well-Formed Finding
EOF2
    inject_reference_file "$skill_refs/good-finding-example.md"
    cat <<'EOF2'

## Anti-Pattern: Do NOT Produce This
EOF2
    inject_reference_file "$skill_refs/bad-finding-example.md"
    cat <<'EOF2'

## Evidence Standard
- location: file:line reference, never a package name or "various"
- evidence: quoted or closely paraphrased code from the file, never a general assertion
- fix: a concrete, actionable code change naming the specific function or expression
- confidence: high (direct evidence), medium (reasonable inference), low (speculation)
EOF2
    inject_pre_check_findings "$PRE_CHECK_FINDINGS"
    cat <<'EOF2'

Only inspect the files listed below and any root context files in this isolated workspace.
If those files mention repo paths not present here, treat them as out-of-scope references.
Do not treat fixed literal example paths or placeholder prompt text as untrusted input interpolation.

Review these files:
EOF2
    printf -- '- %s\n' "${files[@]}"
    if [[ -n "$WORKSPACE_PLAN_PATH" ]]; then
      printf 'Use "%s" as the spec baseline when checking implementation compliance.\n' "$WORKSPACE_PLAN_PATH"
    fi
    emit_prior_findings_context
    emit_exhaustiveness_instructions
    cat <<'EOF2'

Return JSON only matching this shape exactly:
{
  "lens": string,
  "verdict": "PASS" | "FAIL",
  "summary": string,
  "findings": [
    {
      "severity": "Critical" | "Important" | "Minor",
      "location": string,
      "evidence": string,
      "impact": string,
      "fix": string,
      "confidence": "high" | "medium" | "low"
    }
  ],
  "pass_rationale": string
}
Populate every finding with evidence, impact, fix, and confidence.
Only mark FAIL for issues explicitly present in the reviewed files as written.
Do not mark FAIL for hypothetical misuse by an external orchestrator that is not described here.
If there are no Critical or Important issues, return PASS and a non-empty pass_rationale.
EOF2
  } > "$prompt_file"
}
