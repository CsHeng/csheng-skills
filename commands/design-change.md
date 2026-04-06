---
description: Top-level sovereign harness entry for defining a change, classifying impact, and selecting design strength
argument-hint: "<change request>"
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Edit", "MultiEdit"]
---

Invoke the `coding:design-change` skill as the top-level change-definition entry.

Treat `$ARGUMENTS` as the change request to shape.

Rules:
- classify truth impact and boundary impact before planning
- choose explicitly between `no-design`, `design-lite`, and `design-full`
- produce or update the design artifact only when the classification requires it
- stop for human approval before handing off to `coding:plan-change`
