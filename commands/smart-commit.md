---
description: Analyze changes, exclude unsafe files, split into focused commits by business purpose
argument-hint: "[--filter=<path>]"
allowed-tools: ["Bash(git rev-parse --git-dir:*)", "Bash(git status --short:*)", "Bash(git diff --cached:*)", "Bash(git diff:*)", "Bash(git ls-files:*)", "Bash(git add:*)", "Bash(git commit:*)", "Bash(git log:*)", "Read", "Glob", "Grep"]
---

Invoke the `coding:smart-commit` skill to analyze current repository changes and produce multiple focused commits grouped by business purpose.

If `$ARGUMENTS` contains `--filter=<path>`, restrict analysis to files within that directory and its subdirectories.
