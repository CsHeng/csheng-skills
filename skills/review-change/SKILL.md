---
name: review-change
description: "Use when the harness needs one review gate for a design, plan, or code artifact and must normalize lower-plane review output into a single verdict. Activates for: review change, review gate, design review gate, plan review gate, code review gate, 审查变更, 评审闸门。"
---

# Review Change

Run the review gate for the current change phase.

## Use This Skill When

- the harness needs one review entry regardless of artifact type
- the current artifact is a design, plan, or implementation result
- the change needs a normalized review verdict before verify, truth sync, or close

## Do Not Use This Skill When

- the request is still defining scope or building the plan
- the user only wants direct invocation of lower-plane review skills without harness routing
- the task is only truth sync or close

## Workflow

1. Identify the current artifact class and phase.
2. Route to `review-design`, `review-plan`, or `review-code-impl`.
3. Collect the lower-plane review output and normalize the verdict.
4. Return a gate result that either advances, requires fixes, or rolls back phase.

## Operating Rules

- This is the top-level review gate.
- `review-design`, `review-plan`, and `review-code-impl` are lower-plane evaluators.
- Review and verification are separate gates.
- Completion judgment stays with the harness, not the evaluator.
