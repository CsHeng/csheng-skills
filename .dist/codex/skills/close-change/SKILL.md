---
name: close-change
description: "Use after a verified change to decide merge, release, cleanup, rollback, branch closure, or final close-gate status."
---

# Close Change

Judge whether the current change can finish.

## Use This Skill When

- the change is ready for merge, release, or workspace cleanup
- the harness must make the final close decision after review and verification
- the user wants an explicit closure judgment instead of an implied finish

## Do Not Use This Skill When

- the change still lacks required review, verification, or truth-sync evidence
- the task is still in design, planning, execution, or review
- the request only asks for local git status or cleanup advice

## Workflow

1. Check whether review, verification, and truth-sync gates are satisfied as applicable.
2. Confirm the target close mode: merge, release, or cleanup.
3. Block closure when required evidence or approvals are missing.
4. Produce the final close decision and any remaining human actions.

## Operating Rules

- This is the top-level closure gate.
- Final completion judgment belongs to the harness.
- Human approval remains final for close.
- No change closes by default just because implementation stopped.
- Evidence before closure: review status, verification status, requested write/install/deploy/commit status, and truth-sync status must each be proven from current artifacts or command output.
- Do not infer close readiness from partial checks, previous-session output, or delegated-agent summaries.
