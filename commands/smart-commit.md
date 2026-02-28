---
description: Analyze changes, exclude unsafe files, split into focused commits by business purpose
argument-hint: "[--filter=<path>]"
allowed-tools: ["Bash", "Bash(git rev-parse --git-dir:*)", "Bash(git status --short:*)", "Bash(git diff --cached:*)", "Bash(git diff:*)", "Bash(git ls-files:*)", "Bash(git add:*)", "Bash(git commit:*)", "Bash(git log:*)", "Read", "Glob", "Grep"]
---

## Usage

Invoke the `coding:smart-commit` skill to analyze current repository changes and produce multiple focused commits grouped by business purpose.

## Arguments

- `--filter=<path>`: Restrict analysis to files within this directory and its subdirectories (default: current working directory)

## Examples

```bash
# Analyze all changes and create smart commits
/smart-commit

# Restrict to a specific directory
/smart-commit --filter=src/auth/
```
