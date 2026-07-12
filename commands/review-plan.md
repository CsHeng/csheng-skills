---
description: Review an implementation plan with a bounded agent-native brief
argument-hint: "<plan-path>"
allowed-tools: ["Agent", "Read", "Glob", "Grep", "Bash"]
---

Use `coding:review-plan`.

Validate the plan and its approved upstream design, then construct a bounded brief from the current milestone, changed plan sections, task DAG, acceptance oracles, rollback, execution continuity, and justified supporting files. Prefer one reviewer subagent for non-trivial review; review directly for a small plan or when delegation is unavailable.

Return candidate findings only. The main agent adjudicates them through `coding:review-change`; no reviewer may edit the plan, delegate recursively, or authorize repair.
