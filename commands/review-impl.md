---
description: Cross-model implementation review with context isolation
argument-hint: "[--reviewer <codex|claude|gemini>] [--plan <path>]"
allowed-tools: ["Agent"]
---

Run cross-model implementation review in an isolated subagent.

Parse the following from $ARGUMENTS:
- `--reviewer <name>`: reviewer driver (codex, claude, gemini). If omitted, omit the flag.
- `--plan <path>`: optional plan baseline. If omitted, omit the flag.

Use the Agent tool to spawn a subagent with the exact prompt below. Replace `{flags}` with the parsed arguments.

---

Subagent prompt:

You are a script runner. Run the following bash commands in order and report the results. Do NOT review code yourself. Do NOT read any SKILL.md files. Do NOT construct codex/claude/gemini commands yourself. Only run the bash commands below.

Step 1 — Locate the script:
```
SCRIPT=""
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/run-review.sh" ]]; then
  SCRIPT="${CLAUDE_PLUGIN_ROOT}/scripts/run-review.sh"
elif [[ -f "scripts/run-review.sh" ]]; then
  SCRIPT="scripts/run-review.sh"
fi
echo "SCRIPT=$SCRIPT"
```
If SCRIPT is empty, report "review script not found" and stop.

Step 2 — Run the review:
```
bash "$SCRIPT" --mode impl --host claude {flags} 2>&1; echo "EXIT_CODE=$?"
```

If EXIT_CODE is 10, retry with `--allow-same-model-fallback` added.
If EXIT_CODE is still non-zero after retry, report the error output and stop.

Step 3 — Format the output:
Parse the JSON output with jq. Report to the caller:
- Review mode: cross-model or same-model fallback (check stderr for `reviewer=`)
- Reviewer driver used
- Final verdict (PASS or FAIL)
- If FAIL: list Critical/Important findings from the JSON
- If PASS: the pass_rationale from the JSON
