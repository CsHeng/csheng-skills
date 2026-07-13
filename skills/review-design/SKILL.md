---
name: review-design
description: "Review design documents against approved goals, non-goals, architecture boundaries, risks, and acceptance criteria using a bounded agent-native review brief. Return candidate findings only; the main agent owns adjudication and repair."
---

# Review Design

Decide whether the supplied design can safely enter planning. Review the approved design slice, not the repository as a whole.

## Actor Contract

- The main agent prefers a reviewer subagent for a non-trivial design review when delegation is available.
- The main agent may review directly when the artifact is small, mechanical, or delegation is unavailable.
- The bounded review brief declares `actor_role: main | delegated`.
- A delegated reviewer must not delegate recursively, mutate files, invoke lifecycle controllers, or authorize repair.

## Bounded Review Brief

Require the main agent to supply:

- design path and approved objective
- explicit goals, non-goals, and current milestone
- acceptance conditions and implementation-surface requirements
- exact changed design sections or diff
- explicitly allowed supporting documents, each with a reason

Read only the design, the named supporting documents, and the minimum root guidance needed to interpret them. Do not search the repository for additional requirements. An unchanged document may be read only when it is a direct design dependency and is necessary to judge the changed boundary.

## Review Concerns

- goals, non-goals, and milestone scope
- architecture ownership and dependency direction
- durable truth and implementation-surface boundaries
- material rollout, rollback, and operability risks needed before planning
- acceptance conditions that make downstream planning reviewable

When the design activates architecture economics, also review:

- demand-complexity fit and the constrained resource or hard requirement
- the status quo, smallest sufficient option, and structural investment with material discard reasons
- owner-cost alignment, including shifted operational cost and cleanup responsibility
- an executable oracle, rollback boundary, and observable upgrade trigger

Do not require numeric scoring or block on uncertain financial estimates. Block only when missing causal evidence makes the selected persisted boundary unsafe, unjustified, or unreviewable.

Do not block on task ordering, command flags, fixture contents, field parity, cleanup polish, or code-level hardening unless the omission makes the design boundary unsafe or unreviewable.

## Candidate Finding Contract

Return only evidence-backed candidate findings. Each material candidate includes:

- `location`
- `evidence`
- `impact`
- `causal_class`: `introduced_by_change | regressed_by_change | activated_by_change | pre_existing | unrelated`
- `violated_contract`: the exact approved goal, boundary, acceptance condition, or invariant
- `confidence`: `high | medium | low`
- `smallest_fix`
- `recommended_disposition`

Only `introduced_by_change`, `regressed_by_change`, and narrowly proven `activated_by_change` can be recommended as blocking. Low-confidence, pre-existing, unrelated, future-phase, general-hardening, or plan-expanding concerns are not current blockers and should normally be omitted. A material out-of-scope security or data-loss concern may be escalated as evidence, but it never authorizes design mutation.

Prefer PASS when the bounded design satisfies its goals, boundaries, acceptance conditions, and downstream implementation-surface contract. Do not optimize for the number of findings.

## Output

Return:

- `verdict: pass | candidate-findings | manual-decision-required`
- `review_surface`: files and sections actually read, including the reason for every supporting file
- `candidate_findings`
- `pass_rationale` when passing

The main agent adjudicates every material candidate before any repair.
