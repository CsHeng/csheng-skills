---
name: review-change
description: "Use as the top-level agent-native review gate for design, plan, or implementation artifacts. Builds a bounded review brief, prefers subagent review when useful, adjudicates candidate findings, and returns one lifecycle verdict."
---

# Review Change

Run a bounded review and keep final judgment with the main agent.

## Use This Skill When

- a design, plan, or implementation needs a lifecycle review gate
- the main agent must decide whether candidate findings justify repair or a typed stop
- direct user review needs a bounded artifact-specific evaluator

## Actor Selection

The review brief distinguishes the `main` actor from a `delegated` reviewer.

1. Declare `actor_role: main` before choosing the review path.
2. Prefer one reviewer subagent for a non-trivial review when delegation is available and the approved task slice is stable.
3. Review directly when the change is small or mechanical, delegation is unavailable, or spawning would add no useful independence.
4. Give a reviewer subagent only the bounded review brief, not the full conversation or an invitation to audit the repository.
5. A delegated reviewer runs with `actor_role: delegated` and must not delegate recursively.

## Bounded Review Brief

The main agent constructs:

- artifact class and current task-slice objective
- approved goals, non-goals, and acceptance criteria
- exact artifact diff or changed files
- declared executable oracles and current verification evidence
- approved touch set
- explicitly allowed supporting files, each with a reason

Route the brief to `review-design`, `review-plan`, or `review-implementation`. The evaluator returns candidate evidence only.

## Main-Agent Adjudication

For every material candidate, verify the evidence, causal connection, approved-contract violation, confidence, consequence, and smallest in-scope fix. Assign exactly one disposition:

- `accepted`
- `rejected_no_causal_link`
- `rejected_pre_existing`
- `rejected_out_of_scope`
- `rejected_insufficient_evidence`
- `deferred_followup`
- `needs_plan_change`

Severity and reviewer-recommended scope never authorize repair by themselves. Only `accepted` candidates can become local repair work. Record a concise reason for each accepted candidate and each materially rejected candidate.

## Verdicts

- `pass`: no accepted candidate remains and required verification is sufficient
- `needs-fixes`: accepted findings have a smallest fix inside the approved task slice
- `manual-decision-required`: evidence requires authority, external verification, or an out-of-scope decision
- `split-scope`: the current milestone cannot remain one bounded review surface
- `needs-design-decision`: architecture intent must change
- `needs-plan-change`: the approved task graph, acceptance contract, or touch set is insufficient

## Operating Rules

- Review and verification are separate evidence sources combined by the lifecycle controller.
- Evaluators never mutate files or decide continuation.
- Pre-existing, unrelated, future-phase, adjacent, and low-confidence findings do not block the current change.
- A critical out-of-scope security or data-loss observation may force a manual decision but never silently expands repair scope.
- Prefer PASS when the bounded task acceptance and declared oracles are satisfied.
- Return the machine-checkable verdict directly; do not ask whether to continue when the state is known.
