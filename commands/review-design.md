---
description: Same-model design review with optional cross/adversarial mode and repair-review loop through the shared review runner in an isolated subagent
argument-hint: "[--design] <path> [--repair-review] [--cross-model|--adversarial] [--reviewer <codex|claude|gemini>] [--depth <thorough|quick>] [--timeout <seconds>] [--branch <name>] [--batch <n>] [--round <n>] [--max-rounds <n>] [--approve-next-batch]"
allowed-tools: ["Agent", "Bash", "Read", "Edit", "MultiEdit", "Glob", "Grep"]
---

Run same-model design review through the shared review runner in an isolated subagent. Use `--cross-model` or `--adversarial` only when the user explicitly asks for cross/adversarial review.
Default behavior: `review-only`. Only enter the automatic fix-and-rerun loop when `--repair-review` is explicitly present.
Default reviewer model targets:
- `codex`: `gpt-5.4`
- `claude`: `claude-opus-4-6`
- `gemini`: `gemini-3.1-pro-preview`
Default timeout: `1800` seconds per reviewer invocation.
Default depth: `thorough` (surfaces all Critical/Important/Minor issues exhaustively).
Artifact-DAG baseline: design docs that feed plan/code review should declare `## Implementation Surface` with `impl_file_refs` and `test_file_refs`. Those refs are the source of truth for downstream plan/design linkage and bounded code repair.

Parse the following from $ARGUMENTS (flags may appear in any order):
- `--design <path>`: design document to review. Required.
- `--repair-review`: optional. If present, allow host-side fixes and reruns up to the bounded batch/round policy, but only when every blocking finding is `scope_class: in_scope_blocking`.
- `--cross-model`: optional. If present, use an opposite-driver reviewer.
- `--adversarial`: optional alias for `--cross-model`.
- `--reviewer <name>`: reviewer driver (codex, claude, gemini). If omitted, omit the flag. A reviewer different from the host requires `--cross-model` or `--adversarial`.
- `--depth <thorough|quick>`: review depth. `thorough` (default) surfaces all issues exhaustively; `quick` focuses on Critical only. If omitted, omit the flag.
- `--timeout <seconds>`: optional reviewer timeout. If omitted, default to `1800`. Use this same value for the outer Bash tool invocation and the inner `bash ... --timeout` runner call.
- `--branch <name>`: optional git worktree branch name. Resolves to the worktree path for that branch. Mutually exclusive with direct repo-root specification.
- `--batch <n>`: optional repair-review batch metadata. If omitted, omit the flag.
- `--round <n>`: optional repair-review round metadata. If omitted, omit the flag.
- `--max-rounds <n>`: optional tighter round cap. Must be `<= 3`. If omitted, omit the flag. Default is now `3`.
- `--approve-next-batch`: optional explicit approval token for starting batch >1.

Bare-path inference: if `$ARGUMENTS` contains a path-like token (contains `/` or ends with `.md`) that is not preceded by a recognized flag, treat it as the `--design` value. Strip a leading `@` from any path token (Claude Code file-picker prefix).

Validate the parsed control flags before spawning the subagent:
- require integers for `--batch`, `--round`, and `--max-rounds` when they are present
- require a positive integer for `--timeout` when it is present
- require `batch >= 1`
- require `batch <= 2` unless a harness-maintainer override is explicitly documented outside the ordinary user approval loop
- require `round >= 1`
- require `1 <= max-rounds <= 3`
- reject `round > max-rounds` when both are present
- reject `--batch > 1` unless `--approve-next-batch` is present
- reject `--approve-next-batch` when `--batch` is omitted or equals `1`
- reject simultaneous `--cross-model` and `--adversarial`
- reject any token in `$ARGUMENTS` that is neither a recognized flag, a flag value, nor a bare path consumed by inference

Track mode:
- default mode is `review-only`
- if `--repair-review` is present, mode is `repair-review`

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

b) Resolve `--design` to absolute path (required):
   Try in order: `realpath "{design_path}"`, then `realpath "{resolved_worktree}/{design_path}"` (if --branch was used).
   If neither resolves to an existing file → stop with "design file not found: {design_path}".
   Record the resolved path as `{resolved_design}`. Use this in Step 2 instead of the original path.

Use the resolved absolute paths (not the original arguments) in all subsequent steps.

Step 2 — Spawn the subagent using the Agent tool with this exact prompt (replace `{SCRIPT}` with the resolved absolute path, `{resolved_design}` with the pre-validated design path from Step 1.5, and `{flag_lines}` with zero or more validated `args+=(...)` lines derived from the script-passthrough flags):

Script-passthrough flags (include in `{flag_lines}` when present):
- `--reviewer <name>`
- `--cross-model`
- `--adversarial`
- `--depth <thorough|quick>`
- `--timeout <seconds>`
- `--branch <name>`
- `--batch <n>`
- `--round <n>`
- `--max-rounds <n>`
- `--approve-next-batch`
- `--prior-findings <path>` (generated by repair loop, not user-facing)

Host-only flags (do NOT include in `{flag_lines}` — consumed by the command wrapper):
- `--repair-review` → controls whether Step 4 repair loop runs; never passed to the script

---

You are a script runner. Run ONE bash command and report the results. Do NOT review designs yourself. Do NOT read any files. Do NOT construct codex/claude/gemini commands yourself.
Use the same timeout budget for the Bash tool invocation and the inner runner command. Set `timeout_seconds` to the validated caller value or `1800` when omitted.

Run:
```
json_file="$(mktemp)"
stderr_file="$(mktemp)"
timeout_seconds="{timeout_seconds}"
args=(bash {SCRIPT} --mode design --host claude --plan "{resolved_design}")
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

If EXIT_CODE is 10 and cross/adversarial mode was requested, retry with `--allow-same-model-fallback` added.
If EXIT_CODE is still non-zero after retry, report the full error output and stop.

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
- `.result.verdict`

Validation rules:
- Treat scalar control fields as required and non-empty.
- Treat `.blocking_findings` as required and typed, but allow it to be `[]` when `.result.verdict == "PASS"`.
- If `.result.verdict == "FAIL"`, require `.blocking_findings` to contain the Critical/Important issues you will report.
- If `.result.verdict == "PASS"`, require `.result.pass_rationale` to be non-empty.

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
- If FAIL: list `.blocking_findings[]`
- If PASS: `.result.pass_rationale`

Step 4 — Host Repair Loop:
- If mode is `review-only`, stop after reporting the result.
- If `.status == "pass"`, stop after reporting the result.
- If `.status == "needs_fixes"`, the host must fix only `.blocking_findings[]` in the current design document, and only when those blocking findings are `scope_class == "in_scope_blocking"`.
- Apply the smallest viable fixes that satisfy the cited evidence and do not expand scope beyond the design boundary.
- Design fixes should preserve or repair the `Implementation Surface` refs needed by downstream plan/code review.
- Treat any blocking finding with `scope_class != "in_scope_blocking"` as manual-only. Do not continue `repair-review` for those cases.
- After fixing, save the current `.blocking_findings` to a temp file for prior-findings context:
  ```
  prior_findings_file="$(mktemp --suffix=.json)"
  echo '<blocking_findings_json>' > "$prior_findings_file"
  ```
- After fixing, rerun Step 2 with:
  - the same reviewer and design flags
  - `--batch` set to the current `.batch`
  - `--round` set to `.suggested_next_round`
  - `--max-rounds` preserved if the caller provided it
  - `--prior-findings "$prior_findings_file"` added to pass context to the reviewer
- Repeat until the wrapper returns `.status == "pass"` or `.status == "manual_review_required"`.

Step 5 — Manual Gate:
- If `.status == "manual_review_required"`, stop and report the unresolved `.blocking_findings[]`.
- Report the exact next-batch control values from `.suggested_next_batch` and `.suggested_next_round`.
- Do not start the next batch automatically.
- The next batch may start only on a fresh explicit user invocation that includes `--batch <suggested_next_batch> --round 1 --approve-next-batch`.
- If `suggested_next_batch > 2`, treat the review budget as exhausted. Stop for split scope, upstream design revision, or deliberate harness override instead of launching another repair batch.
