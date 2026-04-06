---
description: Top-level sovereign harness entry for updating stable truth after a verified truth-affecting change
argument-hint: "<change context|paths>"
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Edit", "MultiEdit"]
---

Invoke the `coding:sync-truth` skill as the top-level truth-sync entry.

Interpret `$ARGUMENTS` as the verified change context, evidence, or stable docs that need updating.

Rules:
- require verified change evidence before syncing truth
- update stable docs with the minimum necessary changes
- keep stage artifacts as history, not default truth
- use `coding:organize-docs` only as a lower-plane maintenance component when needed
