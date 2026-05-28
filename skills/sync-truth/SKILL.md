---
name: sync-truth
description: "Use after verified behavior changes to update stable project truth docs, README/AGENTS boundaries, and durable operational facts."
---

# Sync Truth

Update stable truth after a truth-affecting change has evidence behind it.

## Use This Skill When

- a verified change has `truth_impact = true`
- stable docs or other long-lived truth need to reflect approved behavior
- the harness must update truth from execution evidence rather than rediscovery

## Do Not Use This Skill When

- the change has no real truth impact
- the request is only a read-only project explanation; use `analyze-project`
- the task is only implementation review or close without truth updates

## Workflow

1. Confirm that truth sync is required for the change.
2. Gather approved design, plan, review, and verification evidence.
3. Update stable truth artifacts with the minimum required changes.
4. Use lower-plane truth maintenance skills when the update touches their domain.
5. Stop for explicit human truth-sync approval before close.

## Operating Rules

- This is the top-level truth-sync gate.
- `analyze-project` remains the read-only truth query entry.
- `organize-docs` remains a lower-plane truth maintenance component.
- Truth sync does not rediscover the project from zero.
