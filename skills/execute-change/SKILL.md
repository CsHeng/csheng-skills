---
name: execute-change
description: "Use when an approved implementation plan should be executed under serial-first harness control with explicit converge, review, verify, and rollback checkpoints. Activates for: execute change, implement plan, run approved tasks, serial execution, 执行变更, 实施计划。"
---

# Execute Change

Execute an approved plan under harness control as one execution unit and stop only at the next explicit gate.

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
2. Run a one-time worktree preflight before the first code mutation when execution starts in the current checkout.
3. Execute ready tasks serially unless the plan defines a human-approved parallel batch.
4. Keep progress in a task-level execution ledger instead of relying on chat memory alone.
5. Converge results back into one reviewable state.
6. Route the result through `review-change` and verification before closure.
7. Normalize review and verification into one execution verdict.
8. Escalate repeated failures upward instead of continuing indefinitely.

## Operating Rules

- This is a top-level harness entry.
- Serial-first is the default.
- No unattended execution is the default.
- Parallel execution requires explicit human approval after dependency freeze.
- The approved plan is the atomic execution unit for this entry.
- Do not stop mid-plan merely because one task completed while another ready task remains.
- Task verification and task-scoped review happen before a task is marked done.
- When the next state is already determined by review, verification, truth-sync, or rollback gates, report it directly instead of asking whether to continue.
