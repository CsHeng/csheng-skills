---
description: Top-level sovereign harness planning runner with mandatory artifact validation, review, and human approval gate
argument-hint: "[--design <path>] [--plan <path>] [--cross-model|--adversarial] [--reviewer <codex|claude|gemini>] [--depth <thorough|quick>] [--max-rounds <n>] <approved design path>"
allowed-tools: ["Agent", "Bash", "Read", "Edit", "MultiEdit", "Glob", "Grep"]
---

Run the sovereign harness planning entry with mandatory upstream-design validation, plan validation, plan review, and explicit human approval before execution.

This command is the command-surface wrapper for `coding:plan-change`.

Parse the following from `$ARGUMENTS`:
- `--design <path>`: required design artifact input unless provided as a bare path-like token
- `--plan <path>`: optional output plan path override
- `--cross-model`: optional review strategy override. Use only when the user explicitly asks for cross-model review.
- `--adversarial`: optional review strategy override alias for `--cross-model`.
- `--reviewer <name>`: optional reviewer driver passed through to the shared review runner. A reviewer different from the host requires `--cross-model` or `--adversarial`.
- `--depth <thorough|quick>`: optional review depth passed through to the shared review runner
- `--max-rounds <n>`: optional review/autofix cap. Default `3`, must be `1 <= n <= 3`
- one bare path-like token may be consumed as `--design` if `--design` was omitted

If no design artifact path can be resolved, stop and redirect the caller to `coding:design-change`. Do not build a plan directly from loose request prose.

Step 1 — Resolve runner paths yourself with Bash:
```bash
RUNNER=""
DESIGN_RUNNER=""
REVIEW_GATE=""
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/plan-runner.sh" ]]; then
  RUNNER="$(realpath "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/plan-runner.sh")"
fi
if [[ -z "${RUNNER:-}" ]]; then
  RUNNER="$(find ~/.claude/plugins -path '*/skills/_harness-libs/plan-runner.sh' -print -quit 2>/dev/null)"
  [[ -n "${RUNNER:-}" ]] && RUNNER="$(realpath "$RUNNER")"
  [[ -f "${RUNNER:-}" ]] || RUNNER=""
fi

if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/design-runner.sh" ]]; then
  DESIGN_RUNNER="$(realpath "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/design-runner.sh")"
fi
if [[ -z "${DESIGN_RUNNER:-}" ]]; then
  DESIGN_RUNNER="$(find ~/.claude/plugins -path '*/skills/_harness-libs/design-runner.sh' -print -quit 2>/dev/null)"
  [[ -n "${DESIGN_RUNNER:-}" ]] && DESIGN_RUNNER="$(realpath "$DESIGN_RUNNER")"
  [[ -f "${DESIGN_RUNNER:-}" ]] || DESIGN_RUNNER=""
fi

if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/review-gate.sh" ]]; then
  REVIEW_GATE="$(realpath "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/review-gate.sh")"
fi
if [[ -z "${REVIEW_GATE:-}" ]]; then
  REVIEW_GATE="$(find ~/.claude/plugins -path '*/skills/_harness-libs/review-gate.sh' -print -quit 2>/dev/null)"
  [[ -n "${REVIEW_GATE:-}" ]] && REVIEW_GATE="$(realpath "$REVIEW_GATE")"
  [[ -f "${REVIEW_GATE:-}" ]] || REVIEW_GATE=""
fi

printf 'RUNNER=%s\nDESIGN_RUNNER=%s\nREVIEW_GATE=%s\n' "$RUNNER" "$DESIGN_RUNNER" "$REVIEW_GATE"
```
If any required path is empty, stop and report the missing runner.

Step 2 — Resolve and validate the upstream design first:
- Resolve the design path to an absolute path under the repository root
- The design file must already exist
- Validate it before drafting the plan:
```bash
bash "$DESIGN_RUNNER" validate "<resolved_design>"
```
- Read the approval state with:
```bash
bash "$DESIGN_RUNNER" approval-status "<resolved_design>"
```
- If the design artifact is invalid, stop
- If the resolved approval status is not exactly `approved`, stop and ask for explicit human approval instead of drafting the plan

Step 3 — Resolve the plan output path and entry phase:
- Compute the plan entry phase with:
```bash
bash "$RUNNER" entry-phase
```
- If no plan path was provided, derive it from the upstream design with:
```bash
bash "$RUNNER" default-path "<resolved_design>"
```
- Resolve the final plan path to an absolute path under the repository root. If the file does not exist yet, create parent directories as needed.

Step 4 — Draft or update the plan artifact:
- The plan file must include these sections exactly:
  - `## Upstream Design`
  - `## Implementation Scope`
  - `## Review Gate`
  - `## Human Gate`
  - at least one `## Task N:`
  - `## Rollback`
- In `## Upstream Design`, record:
  - `design_ref`
  - `design_version`
- In `## Implementation Scope`, record:
  - `impl_file_refs`
  - `test_file_refs`
  - `verification_scope`
- In `## Review Gate`, record at least:
  - `required_entry: review-change`
- In `## Human Gate`, record at least:
  - `approval_required: true`
  - `approval_status: pending`
  - `next_entry: execute-change`
- In `## Rollback`, record the failure or escalation path back to `design-change` or another earlier phase when appropriate
- The plan must name ordered tasks, dependencies, verification commands, and rollback triggers. Do not accept a prose-only status summary as a valid plan artifact.

Step 5 — Validate the drafted plan artifact before review:
```bash
bash "$RUNNER" validate "<resolved_plan>"
```
This is the `skills/_harness-libs/plan-runner.sh validate` gate.
If validation fails, fix the artifact first. Do not proceed to review with an invalid plan file.

Step 6 — Run mandatory plan review in an isolated subagent:
- Route review through the top-level `coding:review-change` gate; the subagent below must use `skills/_harness-libs/review-gate.sh`, not call `_review-libs/run-review.sh` directly.
- Build a bash argv array. Do not splice caller-derived text directly into the shell command.
- Use this exact subagent prompt shape:

---
You are a script runner. Run ONE bash command and report the results. Do NOT review plans yourself. Do NOT read any files. Do NOT construct codex/claude/gemini commands yourself.

Run:
```bash
json_file="$(mktemp)"
stderr_file="$(mktemp)"
args=(bash {REVIEW_GATE} run plan claude "{resolved_plan}")
```

Add optional argv lines when present:
- `args+=(--cross-model)`
- `args+=(--adversarial)`
- `args+=(--reviewer "{reviewer}")`
- `args+=(--depth "{depth}")`

Then run:
```bash
"${args[@]}" >"$json_file" 2>"$stderr_file"
exit_code=$?
printf 'EXIT_CODE=%s\n' "$exit_code"
printf 'STDERR_BEGIN\n'
cat "$stderr_file"
printf 'STDERR_END\n'
printf 'JSON_BEGIN\n'
cat "$json_file"
printf '\nJSON_END\n'
```

If `EXIT_CODE=10` and cross/adversarial mode was requested, retry once with `args+=(--allow-same-model-fallback)`.
If the final exit code is non-zero, report stderr and stop.
Otherwise, return stdout/stderr verbatim.
---

Step 7 — Validate the review output yourself:
- Extract the JSON between `JSON_BEGIN` and `JSON_END`
- Require with `jq`:
  - `.review_mode`
  - `.reviewer`
  - `.reviewer_model`
  - `.status`
  - `.next_action`
  - `.manual_intervention_required`
  - `.batch`
  - `.round`
  - `.max_rounds`
  - `.suggested_next_batch`
  - `.suggested_next_round`
  - `.blocking_findings`
  - `.result.verdict`
- If validation fails, stop and report reviewer-output validation failure

Step 8 — Mandatory bounded autofix loop:
- Review is mandatory for this harness entry; do not stop after writing the plan
- If review returns PASS, continue to Step 9
- If review returns FAIL and every blocking finding is `scope_class: in_scope_blocking`, fix only those findings in the current plan artifact, rerun `bash "$RUNNER" validate "<resolved_plan>"`, then rerun Step 6
- Default max rounds is `3` unless `--max-rounds` supplied
- If a rerun would exceed `max-rounds`, stop and report the unresolved findings with `suggested_next_round`
- If any blocking finding is out-of-scope or `manual_intervention_required=true`, stop and report the findings without further autofix

Step 9 — Human approval gate:
- After the plan artifact validates and the mandatory review loop reaches PASS, stop and ask for explicit human approval
- Keep `approval_status: pending` until the human explicitly approves the plan
- Only after explicit approval may the artifact move to `approval_status: approved`
- Report:
  - resolved design path
  - resolved plan path
  - reviewer driver/model
  - final review verdict
  - recommended next entry: `coding:execute-change`
- Do NOT start execution automatically
- Do NOT respond as if planning is complete just because the file was updated
- Do NOT ask whether to continue; report that the harness is stopped at the explicit human approval gate until `approval_status` becomes `approved`
