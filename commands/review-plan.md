---
description: Cross-model plan review with context isolation
argument-hint: "--plan <path> [--reviewer <codex|claude|gemini>]"
allowed-tools: ["Task"]
---

Run cross-model plan review using the review-plan-agent.

Parse the following from $ARGUMENTS:
- `--plan <path>`: plan file to review. Required.
- `--reviewer <name>`: reviewer driver to use (codex, claude, gemini). If omitted, auto-detect opposite.

Pass all parsed arguments to the review-plan-agent. The agent handles script location, execution, output formatting, and fallback.
