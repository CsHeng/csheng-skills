---
description: Review an implementation diff with bounded context and change causality
argument-hint: "[--plan <path>] [--file <path> ...]"
allowed-tools: ["Agent", "Read", "Glob", "Grep", "Bash"]
---

Use `coding:review-implementation`.

Build the bounded review brief from the approved task slice, exact changed files and diff, task tests, verification evidence, touch set, and justified supporting files. Prefer one reviewer subagent for a non-trivial diff; review a small mechanical diff directly.

Require causal classification for every material candidate. Moving or renaming unchanged code does not activate pre-existing defects. Return candidate findings to the main agent for adjudication; do not edit, delegate recursively, or authorize repair.
