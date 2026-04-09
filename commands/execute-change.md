---
description: Top-level sovereign harness execution runner with approved-plan validation, serial-first implementation, review, verification, and rollback control
argument-hint: "[--plan <path>] [--reviewer <codex|claude|gemini>] [--depth <thorough|quick>] [--max-rounds <n>] <approved plan path>"
allowed-tools: ["Agent", "Read", "Glob", "Grep", "Bash", "Edit", "MultiEdit"]
---

Run the sovereign harness execution entry with explicit approved-plan validation, serial-first implementation, task-ledger-driven progress, mandatory review, mandatory verification, and deterministic post-execution state.

This command is the command-surface wrapper for `coding:execute-change`.

Parse the following from `$ARGUMENTS`:
- `--plan <path>`: required approved plan input unless provided as one bare path-like token
- `--reviewer <name>`: optional reviewer driver for downstream implementation review
- `--depth <thorough|quick>`: optional review depth for downstream implementation review
- `--max-rounds <n>`: optional downstream review/autofix cap. Must satisfy `1 <= n <= 3`
- one bare path-like token may be consumed as `--plan`

If no plan path can be resolved, stop and redirect the caller to `coding:plan-change`.

Step 1 — Resolve runner paths yourself with Bash:
```bash
RUNNER=""
REVIEW_RUNNER=""
REVIEW_GATE=""
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/execute-runner.sh" ]]; then
  RUNNER="$(realpath "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/execute-runner.sh")"
fi
if [[ -z "${RUNNER:-}" ]]; then
  RUNNER="$(find ~/.claude/plugins -path '*/skills/_harness-libs/execute-runner.sh' -print -quit 2>/dev/null)"
  [[ -n "${RUNNER:-}" ]] && RUNNER="$(realpath "$RUNNER")"
  [[ -f "${RUNNER:-}" ]] || RUNNER=""
fi

if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/review-runner.sh" ]]; then
  REVIEW_RUNNER="$(realpath "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/review-runner.sh")"
fi
if [[ -z "${REVIEW_RUNNER:-}" ]]; then
  REVIEW_RUNNER="$(find ~/.claude/plugins -path '*/skills/_harness-libs/review-runner.sh' -print -quit 2>/dev/null)"
  [[ -n "${REVIEW_RUNNER:-}" ]] && REVIEW_RUNNER="$(realpath "$REVIEW_RUNNER")"
  [[ -f "${REVIEW_RUNNER:-}" ]] || REVIEW_RUNNER=""
fi

if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/review-gate.sh" ]]; then
  REVIEW_GATE="$(realpath "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/review-gate.sh")"
fi
if [[ -z "${REVIEW_GATE:-}" ]]; then
  REVIEW_GATE="$(find ~/.claude/plugins -path '*/skills/_harness-libs/review-gate.sh' -print -quit 2>/dev/null)"
  [[ -n "${REVIEW_GATE:-}" ]] && REVIEW_GATE="$(realpath "$REVIEW_GATE")"
  [[ -f "${REVIEW_GATE:-}" ]] || REVIEW_GATE=""
fi

printf 'RUNNER=%s\nREVIEW_RUNNER=%s\nREVIEW_GATE=%s\n' "$RUNNER" "$REVIEW_RUNNER" "$REVIEW_GATE"
```
If any required runner is empty, stop and report the missing path.

Step 2 — Resolve and validate the approved plan first:
- Resolve the final plan path to an absolute path under the repository root.
- Record the entry phase with:
```bash
bash "$RUNNER" entry-phase
```
- Validate the plan for execution with:
```bash
bash "$RUNNER" validate "<resolved_plan>"
```
- Read the approved plan state with:
```bash
bash "$RUNNER" approval-status "<resolved_plan>"
```
- The approval status must be exactly `approved`.
- If the plan is invalid or approval status is not `approved`, stop before implementation starts.

Step 3 — Materialize the execution contract from the approved plan:
- Resolve the execution mode with:
```bash
bash "$RUNNER" mode "<resolved_plan>"
```
- Resolve the current workspace mode with:
```bash
bash "$RUNNER" workspace-mode
```
- Resolve whether a one-time worktree preflight reminder is required with:
```bash
bash "$RUNNER" worktree-preflight-required "<workspace_mode>" "false"
```
- If the result is `true`, remind the user once that isolated worktree development is available through the existing `git-worktrees` workflow before the first code mutation.
- If the user declines, record that decision for this run and do not ask again mid-plan.
- Materialize the task catalog with:
```bash
bash "$RUNNER" task-catalog "<resolved_plan>"
```
- Materialize the initial task-ledger with:
```bash
bash "$RUNNER" task-ledger "<resolved_plan>"
```
- Resolve the allowed touch set with:
```bash
bash "$RUNNER" allowed-touch-set "<resolved_plan>"
```
- Resolve the verification commands with:
```bash
bash "$RUNNER" verification-commands "<resolved_plan>"
```
- These commands come from the approved plan `verification_scope`.
- Resolve whether truth sync is required after verification with:
```bash
bash "$RUNNER" truth-sync-required "<resolved_plan>"
```
- Unless the plan explicitly resolves to `parallel-approved`, execution mode stays `implement-serial` / `serial-first`.

Step 4 — Execute the approved plan under serial-first control:
- Treat the approved plan as the atomic execution unit.
- Execute ready tasks in approved dependency order. Do not reorder the approved task graph.
- Use the task ledger rather than chat memory to track the active task, completed tasks, and remaining tasks.
- Before each task starts, report progress in a concise machine-readable shape such as:
  - `current_task`
  - `completed_task_count`
  - `remaining_task_count`
  - `workspace_mode`
- Use TDD for code changes: write a failing test or equivalent narrow reproducer first, then implement the minimal fix, then rerun the narrow verification before moving on.
- Keep edits inside the approved `allowed_touch_set` unless you intentionally stop for rollback or re-planning.
- Do not silently expand scope beyond the approved plan.
- If a task requires files outside the allowed touch set, stop and treat that as a rollback or re-plan condition instead of continuing.
- After each task implementation slice, run task-scoped verification first, then route task-scoped review through `coding:review-change`.
- Default task review depth is `quick`.
- Escalate task review depth to `thorough` for higher-risk tasks such as command-surface changes, schema or migration changes, security-sensitive paths, or tasks that already failed one quick review round.
- Readonly review may widen inside the current plan-bound review surface, but automatic fixes still remain bounded by `allowed_touch_set`.
- If a ready task remains and no machine-checkable gate requires a stop, continue automatically. Do NOT ask whether to continue mid-plan.
- If repeated failures occur, compute the rollback target with:
```bash
bash "$RUNNER" rollback-target "<failure_kind>" "<failure_count>"
```
- Rollback target resolution is the authoritative rollback target for this entry.

Step 5 — Converge the implementation into one reviewable state:
- After plan execution, collect changed files with:
```bash
git diff --name-only --diff-filter=ACMR
```
- If no changed files remain, stop and report that execution produced no reviewable implementation delta.
- For review, pass the resolved plan and the changed files to the top-level `coding:review-change` gate through `skills/_harness-libs/review-gate.sh`.

Step 6 — Run mandatory implementation review in an isolated subagent:
- Build a bash argv array. Do not splice caller-derived text directly into the shell command.
- Use this exact subagent prompt shape:

---
You are a script runner. Run ONE bash command and report the results. Do NOT review code yourself. Do NOT read files. Do NOT construct codex/claude/gemini commands yourself.

Run:
```bash
json_file="$(mktemp)"
stderr_file="$(mktemp)"
args=(bash {REVIEW_GATE} run code-impl claude --plan "{resolved_plan}")
```

Add one argv line per changed file:
- `args+=(--file "{changed_file}")`

Add optional argv lines when present:
- `args+=(--reviewer "{reviewer}")`
- `args+=(--depth "{depth}")`
- `args+=(--max-rounds "{max_rounds}")`

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

If `EXIT_CODE=10`, retry once with `args+=(--allow-same-model-fallback)`.
If the final exit code is non-zero, report stderr and stop.
Otherwise, return stdout/stderr verbatim.
---

Step 7 — Validate the review output and derive the implementation review verdict:
- Extract the JSON between `JSON_BEGIN` and `JSON_END`
- Validate it with:
```bash
bash "$REVIEW_RUNNER" validate-output "$json_file"
```
- Build the normalized implementation review gate result with:
```bash
review_gate_json="$(bash "$REVIEW_RUNNER" gate-result code-impl "$json_file")"
```
- If the normalized review verdict is not `pass`, stop immediately and report the blocking findings plus the rollback target for `review-blocking-failure`

Step 8 — Run mandatory verification from the approved plan:
- Run every command produced by:
```bash
bash "$RUNNER" verification-commands "<resolved_plan>"
```
- Run verification exactly as declared in `verification_scope`; do not replace it with a prose summary.
- Verification status is `pass` only if every command succeeds.
- If any verification command fails, set verification status to `needs-rollback` and compute the authoritative rollback target for `verification-failure`.

Step 9 — Normalize review and verification with the evaluation gate:
- Use the shared evaluation-gate via:
```bash
bash "$RUNNER" gate-result "<review_status>" "<verify_status>" "<truth_sync_required>" "false"
```
- This is the `build_evaluation_verdict` / evaluation-gate normalization step.
- Report the resulting JSON as the execution verdict for this top-level entry.

Step 10 — Deterministic post-execution state:
- If the execution verdict is `needs-rollback`, stop and report the rollback target from:
```bash
bash "$RUNNER" rollback-target "<failure_kind>" "<failure_count>"
```
- If the execution verdict is `needs-fixes`, stop and report the failing review or verification gate
- If the execution verdict is `pass` and `ready_for_close == false`, the next entry is `coding:sync-truth`
- If the execution verdict is `pass` and `ready_for_close == true`, the next entry is `coding:close-change`
- If the review gate or verification gate already determines the next state, that machine-checkable gate is authoritative
- Do NOT ask whether to continue when the machine-checkable gate already determines the next state
