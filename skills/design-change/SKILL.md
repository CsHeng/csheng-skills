---
name: design-change
description: "Use when a change request needs truth-impact or boundary-impact classification before planning or execution, including explicit choice between `no-design`, `design-lite`, and `design-full`. Activates for: design change, change design, scope change, truth impact, boundary impact, 设计变更, 变更设计。"
---

# Design Change

Define the change boundary before planning or implementation.

## Use This Skill When

- the user wants to shape a new change before work starts
- the request may affect stable truth, public boundaries, or operating semantics
- the harness must decide between `no-design`, `design-lite`, or `design-full`
- the user needs explicit non-goals, change boundaries, or approval points

## Do Not Use This Skill When

- the user only wants read-only project explanation; use `analyze-project`
- an approved design already exists and the next step is planning
- the task is already in review, truth sync, or close

## Workflow

1. Classify the request for truth impact and boundary impact.
2. Record the change class and required design strength.
3. Define scope, non-goals, approvals, and rollback surface.
4. Produce or update the design artifact only when the classification requires it.
5. Stop after explicit human design approval and hand off to `plan-change`.

## Operating Rules

- This is a top-level harness entry, not a lower-plane guideline.
- Design strength follows truth impact and boundary impact, not task size.
- Human approval is required before leaving this phase.
- `design-full` is not the default answer for every change.
