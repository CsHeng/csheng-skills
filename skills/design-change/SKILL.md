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
2. Run decision discovery when the goal, terminology, acceptance boundary, owner, or non-goals are unclear.
3. Record the change class and required design strength.
4. Define scope, non-goals, approvals, and rollback surface.
5. Produce or update the design artifact in a stable, reviewable shape.
6. Validate the artifact before review.
7. Route the artifact through mandatory design review and bounded in-scope autofix when needed.
8. Hold the artifact at `approval_status: pending` until explicit human design approval.
9. Stop after explicit human design approval and hand off to `plan-change`.

## Decision Discovery

Use this as a bounded clarification loop, not as a competing top-level workflow.

Run decision discovery when any of these are true:
- the user cannot state concrete acceptance conditions yet
- the proposed plan would require guessing architecture intent
- the change mixes multiple milestones or future phases
- terminology is unstable enough that reviewers may argue over words instead of behavior
- a reviewer finds baseline mismatch, scope expansion, or repeated out-of-scope issues

Decision discovery must produce:
- the chosen milestone objective
- explicit non-goals and future-phase items
- unresolved decisions that block planning
- shared terms that downstream plans and reviews should use
- a stop state: `ready_for_plan`, `needs_more_design`, `split_scope`, or `manual_checkpoint`

Do not continue to `plan-change` when decision discovery ends in anything other than `ready_for_plan`.

## Operating Rules

- This is a top-level harness entry, not a lower-plane guideline.
- Design strength follows truth impact and boundary impact, not task size.
- A design file update alone is not completion.
- Mandatory review happens before the human approval gate.
- The artifact should carry explicit approval state, not just an approval reminder.
- Human approval is required before leaving this phase.
- `design-full` is not the default answer for every change.
- Decision discovery may clarify scope, but it must not start planning, execution, or review-batch repair.
- When the user explicitly asks to grill, stress-test, harden, challenge, or interrogate a design or plan, read `references/stress-test-mode.md`.
