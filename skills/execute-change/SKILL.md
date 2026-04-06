---
name: execute-change
description: "Use when an approved implementation plan should be executed under serial-first harness control with explicit converge, review, verify, and rollback checkpoints. Activates for: execute change, implement plan, run approved tasks, serial execution, 执行变更, 实施计划。"
---

# Execute Change

Execute an approved plan under harness control.

## Use This Skill When

- the user wants implementation work against an approved plan
- the harness must drive task execution, convergence, review, and verification
- the change has a declared serial path or an explicitly approved parallel batch

## Do Not Use This Skill When

- the request still needs design or plan approval
- the user only wants a read-only review
- the task is only truth sync or close

## Workflow

1. Confirm the approved plan, dependency state, and current phase.
2. Execute tasks serially unless the plan defines a human-approved parallel batch.
3. Converge results back into one reviewable state.
4. Route the result through `review-change` and verification before closure.
5. Escalate repeated failures upward instead of continuing indefinitely.

## Operating Rules

- This is a top-level harness entry.
- Serial-first is the default.
- No unattended execution is the default.
- Parallel execution requires explicit human approval after dependency freeze.
