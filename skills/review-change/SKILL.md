---
name: review-change
description: "Use as the top-level review gate for design, plan, or code artifacts; normalizes lower-plane review results into one verdict."
---

# Review Change

Run the review gate for the current change phase and return one normalized harness verdict.

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
2. Validate the review target before any lower-plane review starts.
3. Route to `review-design`, `review-plan`, or `review-implementation`.
4. Collect the lower-plane review output and normalize the verdict.
5. Apply the review budget and stop-state policy.
6. Return a gate result that either advances, requires fixes, or stops for manual decision.

## Target Validation

- For plan review, require `design_ref` and `design_version` before invoking lower-plane reviewers.
- For implementation review against a plan, validate the plan path and upstream design linkage first.
- If a legacy artifact lacks required linkage, stop with an artifact-upgrade recommendation instead of running an under-scoped review.

## Budget And Stop States

Default review budget:
- design/plan: `1` round per batch and `2` batches per artifact
- implementation: expected convergence metadata `5` rounds with hard limit `10`; `implement-change` owns the actual repair loop

For design and plan artifacts, do not start a new batch merely because the user says "go" or "review again". Batch 2 still requires explicit next-batch approval. Implementation rounds are caller metadata for `implement-change`; this gate never edits implementation or owns continuation.

Normalize lower-plane findings into these decisions:
- `pass`: advance to the next harness gate
- `needs-fixes`: only in-scope blocking fixes remain within the current batch
- `manual-decision-required`: baseline mismatch, out-of-DAG scope, external verification dependency, exhausted budget, or repeated disagreement
- `split-scope`: the plan is too broad for one milestone
- `needs-design-decision`: the artifact asks review to resolve architecture intent

## Operating Rules

- This is the top-level review gate.
- `review-design`, `review-plan`, and `review-implementation` are lower-plane evaluators.
- Lower-plane evaluators return evidence only and must not invoke this gate, invoke `implement-change`, or mutate implementation.
- Review and verification are separate gates.
- Completion judgment stays with the harness, not the evaluator.
- Review is same-driver by design. This repository does not route review work across different LLM providers or harnesses; external review reports may be attached only as passive evidence.
- Review feedback is not automatically correct. Verify each blocking finding against the artifact and approved scope before applying fixes; push back or stop for manual decision when feedback conflicts with repo truth or approved boundaries.
- When the gate result is already machine-checkable, report that state directly instead of asking whether to continue.
- Review must not expand the active milestone to satisfy future-phase concerns.
