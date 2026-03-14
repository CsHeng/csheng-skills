---
description: Cross-model plan review with context isolation
argument-hint: "--plan <path> [--reviewer <codex|claude|gemini>]"
allowed-tools: ["Agent", "Bash"]
---

Run cross-model plan review in an isolated subagent.

Parse the following from $ARGUMENTS:
- `--plan <path>`: plan file to review. Required.
- `--reviewer <name>`: reviewer driver (codex, claude, gemini). If omitted, omit the flag.

Step 1 — Resolve the script path (run this Bash command yourself, do NOT delegate):
```
SCRIPT=""
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/run-review.sh" ]]; then
  SCRIPT="${CLAUDE_PLUGIN_ROOT}/scripts/run-review.sh"
elif [[ -f "scripts/run-review.sh" ]]; then
  SCRIPT="scripts/run-review.sh"
else
  SCRIPT="$(/bin/ls -dv ~/.claude/plugins/cache/skills-csheng/coding/*/scripts/run-review.sh 2>/dev/null | tail -1)"
  [[ -f "${SCRIPT:-}" ]] || SCRIPT=""
fi
echo "SCRIPT=$SCRIPT"
```
If SCRIPT is empty, report "review script not found" and stop.

Step 2 — Spawn the subagent using the Agent tool with this exact prompt (replace `{SCRIPT}` with the resolved absolute path, `{plan_path}` with the plan path, and `{flags}` with any remaining arguments):

---

You are a script runner. Run ONE bash command and report the results. Do NOT review plans yourself. Do NOT read any files. Do NOT construct codex/claude/gemini commands yourself.

Run:
```
bash {SCRIPT} --mode plan --host claude --plan "{plan_path}" {flags} 2>&1; echo "EXIT_CODE=$?"
```

If EXIT_CODE is 10, retry with `--allow-same-model-fallback` added.
If EXIT_CODE is still non-zero after retry, report the full error output and stop.

Otherwise, report the complete stdout and stderr output verbatim.

---

Step 3 — Format the result yourself (do NOT delegate):
The script stderr contains a line like `[run-review] step=done review_mode=cross-model reviewer=codex verdict=FAIL`. Extract `review_mode` and `reviewer` from that line. Do NOT infer review mode yourself — use ONLY what the script reports.

Parse the JSON from the subagent's output with jq (via Bash). Report:
- Review mode: the exact `review_mode` value from the script's `step=done` log line
- Reviewer driver: the exact `reviewer` value from that same log line
- Final verdict (PASS or FAIL)
- If FAIL: list Critical/Important findings from the JSON
- If PASS: the pass_rationale from the JSON
