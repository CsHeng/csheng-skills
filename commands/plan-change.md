---
description: Top-level sovereign harness entry for compiling an approved change into ordered tasks, dependencies, and verification
argument-hint: "<design path|approved change definition>"
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Edit", "MultiEdit"]
---

Invoke the `coding:plan-change` skill as the top-level planning entry.

Interpret `$ARGUMENTS` as the approved design path or boundary decision to plan from.

Rules:
- require an approved design or explicit boundary decision before planning
- define task order, dependencies, write sets, verification commands, and rollback triggers
- keep execution serial by default
- mark any parallel-safe batch explicitly instead of implying it
- stop for human approval before handing off to `coding:execute-change`
