---
description: Execute an approved plan with serial task control, bounded agent-native review, verification, and typed closeout
argument-hint: "<approved-plan-path>"
allowed-tools: ["Agent", "Read", "Glob", "Grep", "Bash", "Edit", "MultiEdit"]
---

Use `coding:implement-change` and read its installed workflow and repair-loop references completely.

Resolve and validate the approved plan with `skills/_harness-libs/execute-runner.sh`. Require `approval_status: approved`, materialize the task catalog and task ledger, perform the one-time worktree preflight, and execute serial-first inside `allowed_touch_set = impl_file_refs + test_file_refs`.

For every task:

1. execute the task slice
2. run its narrow and declared `verification_scope`
3. construct a bounded review brief from the exact task diff and evidence
4. route task-scoped review through `coding:review-change`
5. prefer one reviewer subagent for non-trivial review; allow direct main-agent review for small mechanical changes
6. have the main agent adjudicate candidate findings
7. repair only `accepted` findings
8. run focused verification of accepted repairs and repair-introduced regressions
9. update the task ledger only after review and verification pass

Do not use a semantic review shell runner. Do not let a delegated reviewer edit, delegate recursively, or control lifecycle continuation.

After all tasks, combine review and verification through the deterministic evaluation gate, resolve rollback targets for failures, and return `sync-truth`, `close-change`, or the exact typed stop state. The machine-checkable gate decides continuation; do not ask whether to continue when that state is known.
