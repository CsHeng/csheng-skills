---
description: Review a design with a bounded agent-native brief
argument-hint: "<design-path>"
allowed-tools: ["Agent", "Read", "Glob", "Grep", "Bash"]
---

Use `coding:review-design`.

Validate the design path, construct a bounded brief from the changed design sections, goals, non-goals, acceptance conditions, implementation surface, and justified supporting documents, then prefer one reviewer subagent for non-trivial review. Review directly when the artifact is small or delegation is unavailable.

Return candidate findings only. The main agent adjudicates them through `coding:review-change`; no reviewer may edit the artifact, delegate recursively, or authorize repair.
