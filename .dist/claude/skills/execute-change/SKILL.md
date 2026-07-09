---
name: execute-change
description: "Use to execute an approved implementation plan with serial tasks, verification, review gates, rollback handling, and truth-sync tracking."
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
2. Read `## Execution Continuity` if present and resolve whether execution is continuous, pre-confirmation-blocked, or not ready.
3. Run a one-time worktree preflight before the first code mutation when execution starts in the current checkout.
4. Execute ready tasks serially unless the plan defines a human-approved parallel batch.
5. Keep progress in a task-level execution ledger instead of relying on chat memory alone.
6. Converge results back into one reviewable state.
7. Route the result through `review-change` and verification before closure.
8. Normalize review and verification into one execution verdict.
9. Escalate repeated failures upward instead of continuing indefinitely.

## Execution Continuity Handling

Use the plan's `## Execution Continuity` section as the execution contract.

- If `execution_mode: continuous_after_plan_approval`, execute the approved plan without asking more human questions unless a declared `runtime_contingency` is triggered by observed evidence.
- If any `confirmation_clearance` item has `resolution: needs_confirmation_before_execution`, stop before the first mutation and ask the exact `C*` question(s). Do not partially execute low-risk tasks unless the plan explicitly separates them from the blocked task range.
- If a `confirmation_clearance` item is `pre_confirmed`, do not ask again; record it in the execution ledger when its task range is reached.
- If `execution_mode: not_ready`, stop and route back to `plan-change` or `design-change` as declared by the plan.
- Treat `runtime_contingencies` as reactive stop conditions only. They do not block normal execution until the declared trigger is actually observed.
- Legacy plans without `## Execution Continuity` may be executed in compatibility mode, but if a known human decision appears during preflight, stop before mutation and route the missing clearance back to `plan-change`.

## Resume And Completion Gates

- After interruption, compaction, rollback, or resumed execution, re-check the latest user request, the current ledger state, and the last completed write/install/deploy command before continuing.
- Verification passing does not imply that an install, deploy, write, or commit step completed. Record those as complete only after their own command succeeds.
- If execution stopped after verification but before the requested write/install/deploy step, report the incomplete step instead of declaring the change done.
- Do not claim completion, pass status, fixed status, or readiness without fresh verification evidence from the current execution turn.
- Treat delegated-agent success reports as claims to verify with local diff, review output, or command evidence before advancing the harness gate.

## Operating Rules

- This is a top-level harness entry.
- Serial-first is the default.
- No unattended execution is the default.
- Parallel execution requires explicit human approval after dependency freeze.
- The approved plan is the atomic execution unit for this entry.
- Do not stop mid-plan merely because one task completed while another ready task remains.
- Do not re-open plan-approved or pre-confirmed decisions during execution unless live evidence contradicts the plan.
- Do not convert known planning decisions into runtime contingencies; unresolved known decisions belong in `plan-change`.
- Task verification and task-scoped review happen before a task is marked done.
- For behavior changes, prefer red-green verification: create a failing test or narrow reproducer, confirm it fails for the expected reason, implement the smallest fix, then rerun the narrow and declared plan verification.
- For failures, identify the reproducible symptom and root cause before applying fixes; if three fix attempts fail, stop for design or plan reconsideration instead of stacking more patches.
- When the next state is already determined by review, verification, truth-sync, or rollback gates, report it directly instead of asking whether to continue.
