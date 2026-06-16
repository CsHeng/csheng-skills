---
description: Top-level sovereign harness entry for updating stable truth after a verified truth-affecting change
argument-hint: "[--truth-sync <path>] [--review-status <pass|needs-fixes|needs-rollback|manual-decision-required>] [--verify-status <pass|needs-fixes|needs-rollback|manual-decision-required>] <change context|paths>"
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Edit", "MultiEdit"]
---

Run the sovereign harness truth-sync entry with verified evidence, stable truth boundary checks, explicit human approval, and deterministic next state.

This command is the command-surface wrapper for `coding:sync-truth`.

Parse the following from `$ARGUMENTS`:
- `--truth-sync <path>`: optional truth-sync artifact path. If omitted, derive the default path from a short topic.
- `--review-status <status>`: review gate status. Default `pass` only when the invoking execute gate already returned pass.
- `--verify-status <status>`: verification gate status. Default `pass` only when the invoking execute gate already returned pass.
- remaining text is verified change context and evidence. It is required when creating a new artifact.

Step 1 — Resolve the runner path yourself with Bash:
```bash
RUNNER=""
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/truth-sync-runner.sh" ]]; then
  RUNNER="$(realpath "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/truth-sync-runner.sh")"
fi
if [[ -z "${RUNNER:-}" ]]; then
  RUNNER="$(find ~/.claude/plugins -path '*/skills/_harness-libs/truth-sync-runner.sh' -print -quit 2>/dev/null)"
  [[ -n "${RUNNER:-}" ]] && RUNNER="$(realpath "$RUNNER")"
  [[ -f "${RUNNER:-}" ]] || RUNNER=""
fi

printf 'RUNNER=%s\n' "$RUNNER"
```
If the runner path is empty, stop and report the missing runner.

Step 2 — Resolve the truth-sync artifact:
- Record the entry phase with:
```bash
bash "$RUNNER" entry-phase
```
- If no artifact path was supplied, derive a short kebab-case topic from the verified change context and compute:
```bash
bash "$RUNNER" default-path "<topic-slug>"
```
- Resolve the final artifact path under the repository root.

Step 3 — Draft or update the truth-sync artifact:
- The artifact must include these sections exactly:
  - `## Evidence`
  - `## Stable Truth Updates`
  - `## Human Gate`
- In `## Evidence`, record at least:
  - `approved_design_ref`
  - `approved_plan_ref`
  - `review_gate_ref`
  - `verification_ref`
  - `truth_sync_required: true`
- In `## Stable Truth Updates`, record at least:
  - `stable_truth_refs`
  - `stage_artifact_refs`
  - `summary`
- `stable_truth_refs` must point only at long-lived truth roots such as `README.md`, `AGENTS.md`, stable `docs/` files, or skill/command docs that are stable truth for behavior.
- `stable_truth_refs` must not point at `docs/plans/`; that is the stage artifact root.
- Use `coding:organize-docs` only as a lower-plane maintenance component when the update touches documentation boundaries.
- In `## Human Gate`, record at least:
  - `approval_required: true`
  - `approval_status: pending`
  - `next_entry: close-change`

Step 4 — Validate the artifact:
```bash
bash "$RUNNER" validate "<resolved_truth_sync_artifact>"
```
If validation fails, fix the artifact before reporting the gate result.

Step 5 — Report the machine-checkable gate state:
```bash
bash "$RUNNER" approval-status "<resolved_truth_sync_artifact>"
bash "$RUNNER" gate-result "<resolved_truth_sync_artifact>" "<review_status>" "<verify_status>"
```
- If `approval_status: pending`, stop at the explicit human truth-sync approval gate.
- Keep `approval_status: pending` until the human explicitly approves the truth sync.
- Only after explicit approval may the artifact move to `approval_status: approved`.
- If the gate result has `ready_for_close == true`, the next entry is `coding:close-change`.
- If review or verification is no longer pass, report the failing gate and route back to `coding:execute-change`.
- Do NOT ask whether to continue when the machine-checkable gate already determines the next state.
