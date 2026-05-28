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
3. Define touched files, verification commands, review depth, and rollback triggers for each task.
4. Mark any future parallel-safe batch explicitly; otherwise keep the plan serial.
5. Validate the plan artifact before review.
6. Route the artifact through mandatory plan review and bounded in-scope autofix when needed.
7. Hold the artifact at `approval_status: pending` until explicit human plan approval.
8. Stop after explicit human plan approval and hand off to `execute-change`.

## Operating Rules

- This is a top-level harness entry.
- A prose status summary is not a valid plan artifact.
- New implementation plans should be execution-grade task catalogs, not prose-only checklists.
- Serial execution is the default planning posture.
- Parallel work must be named, dependency-frozen, and human-approved.
- Mandatory review happens before the human approval gate.
- The upstream design should already be `approval_status: approved` before planning starts.
- Review and verification requirements must be part of the plan, not implied later.
- Each new task should declare enough metadata for task-ledger execution, including `task_id`, `depends_on`, `scope_slice`, task-scoped file refs, `verification_scope`, `executor_mode`, `task_review_depth`, `done_when`, and `rollback_on_failure`.
- Legacy plans may remain readable in compatibility mode during transition, but new plans should not rely on that fallback.
