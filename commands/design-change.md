---
description: Top-level sovereign harness change-definition runner with mandatory classification, artifact validation, review, and human approval gate
argument-hint: "[--design <path>] [--reviewer <codex|claude|gemini>] [--depth <thorough|quick>] [--truth-impact <low|medium|high>] [--boundary-impact <low|medium|high>] [--truth-repair] [--request-kind <change-definition|change-planning|truth-maintenance>] [--max-rounds <n>] <change request>"
allowed-tools: ["Agent", "Bash", "Read", "Edit", "MultiEdit", "Glob", "Grep"]
---

Run the sovereign harness design entry with mandatory classification, artifact validation, design review, and explicit human approval before planning.

This command is the command-surface wrapper for `coding:design-change`.

Parse the following from `$ARGUMENTS`:
- `--design <path>`: optional output design path override
- `--reviewer <name>`: optional reviewer driver passed through to the shared review runner
- `--depth <thorough|quick>`: optional review depth passed through to the shared review runner
- `--truth-impact <low|medium|high>`: optional explicit truth-impact override
- `--boundary-impact <low|medium|high>`: optional explicit boundary-impact override
- `--truth-repair`: optional. If present, classify as truth repair
- `--request-kind <change-definition|change-planning|truth-maintenance>`: optional request-kind override. Default is `change-definition`
- `--max-rounds <n>`: optional review/autofix cap. Default `3`, must be `1 <= n <= 3`
- one bare path-like token (`/` in token or ends with `.md`) may be treated as `--design`
- all remaining bare text is the change request and is required

Reject any token that is neither a recognized flag, a flag value, a consumed bare path, nor part of the change request text.

Step 1 — Resolve runner paths yourself with Bash:
```bash
RUNNER=""
REVIEW_GATE=""
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/design-runner.sh" ]]; then
  RUNNER="$(realpath "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/design-runner.sh")"
fi
if [[ -z "${RUNNER:-}" ]]; then
  RUNNER="$(find ~/.claude/plugins -path '*/skills/_harness-libs/design-runner.sh' -print -quit 2>/dev/null)"
  [[ -n "${RUNNER:-}" ]] && RUNNER="$(realpath "$RUNNER")"
  [[ -f "${RUNNER:-}" ]] || RUNNER=""
fi

if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/review-gate.sh" ]]; then
  REVIEW_GATE="$(realpath "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/review-gate.sh")"
fi
if [[ -z "${REVIEW_GATE:-}" ]]; then
  REVIEW_GATE="$(find ~/.claude/plugins -path '*/skills/_harness-libs/review-gate.sh' -print -quit 2>/dev/null)"
  [[ -n "${REVIEW_GATE:-}" ]] && REVIEW_GATE="$(realpath "$REVIEW_GATE")"
  [[ -f "${REVIEW_GATE:-}" ]] || REVIEW_GATE=""
fi

printf 'RUNNER=%s\nREVIEW_GATE=%s\n' "$RUNNER" "$REVIEW_GATE"
```
If either path is empty, stop and report the missing runner.

Step 2 — Resolve classification and artifact path:
- Default `request_kind=change-definition`
- Default `truth_repair=false`
- If `--truth-impact` or `--boundary-impact` were omitted, infer them explicitly from the request and repo context, but the final chosen values MUST be one of `low|medium|high`
- Compute the classification record with:
```bash
bash "$RUNNER" classify "$request_kind" "$truth_impact" "$boundary_impact" "$truth_repair"
```
- Compute the entry phase with:
```bash
bash "$RUNNER" entry-phase
```
- If no design path was provided, derive a short kebab-case topic from the request and compute the default design path with:
```bash
bash "$RUNNER" default-path "<topic-slug>"
```
- Resolve the final design path to an absolute path under the repository root. If the file does not exist yet, create parent directories as needed.

Step 3 — Draft or update the design artifact:
- The design file must include these sections exactly:
  - `## Status`
  - `## Problem`
  - `## Goals`
  - `## Non-Goals`
  - `## Change Classification`
  - `## Boundaries`
  - `## Human Gate`
  - `## Implementation Surface`
- In `## Change Classification`, record at least:
  - `request_kind`
  - `change_class`
  - `design_strength`
  - `truth_impact`
  - `boundary_impact`
  - `recommended_next_phase`
- In `## Human Gate`, record at least:
  - `approval_required: true`
  - `approval_status: pending`
  - `next_entry: plan-change`
- In `## Implementation Surface`, record `impl_file_refs` and `test_file_refs`
- If the classification yields `design_strength=no-design`, still record the classification and the human gate. Do not silently skip the artifact.

Step 4 — Validate the drafted design artifact before review:
```bash
bash "$RUNNER" validate "<resolved_design>"
```
This is the `skills/_harness-libs/design-runner.sh validate` gate.
If validation fails, fix the artifact first. Do not proceed to review with an invalid design file.

Step 5 — Run mandatory design review in an isolated subagent:
- Route review through the top-level `coding:review-change` gate; the subagent below must use `skills/_harness-libs/review-gate.sh`, not call `_review-libs/run-review.sh` directly.
- Build a bash argv array. Do not splice caller-derived text directly into the shell command.
- Use this exact subagent prompt shape:

---
You are a script runner. Run ONE bash command and report the results. Do NOT review designs yourself. Do NOT read any files. Do NOT construct codex/claude/gemini commands yourself.

Run:
```bash
json_file="$(mktemp)"
stderr_file="$(mktemp)"
args=(bash {REVIEW_GATE} run design claude "{resolved_design}")
```

Add optional argv lines when present:
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

If `EXIT_CODE=10`, retry once with `args+=(--allow-same-model-fallback)`.
If the final exit code is non-zero, report stderr and stop.
Otherwise, return stdout/stderr verbatim.
---

Step 6 — Validate the review output yourself:
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

Step 7 — Mandatory bounded autofix loop:
- Review is mandatory for this harness entry; do not stop after drafting the design
- If review returns PASS, continue to Step 8
- If review returns FAIL and every blocking finding is `scope_class: in_scope_blocking`, fix only those findings in the current design artifact, rerun `bash "$RUNNER" validate "<resolved_design>"`, then rerun Step 5
- Default max rounds is `3` unless `--max-rounds` supplied
- If a rerun would exceed `max-rounds`, stop and report the unresolved findings with `suggested_next_round`
- If any blocking finding is out-of-scope or `manual_intervention_required=true`, stop and report the findings without further autofix

Step 8 — Human approval gate:
- After the design artifact validates and the mandatory review loop reaches PASS, stop and ask for explicit human approval
- Keep `approval_status: pending` until the human explicitly approves the design
- Only after explicit approval may the artifact move to `approval_status: approved`
- Report:
  - resolved design path
  - classification record summary
  - reviewer driver/model
  - final review verdict
  - recommended next entry: `coding:plan-change`
- Do NOT start planning automatically
- Do NOT respond as if the change is complete just because the design file was updated
- Do NOT ask whether to continue; report that the harness is stopped at the explicit human approval gate until `approval_status` becomes `approved`
