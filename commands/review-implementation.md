---
description: Same-model implementation review through the shared review runner in an isolated subagent
argument-hint: "[--depth <thorough|quick>] [--timeout <seconds>] [--plan <path>] [--file <path> ...] [--branch <name>] [--batch <n>] [--round <n>] [--max-rounds <n>]"
allowed-tools: ["Agent", "Bash", "Read", "Glob", "Grep"]
---

Run same-model code implementation review through the shared review runner in an isolated subagent.
This command is review-only. It returns evidence and structured control metadata but never edits implementation or owns lifecycle continuation.
Default timeout: `1800` seconds per reviewer invocation.
Default depth: `thorough` (surfaces all Critical/Important/Minor issues exhaustively).
Artifact-DAG fence: use `--plan` for bounded code review. The shared runner resolves the plan's upstream design via `design_ref`, reviews in `design -> plan -> code` order, and derives `.scope.allowed_touch_set` from `plan.impl_file_refs + plan.test_file_refs`.

Use `--plan <path>` to point at the implementation plan that defines the initial review constraint for the code implementation.

Parse the following from $ARGUMENTS (flags may appear in any order):
- `--depth <thorough|quick>`: review depth. `thorough` (default) surfaces all issues exhaustively; `quick` focuses on Critical only. If omitted, omit the flag.
- `--timeout <seconds>`: optional reviewer timeout. If omitted, default to `1800`. Use this same value for the outer Bash tool invocation and the inner `bash ... --timeout` runner call.
- `--plan <path>`: optional implementation plan baseline. For artifact-DAG fenced review, this is the expected path: `design_ref is required`, the upstream design is loaded first, and bounded repair uses `.scope.allowed_touch_set`.
- `--file <path>`: optional explicit code implementation scope file. Repeatable.
- `--branch <name>`: optional git worktree branch name. Resolves to the worktree path for that branch. Mutually exclusive with direct repo-root specification.
- `--batch <n>`: optional caller-owned review batch metadata. If omitted, omit the flag.
- `--round <n>`: optional caller-owned review round metadata. If omitted, omit the flag.
- `--max-rounds <n>`: optional caller-owned round metadata. Must be `<= 10`. If omitted, omit the flag. Default is the hard limit `10`; expected convergence is `5`.

Bare-path inference: if `$ARGUMENTS` contains a path-like token (contains `/` or ends with `.md`) that is not preceded by a recognized flag, treat it as the `--plan` value. Strip a leading `@` from any path token (Claude Code file-picker prefix).

Validate the parsed control flags before spawning the subagent:
- require integers for `--batch`, `--round`, and `--max-rounds` when they are present
- require a positive integer for `--timeout` when it is present
- require `batch >= 1`
- require `round >= 1`
- require `1 <= max-rounds <= 10`
- reject `round > max-rounds` when both are present
- reject any token in `$ARGUMENTS` that is neither a recognized flag, a flag value, nor a bare path consumed by inference

Step 1 — Resolve the shared runner path (run this Bash command yourself, do NOT delegate):
```
SCRIPT=""
# Tier 1: framework-injected variable
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/skills/_review-libs/run-review.sh" ]]; then
  SCRIPT="$(realpath "${CLAUDE_PLUGIN_ROOT}/skills/_review-libs/run-review.sh")"
fi
# Tier 2: find under standard plugin directory (no hardcoded org/plugin names)
if [[ -z "${SCRIPT:-}" ]]; then
  SCRIPT="$(find ~/.claude/plugins -path '*/skills/_review-libs/run-review.sh' -print -quit 2>/dev/null)"
  [[ -n "${SCRIPT:-}" ]] && SCRIPT="$(realpath "$SCRIPT")"
  [[ -f "${SCRIPT:-}" ]] || SCRIPT=""
fi
echo "SCRIPT=$SCRIPT"
```
If SCRIPT is empty, report "review script not found" and stop.

Step 1.5 — Pre-validate inputs (run these Bash commands yourself, do NOT delegate):

Resolve all path arguments to absolute paths before spawning the subagent:

a) If `--branch` was parsed, verify the worktree exists:
   Run: `git worktree list --porcelain | awk -v branch="refs/heads/{branch}" '/^worktree / { wt = substr($0, 10) } $0 == "branch " branch { print wt; exit }'`
   If output is empty → stop with "no worktree found for branch: {branch}".
   Record the output as `{resolved_worktree}`.

b) If `--plan` was parsed, resolve to absolute path:
   Try in order: `realpath "{plan_path}"`, then `realpath "{resolved_worktree}/{plan_path}"` (if --branch was used).
   If neither resolves to an existing file → stop with "plan file not found: {plan_path}".
   Record the resolved path as `{resolved_plan}`. Use this in Step 2 instead of the original path.
   For artifact-DAG fenced review, the shared runner then requires `## Upstream Design` with `design_ref` and `design_version`, loads the upstream design first, and fails fast if that linkage cannot be resolved.

c) If `--file` was parsed (repeatable), resolve each to absolute path via `realpath`. If any doesn't exist → stop.
   If a plan baseline is present, the shared runner later filters these files to `.scope.allowed_touch_set`.

Use the resolved absolute paths (not the original arguments) in all subsequent steps.

Step 2 — Spawn the subagent using the Agent tool with this exact prompt (replace `{SCRIPT}` with the resolved absolute path and `{flag_lines}` with zero or more validated `args+=(...)` lines derived from the script-passthrough flags, using pre-validated absolute paths from Step 1.5):

Script-passthrough flags (include in `{flag_lines}` when present):
- `--depth <thorough|quick>`
- `--timeout <seconds>`
- `--plan <path>` (use resolved absolute path from Step 1.5)
- `--file <path>` (repeatable, use resolved absolute paths from Step 1.5)
- `--branch <name>`
- `--batch <n>`
- `--round <n>`
- `--max-rounds <n>`
- `--prior-findings <path>` (generated by repair loop, not user-facing)

---

You are a script runner. Run ONE bash command and report the results. Do NOT review code yourself. Do NOT read any files. Do NOT construct reviewer commands yourself.
Use the same timeout budget for the Bash tool invocation and the inner runner command. Set `timeout_seconds` to the validated caller value or `1800` when omitted.

Run:
```
json_file="$(mktemp)"
stderr_file="$(mktemp)"
timeout_seconds="{timeout_seconds}"
args=(bash {SCRIPT} --mode code-impl --host claude)
{flag_lines}
args+=(--timeout "$timeout_seconds")
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

Build `args` as an argv array. Do not splice caller-derived text directly into the shell command.

Invoke the Bash tool for this command with timeout `timeout_seconds` seconds.

If EXIT_CODE is non-zero, report the full error output and stop.

Otherwise, report the complete stdout and stderr output verbatim.

---

Step 3 — Format the result yourself (do NOT delegate):
Extract the JSON between `JSON_BEGIN` and `JSON_END`. Extract stderr only from the `STDERR_BEGIN`/`STDERR_END` block.

Before reporting anything, validate the JSON with jq. Require:
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
- `.result.lens`
- `.result.summary`
- `.result.verdict`
- `.result.findings`

Validation rules:
- Treat scalar control fields as required and non-empty.
- Treat `.blocking_findings` as required and typed, but allow it to be `[]` when `.result.verdict == "PASS"`.
- If `.result.verdict == "FAIL"`, require `.blocking_findings` to contain the Critical/Important issues you will report.
- If `.result.verdict == "PASS"`, require `.result.pass_rationale` to be non-empty.
- For every Critical/Important item you surface from `.blocking_findings`, require `location`, `evidence`, `impact`, `fix`, and `confidence`.

If validation fails, stop and report reviewer-output validation failure instead of surfacing the result.

Parse the JSON with jq (via Bash). Report:
- Review mode: `.review_mode`
- Reviewer driver: `.reviewer`
- Reviewer model: `.reviewer_model`
- Status: `.status`
- Next action: `.next_action`
- Manual intervention required: `.manual_intervention_required`
- Review batch: `.batch`
- Review round: `.round/.max_rounds`
- Suggested next batch: `.suggested_next_batch`
- Suggested next round: `.suggested_next_round`
- Final verdict: `.result.verdict`
- Allowed touch set: `.scope.allowed_touch_set`
- Out-of-scope touched files: `.scope.out_of_scope_touched_files`
- If FAIL: list `.blocking_findings[]`
- If PASS: `.result.pass_rationale`

Step 4 — Return Control Metadata:
- Stop after reporting the validated result.
- Do not edit code, rerun yourself, invoke `coding:review-change`, or invoke `coding:implement-change`.
- If `.status == "needs_fixes"`, return the complete `.blocking_findings` and `.suggested_next_round` to the caller.
- If `.status == "manual_review_required"`, return the unresolved findings and scope classes so the lifecycle controller can select replan, redesign, authority, external verification, or rollback.
- When invoked inside `coding:implement-change`, that controller owns finding classification, batched repair, verification, prior-findings persistence, and the decision to request a fresh review.
