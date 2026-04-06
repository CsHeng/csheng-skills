---
description: Top-level sovereign harness entry for project explanation, truth queries, and current-state analysis
argument-hint: "[question|path]"
allowed-tools: ["Read", "Glob", "Grep", "Bash"]
---

Invoke the `coding:analyze-project` skill as the top-level truth-query entry.

Interpret `$ARGUMENTS` as optional project scope, path, or analysis question.

Rules:
- if `$ARGUMENTS` is empty, analyze the current repository
- read stable docs first, then do targeted code or command verification
- search stage artifacts only when the user explicitly asks for history or when stable truth is insufficient
- keep the operation read-only
