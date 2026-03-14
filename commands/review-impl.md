---
description: Cross-model implementation review with context isolation
argument-hint: "[--reviewer <codex|claude|gemini>] [--plan <path>]"
allowed-tools: ["Task"]
---

Run cross-model implementation review using the review-impl-agent.

Parse the following from $ARGUMENTS:
- `--reviewer <name>`: reviewer driver to use (codex, claude, gemini). If omitted, auto-detect opposite.
- `--plan <path>`: optional plan baseline for spec compliance checking.

Pass all parsed arguments to the review-impl-agent. The agent handles script location, execution, output formatting, and fallback.
