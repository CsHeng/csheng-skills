---
name: plan-change
description: "Use after approved design or scope to create execution-grade plans with task order, dependencies, verification, and rollback triggers."
---

# Plan Change

Compile an approved change into an execution plan the harness can govern.

## Use This Skill When

- an approved design or explicit boundary decision needs an implementation plan
- the harness must define task order, write sets, or verification commands
- the change needs dependency freeze or rollback triggers before execution

## Do Not Use This Skill When

- the request still needs change classification or design approval
- the user only wants code execution against an already approved plan
- the task is only review, truth sync, or close

## Workflow

1. Load the approved design or boundary decision.
2. Break the work into ordered tasks with explicit dependencies and stable task IDs.
3. Identify any human confirmation, live-risk, destructive-write, external dependency, credential, or cutover uncertainty and try to resolve it before finalizing the plan.
4. Run work-package readiness before review.
5. Define touched files, executable oracles, verification commands, review depth, and rollback triggers for each task.
6. Mark any future parallel-safe batch explicitly; otherwise keep the plan serial.
7. Validate the plan artifact before review.
8. Route the artifact through mandatory plan review and bounded in-scope autofix when needed.
9. Hold the artifact at `approval_status: pending` until explicit human plan approval.
10. In the final planning summary, show whether execution can proceed continuously after approval or which confirmation IDs still need answers.
11. Stop after explicit human plan approval and hand off to `implement-change`.

## Work-Package Readiness

Before review, the plan must prove that the current milestone is small enough to execute.

Record a `## Work Package Readiness` section with:
- `milestone_objective`
- `non_goals`
- `future_phase`
- `decision_status`: `ready_for_review`, `needs_design_decision`, `split_scope`, or `manual_checkpoint`
- `oracle_strategy`: selected with `executable-oracle-architecture-selector` when behavior, architecture, or runtime correctness is non-trivial
- `acceptance_oracles`: concrete tests, contracts, probes, dry-runs, manual evidence, or substitute verification
- `execution_continuity`: `continuous_after_plan_approval`, `pre_confirmation_required`, or `not_ready`
- `max_review_batches`: default `2`
- `subagent_ready`: `true` only when a subagent can execute the slice without redefining scope

If `decision_status` is not `ready_for_review`, stop and return that typed state instead of making the plan bigger.

If a task cannot declare an executable oracle or substitute verification, it is not ready for implementation unless the plan explicitly marks the task as docs-only, exploratory, or manual-evidence-only.

## Execution Continuity

The goal of planning is to maximize uninterrupted execution after plan approval. Do not create stop gates as a default planning style.

Record a `## Execution Continuity` section with:
- `execution_mode`: `continuous_after_plan_approval`, `pre_confirmation_required`, or `not_ready`
- `confirmation_clearance`: stable `C*` items for known human decisions, destructive writes, live cutovers, credential needs, or external dependencies
- `runtime_contingencies`: stable `X*` items for execution-time surprises only, such as failed probes, live-state drift, missing credentials, verification failures, or rollback triggers
- `planned_stop_points`: should be empty for the normal case; non-empty only when a known issue cannot be safely pre-confirmed during planning
- `task_ordering_rationale`: explain why low-risk, no-confirmation tasks run before live, destructive, or high-risk tasks unless a risky task is a hard prerequisite

Each `confirmation_clearance` item should include:
- `id`: example `C1`
- `question`: the exact decision needed from the user
- `applies_to`: task IDs
- `resolution`: `pre_confirmed`, `needs_confirmation_before_execution`, or `deferred_not_in_scope`
- `default_if_unanswered`: normally `stop`

Known user decisions should be resolved during planning whenever possible. If a known decision remains `needs_confirmation_before_execution`, the plan is not fully continuous and the final planning summary must lead with that fact.

Use `runtime_contingencies` only for uncertainty that cannot be settled before execution. They are not routine human checkpoints.

## Planning Summary

When plan writing and mandatory plan review are complete, the response must include a concise execution-readiness summary before asking for approval:
- `C0`: no remaining confirmation needed; approval authorizes continuous execution
- or `C1`, `C2`, ...: exact confirmations still needed before execution
- `E1`, `E2`, ...: task ranges expected to run continuously
- `X1`, `X2`, ...: runtime contingencies that would stop execution only if triggered by observed evidence

Do not finish plan-change with only a generic approval request. The user must be able to see whether approving the plan will let `implement-change` run through the whole plan or where it will stop.

## Operating Rules

- This is a top-level harness entry.
- A prose status summary is not a valid plan artifact.
- New implementation plans should be execution-grade task catalogs, not prose-only checklists.
- Serial execution is the default planning posture.
- Parallel work must be named, dependency-frozen, and human-approved.
- Prefer pre-confirming known gates during planning over deferring them into execution.
- Plan approval should normally authorize the whole plan to run; unresolved confirmations are exceptions that must be clearly labeled.
- Mandatory review happens before the human approval gate.
- The upstream design should already be `approval_status: approved` before planning starts.
- Review and verification requirements must be part of the plan, not implied later.
- Behavior-changing tasks should declare the failing test, narrow reproducer, or substitute verification evidence expected before implementation.
- Plan writers must not absorb every possible reviewer concern into the current milestone. Put out-of-scope concerns into `future_phase` or stop with `split_scope` / `needs_design_decision`.
- Each new task should declare enough metadata for task-ledger execution, including `task_id`, `depends_on`, `scope_slice`, task-scoped file refs, `verification_scope`, `executor_mode`, `task_review_depth`, `done_when`, and `rollback_on_failure`.
- Task order should put low-risk, repo-local, reversible, and no-confirmation tasks before high-risk, live, destructive, or external-dependency tasks unless the risky task is a hard prerequisite.
- Legacy plans may remain readable in compatibility mode during transition, but new plans should not rely on that fallback.
