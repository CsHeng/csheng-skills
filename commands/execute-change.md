---
description: Top-level sovereign harness entry for executing an approved plan under serial-first control
argument-hint: "<plan path>"
allowed-tools: ["Agent", "Read", "Glob", "Grep", "Bash", "Edit", "MultiEdit"]
---

Invoke the `coding:execute-change` skill as the top-level execution entry.

Interpret `$ARGUMENTS` as the approved implementation plan path.

Rules:
- require an approved plan before execution starts
- execute serially unless the plan defines a dependency-frozen batch with explicit human approval
- converge back into one reviewable state before closure
- route review through `coding:review-change`
- do not assume unattended execution
