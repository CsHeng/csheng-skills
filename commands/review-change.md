---
description: Top-level sovereign harness review gate that routes to design, plan, or code review
argument-hint: "[--design <path> | --plan <path> | --file <path> ...]"
allowed-tools: ["Agent", "Read", "Glob", "Grep", "Bash", "Edit", "MultiEdit"]
---

Invoke the `coding:review-change` skill as the top-level review gate.

Route by artifact type:
- `--design <path>` or a design-doc path: use `coding:review-design`
- `--plan <path>` or a plan-doc path: use `coding:review-plan`
- code implementation scope, explicit files, or repository diff: use `coding:review-code-impl`

Rules:
- preserve user-provided review flags such as reviewer, depth, plan, and file scope when routing
- keep review and verification as separate gates
- report the normalized gate result back at the harness layer
