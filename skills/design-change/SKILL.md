---
name: design-change
description: "Use before planning implementation to classify change scope, truth impact, boundary impact, and no-design/design-lite/design-full depth."
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
4. Produce or update the design artifact in a stable, reviewable shape.
5. Validate the artifact before review.
6. Route the artifact through mandatory design review and bounded in-scope autofix when needed.
7. Hold the artifact at `approval_status: pending` until explicit human design approval.
8. Stop after explicit human design approval and hand off to `plan-change`.

## Operating Rules

- This is a top-level harness entry, not a lower-plane guideline.
- Design strength follows truth impact and boundary impact, not task size.
- A design file update alone is not completion.
- Mandatory review happens before the human approval gate.
- The artifact should carry explicit approval state, not just an approval reminder.
- Human approval is required before leaving this phase.
- `design-full` is not the default answer for every change.
- When the user explicitly asks to grill, stress-test, harden, challenge, or interrogate a design or plan, read `references/stress-test-mode.md`.
