---
description: Manually invoke smart-commit to analyze changes and automatically create focused local commits
argument-hint: "[--filter=<path>]"
allowed-tools: ["Bash(git rev-parse --git-dir:*)", "Bash(git status --short:*)", "Bash(git diff --cached:*)", "Bash(git diff:*)", "Bash(git ls-files:*)", "Bash(git add:*)", "Bash(git commit:*)", "Bash(git log:*)", "Read", "Glob", "Grep"]
---

Invoke the `coding:smart-commit` skill to analyze current repository changes and automatically produce focused local commits grouped by business purpose. Do not invoke this command implicitly; it is a user-requested commit operation.

If `$ARGUMENTS` contains `--filter=<path>`, restrict analysis to files within that directory and its subdirectories.
