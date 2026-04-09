---
description: Top-level sovereign harness entry for merge, release, or cleanup judgment after all required gates pass
argument-hint: "[merge|release|cleanup] --review-status <status> --verify-status <status> --truth-sync-required <true|false> --truth-sync-completed <true|false>"
allowed-tools: ["Read", "Glob", "Grep", "Bash"]
---

Run the sovereign harness close gate with explicit review, verification, truth-sync, and close-mode evidence.

This command is the command-surface wrapper for `coding:close-change`.

Parse the following from `$ARGUMENTS`:
- close mode: one of `merge`, `release`, or `cleanup`. Default is `cleanup` when omitted.
- `--review-status <pass|needs-fixes|needs-rollback|manual-decision-required>`: required review gate status.
- `--verify-status <pass|needs-fixes|needs-rollback|manual-decision-required>`: required verification gate status.
- `--truth-sync-required <true|false>`: required truth-sync requirement from the execute or truth-sync gate.
- `--truth-sync-completed <true|false>`: required truth-sync completion state.

Step 1 — Resolve the runner path yourself with Bash:
```bash
RUNNER=""
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/close-runner.sh" ]]; then
  RUNNER="$(realpath "${CLAUDE_PLUGIN_ROOT}/skills/_harness-libs/close-runner.sh")"
fi
if [[ -z "${RUNNER:-}" ]]; then
  RUNNER="$(find ~/.claude/plugins -path '*/skills/_harness-libs/close-runner.sh' -print -quit 2>/dev/null)"
  [[ -n "${RUNNER:-}" ]] && RUNNER="$(realpath "$RUNNER")"
  [[ -f "${RUNNER:-}" ]] || RUNNER=""
fi

printf 'RUNNER=%s\n' "$RUNNER"
```
If the runner path is empty, stop and report the missing runner.

Step 2 — Validate close inputs:
```bash
bash "$RUNNER" entry-phase
bash "$RUNNER" validate "<merge|release|cleanup>" "<review_status>" "<verify_status>" "<truth_sync_required>" "<truth_sync_completed>"
```
- Closure requires review pass and verify pass.
- Closure requires truth sync when `truth_sync_required == true`.
- If validation fails, do not merge, release, or clean up.

Step 3 — Report the machine-checkable close decision:
```bash
bash "$RUNNER" decision "<merge|release|cleanup>" "<review_status>" "<verify_status>" "<truth_sync_required>" "<truth_sync_completed>"
```
- If `close_allowed == true`, report the selected close mode and the final close decision.
- If truth sync is still required, route to `coding:sync-truth`.
- If review or verification is not pass, route to `coding:execute-change`.
- Keep final completion judgment at the harness layer.
- Do not treat this command as permission to modify user-global Codex state or uninstall unrelated tooling.
- Do NOT ask whether to continue when the machine-checkable gate already determines the next state.
