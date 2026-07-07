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
3. Run work-package readiness before review.
4. Define touched files, executable oracles, verification commands, review depth, and rollback triggers for each task.
5. Mark any future parallel-safe batch explicitly; otherwise keep the plan serial.
6. Validate the plan artifact before review.
7. Route the artifact through mandatory plan review and bounded in-scope autofix when needed.
8. Hold the artifact at `approval_status: pending` until explicit human plan approval.
9. Stop after explicit human plan approval and hand off to `execute-change`.

## Work-Package Readiness

Before review, the plan must prove that the current milestone is small enough to execute.

Record a `## Work Package Readiness` section with:
- `milestone_objective`
- `non_goals`
- `future_phase`
- `decision_status`: `ready_for_review`, `needs_design_decision`, `split_scope`, or `manual_checkpoint`
- `oracle_strategy`: selected with `executable-oracle-architecture-selector` when behavior, architecture, or runtime correctness is non-trivial
- `acceptance_oracles`: concrete tests, contracts, probes, dry-runs, manual evidence, or substitute verification
- `max_review_batches`: default `2`
- `subagent_ready`: `true` only when a subagent can execute the slice without redefining scope

If `decision_status` is not `ready_for_review`, stop and return that typed state instead of making the plan bigger.

If a task cannot declare an executable oracle or substitute verification, it is not ready for implementation unless the plan explicitly marks the task as docs-only, exploratory, or manual-evidence-only.

## Operating Rules

- This is a top-level harness entry.
- A prose status summary is not a valid plan artifact.
- New implementation plans should be execution-grade task catalogs, not prose-only checklists.
- Serial execution is the default planning posture.
- Parallel work must be named, dependency-frozen, and human-approved.
- Mandatory review happens before the human approval gate.
- The upstream design should already be `approval_status: approved` before planning starts.
- Review and verification requirements must be part of the plan, not implied later.
- Behavior-changing tasks should declare the failing test, narrow reproducer, or substitute verification evidence expected before implementation.
- Plan writers must not absorb every possible reviewer concern into the current milestone. Put out-of-scope concerns into `future_phase` or stop with `split_scope` / `needs_design_decision`.
- Each new task should declare enough metadata for task-ledger execution, including `task_id`, `depends_on`, `scope_slice`, task-scoped file refs, `verification_scope`, `executor_mode`, `task_review_depth`, `done_when`, and `rollback_on_failure`.
- Legacy plans may remain readable in compatibility mode during transition, but new plans should not rely on that fallback.
