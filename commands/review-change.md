---
description: Top-level sovereign harness review runner with target validation, lower-plane routing, and normalized gate results
argument-hint: "[--design <path> | --plan <path>] [--file <path> ...] [--repair-review] [--depth <thorough|quick>] [--timeout <seconds>] [--branch <name>] [--batch <n>] [--round <n>] [--max-rounds <n>] [--approve-next-batch]"
allowed-tools: ["Agent", "Read", "Glob", "Grep", "Bash", "Edit", "MultiEdit"]
---

Run the sovereign harness review entry with explicit target validation, lower-plane review routing, normalized gate output, and deterministic stop states.

This command is the command-surface wrapper for `coding:review-change`.

Parse the following from `$ARGUMENTS`:
- `--design <path>`: optional design artifact input
- `--plan <path>`: optional plan artifact input or implementation-plan baseline for code review
- `--file <path>`: optional code scope file. Repeatable.
- `--repair-review`: optional pass-through to lower-plane review flow
- `--depth <thorough|quick>`: optional review depth
- `--timeout <seconds>`: optional lower-plane review timeout. If omitted, default to `1800`. Use this same value for the outer Bash tool invocation and the inner `bash ... --timeout` review call.
- `--branch <name>`: optional worktree branch for lower-plane review
- `--batch <n>`: optional repair-review batch metadata
- `--round <n>`: optional repair-review round metadata
- `--max-rounds <n>`: optional repair-review cap. Must satisfy `1 <= n <= 3`
- `--approve-next-batch`: optional explicit approval token for batch `> 1`
- one bare path-like token may be consumed as `--design` or `--plan`
- if a consumed bare path contains `-design.md` or `/specs/`, treat it as `--design`; otherwise treat it as `--plan`

Validate the parsed control flags before spawning the subagent:
- require a positive integer for `--timeout` when it is present
- require integers for `--batch`, `--round`, and `--max-rounds` when they are present
- require `batch >= 1`
- require `batch <= 2` unless the caller explicitly documents a harness-maintainer override outside the ordinary user approval loop
- require `round >= 1`
- require `1 <= max-rounds <= 3`
- reject `round > max-rounds` when both are present
- reject `--batch > 1` unless `--approve-next-batch` is present
- reject `--approve-next-batch` when `--batch` is omitted or equals `1`
- if a lower-plane result suggests `suggested_next_batch > 2`, stop at `manual-decision-required` and recommend split scope, design revision, or deliberate budget override instead of another repair batch

If no design, no plan, and no files were provided, default the review scope to the current repository diff from:
```bash
git diff --name-only --diff-filter=ACMR
```
If that diff is empty, stop with `no review target`.

Step 1 — Resolve runner paths yourself with Bash:
```bash
RUNNER=""
DESIGN_RUNNER=""
PLAN_RUNNER=""
REVIEW_GATE=""
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/review-runner.sh" ]]; then
  RUNNER="$(realpath "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/review-runner.sh")"
fi
if [[ -z "${RUNNER:-}" ]]; then
  RUNNER="$(find ~/.claude/plugins -path '*/skills/_harness-libs/review-runner.sh' -print -quit 2>/dev/null)"
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

if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/plan-runner.sh" ]]; then
  PLAN_RUNNER="$(realpath "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/plan-runner.sh")"
fi
if [[ -z "${PLAN_RUNNER:-}" ]]; then
  PLAN_RUNNER="$(find ~/.claude/plugins -path '*/skills/_harness-libs/plan-runner.sh' -print -quit 2>/dev/null)"
  [[ -n "${PLAN_RUNNER:-}" ]] && PLAN_RUNNER="$(realpath "$PLAN_RUNNER")"
  [[ -f "${PLAN_RUNNER:-}" ]] || PLAN_RUNNER=""
fi

if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/review-gate.sh" ]]; then
  REVIEW_GATE="$(realpath "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/review-gate.sh")"
fi
if [[ -z "${REVIEW_GATE:-}" ]]; then
  REVIEW_GATE="$(find ~/.claude/plugins -path '*/skills/_harness-libs/review-gate.sh' -print -quit 2>/dev/null)"
  [[ -n "${REVIEW_GATE:-}" ]] && REVIEW_GATE="$(realpath "$REVIEW_GATE")"
  [[ -f "${REVIEW_GATE:-}" ]] || REVIEW_GATE=""
fi

printf 'RUNNER=%s\nDESIGN_RUNNER=%s\nPLAN_RUNNER=%s\nREVIEW_GATE=%s\n' "$RUNNER" "$DESIGN_RUNNER" "$PLAN_RUNNER" "$REVIEW_GATE"
```
If any required runner is empty, stop and report the missing path.

Step 2 — Resolve artifact class and concrete review target:
- Record the review entry phase with:
```bash
bash "$RUNNER" entry-phase
```
- Resolve the artifact class with:
```bash
bash "$RUNNER" artifact-class "${resolved_design:-}" "${resolved_plan:-}" "${resolved_files[@]}"
```
- Supported artifact classes are exactly:
  - `design`
  - `plan`
  - `code-impl`
- Resolve all provided paths to absolute paths before continuing.
- For `design`, resolve exactly one design artifact.
- For `plan`, resolve exactly one plan artifact.
- For `code-impl`, optionally resolve one `--plan` baseline plus zero or more `--file` paths. If no files were provided, derive them from the current diff.

Step 3 — Validate the review target before spawning lower-plane review:
- For `design`, run:
```bash
bash "$RUNNER" validate-target design "<resolved_design>"
```
- For `plan`, run:
```bash
bash "$RUNNER" validate-target plan "<resolved_plan>"
```
- For `code-impl`, run:
```bash
bash "$RUNNER" validate-target code-impl "${resolved_plan:-}" "${resolved_files[@]}"
```
- If target validation fails, stop before any lower-plane review.
- When `code-impl` has a plan baseline, preserve that exact `--plan` path for lower-plane bounded review.

Step 4 — Run lower-plane review in an isolated subagent through `skills/_harness-libs/review-gate.sh`:
- Build a bash argv array. Do not splice caller-derived text directly into the shell command.
- Use this exact subagent prompt shape:

---
You are a script runner. Run ONE bash command and report the results. Do NOT review artifacts yourself. Do NOT read files. Do NOT construct reviewer commands yourself.

Run:
```bash
json_file="$(mktemp)"
stderr_file="$(mktemp)"
args=()
case "{artifact_class}" in
  design)
    args=(bash {REVIEW_GATE} run design claude "{resolved_design}")
    ;;
  plan)
    args=(bash {REVIEW_GATE} run plan claude "{resolved_plan}")
    ;;
  code-impl)
    args=(bash {REVIEW_GATE} run code-impl claude)
    [[ -n "{resolved_plan_optional}" ]] && args+=(--plan "{resolved_plan_optional}")
    # add one args+=(--file "...") line for every resolved file
    ;;
esac
```

Add optional argv lines when present:
- `args+=(--repair-review)`
- `args+=(--depth "{depth}")`
- `args+=(--timeout "{timeout_seconds}")`
- `args+=(--branch "{branch}")`
- `args+=(--batch "{batch}")`
- `args+=(--round "{round}")`
- `args+=(--max-rounds "{max_rounds}")`
- `args+=(--approve-next-batch)`

Set `timeout_seconds` to the validated caller value or `1800` when omitted.

Then run:
```bash
timeout_seconds="{timeout_seconds}"
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

Invoke the Bash tool for this command with timeout `timeout_seconds` seconds.

If the final exit code is non-zero, report stderr and stop.
Otherwise, return stdout/stderr verbatim.
---

Step 5 — Validate and normalize the lower-plane review output yourself:
- Extract the JSON between `JSON_BEGIN` and `JSON_END`
- Validate it with:
```bash
bash "$RUNNER" validate-output "$json_file"
```
- This is the `review-runner.sh validate-output` gate.
- Build the normalized gate result with:
```bash
gate_json="$(bash "$RUNNER" gate-result "{artifact_class}" "$json_file")"
```
- The normalized gate result is the harness-facing review verdict. Report it back as the normalized gate result for this top-level entry.

Step 6 — Deterministic stop state:
- If the normalized gate result verdict is `pass`:
  - `design`: return PASS to the invoking design entry; it may advance to its explicit human approval gate
  - `plan`: return PASS to the invoking plan entry; it may advance to its explicit human approval gate
  - `code-impl`: return PASS to the invoking execute entry; it may advance to verification, not directly to close
- If the normalized gate result verdict is `needs-fixes`, stop and report the exact blocking findings plus `suggested_next_round`
- If the normalized gate result verdict is `manual-decision-required`, stop and report the exact `suggested_next_batch` and `suggested_next_round`
- If `suggested_next_batch > 2`, also report `budget_exhausted: true` and do not present another batch as the default next step
- Review and verification are still separate gates
- The machine-checkable gate state decides the next stop condition
- Do NOT ask whether to continue when the machine-checkable gate already determines the next state
