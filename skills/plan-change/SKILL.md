---
name: plan-change
description: "Use when an approved change definition must be compiled into task order, dependencies, verification commands, and rollback triggers before execution starts. Activates for: plan change, implementation plan, task DAG, dependency freeze, 规划变更, 实现计划。"
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
2. Break the work into ordered tasks with explicit dependencies.
3. Define touched files, verification commands, and rollback triggers.
4. Mark any future parallel-safe batch explicitly; otherwise keep the plan serial.
5. Stop after explicit human plan approval and hand off to `execute-change`.

## Operating Rules

- This is a top-level harness entry.
- Serial execution is the default planning posture.
- Parallel work must be named, dependency-frozen, and human-approved.
- Review and verification requirements must be part of the plan, not implied later.
