---
description: Top-level sovereign harness planning runner with mandatory artifact validation, review, and human approval gate
argument-hint: "[--design <path>] [--plan <path>] [--depth <thorough|quick>] [--max-rounds <n>] <approved design path>"
allowed-tools: ["Agent", "Bash", "Read", "Edit", "MultiEdit", "Glob", "Grep"]
---

Run the sovereign harness planning entry with mandatory upstream-design validation, plan validation, plan review, and explicit human approval before execution.

This command is the command-surface wrapper for `coding:plan-change`.

Parse the following from `$ARGUMENTS`:
- `--design <path>`: required design artifact input unless provided as a bare path-like token
- `--plan <path>`: optional output plan path override
- `--depth <auto|boundary|thorough|quick>`: optional review depth passed through to the shared review runner
- `--max-rounds <n>`: optional review/autofix cap. Default follows the shared runner, must be `1 <= n <= 3`
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
  - `## Work Package Readiness`
  - `## Execution Continuity`
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
- In `## Work Package Readiness`, record:
  - `milestone_objective`
  - `non_goals`
  - `future_phase`
  - `decision_status: ready_for_review|needs_design_decision|split_scope|manual_checkpoint`
  - `oracle_strategy`
  - `acceptance_oracles`
  - `execution_continuity: continuous_after_plan_approval|pre_confirmation_required|not_ready`
  - `max_review_batches: 2` unless the design explicitly approves a smaller budget
  - `subagent_ready: true|false`
- If behavior, architecture, runtime semantics, security, compatibility, or long-lived maintenance risk is non-trivial, choose `oracle_strategy` using `coding:executable-oracle-architecture-selector` before drafting task details.
- If `decision_status` is not `ready_for_review`, stop with that typed state. Do not broaden the plan to make it reviewable.
- In `## Execution Continuity`, record:
  - `execution_mode: continuous_after_plan_approval|pre_confirmation_required|not_ready`
  - `confirmation_clearance`: `C*` items for known human decisions, destructive writes, live cutovers, credential needs, or external dependencies
  - `runtime_contingencies`: `X*` items for execution-time surprises only, such as live-state drift, failed probes, missing credentials, verification failures, or rollback triggers
  - `planned_stop_points`: empty unless a known issue cannot be safely pre-confirmed during planning
  - `task_ordering_rationale`: why low-risk/no-confirmation tasks run before live/destructive/high-risk tasks, unless a risky task is a hard prerequisite
- Resolve known confirmations during planning whenever possible. Prefer `pre_confirmed` or `deferred_not_in_scope`; use `needs_confirmation_before_execution` only when the plan cannot safely pre-confirm the decision.
- Do not use `runtime_contingencies` for known human decisions. They are only reactive stop conditions for execution-time evidence.
- In `## Review Gate`, record at least:
  - `required_entry: review-change`
- In `## Human Gate`, record at least:
  - `approval_required: true`
  - `approval_status: pending`
  - `next_entry: execute-change`
- In `## Rollback`, record the failure or escalation path back to `design-change` or another earlier phase when appropriate
- The plan must name ordered tasks, dependencies, verification commands, and rollback triggers. Do not accept a prose-only status summary as a valid plan artifact.
- Task order should put low-risk, repo-local, reversible, no-confirmation tasks before high-risk, live, destructive, or external-dependency tasks unless the risky task is a hard prerequisite.
- Each behavior-changing task must point to an executable oracle or substitute verification evidence. Docs-only, exploratory, and manual-evidence-only tasks must say so explicitly.

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
You are a script runner. Run ONE bash command and report the results. Do NOT review plans yourself. Do NOT read any files. Do NOT construct reviewer commands yourself.

Run:
```bash
json_file="$(mktemp)"
stderr_file="$(mktemp)"
args=(bash {REVIEW_GATE} run plan claude "{resolved_plan}")
```

Add optional argv lines when present:
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
- Default max rounds follows the shared runner unless `--max-rounds` supplied
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
  - execution continuity status:
    - `C0`: no remaining confirmation needed; plan approval authorizes continuous execution
    - or `C1`, `C2`, ...: exact confirmations still needed before execution
    - `E1`, `E2`, ...: task ranges expected to run continuously
    - `X1`, `X2`, ...: runtime contingencies that stop execution only if observed evidence triggers them
  - recommended next entry: `coding:execute-change`
- Do NOT start execution automatically
- Do NOT respond as if planning is complete just because the file was updated
- Do NOT ask a generic whether to continue; either ask for plan approval with `C0` continuous execution stated, or ask the exact unresolved `C*` confirmation questions
- Do NOT leave the user guessing whether `execute-change` will run through the whole plan or stop on a known gate
