---
name: review-plan
description: "Review implementation plans against an approved design, executable task DAG, bounded scope, verification, rollback, and execution continuity using an agent-native bounded review brief. Return candidate findings only."
---

# Review Implementation Plan

Decide whether the supplied current-milestone plan can safely enter execution. Do not review future phases or implementation details outside the plan gate.

## Actor Contract

- Prefer a reviewer subagent for a non-trivial plan when the main agent can delegate.
- Permit direct main-agent review for small plans or when delegation is unavailable.
- The bounded review brief declares `actor_role: main | delegated`.
- A delegated reviewer must not delegate recursively, edit the plan, call lifecycle controllers, or authorize repairs.

## Bounded Review Brief

Require:

- plan path, current milestone objective, and exact changed plan sections or diff
- approved upstream `design_ref` and `design_version`
- approved scope, non-goals, future phase, and implementation surface
- task DAG and dependency state
- acceptance oracles, rollback triggers, and execution-continuity declarations
- the approved architecture decision reference, reversible staging, and upgrade triggers when the upstream design carries architecture economics
- explicitly allowed supporting files, each with a reason

Read the upstream design first, then the plan. Read no other files unless the brief names them or they are direct dependencies required to validate a changed plan claim. Do not inspect implementation code to invent plan requirements.

## Review Concerns

- one executable milestone objective with explicit non-goals
- scope contained by the approved design
- dependency-complete task order and ownership
- executable oracle or declared substitute for behavior-changing tasks
- rollback and authority boundaries
- `Work Package Readiness` and `Execution Continuity` consistency
- fidelity to the approved architecture decision, including bounded reversible staging and preserved upgrade triggers

Do not rerun or rescore architecture selection. If the plan changes the approved demand, constraint, owner, hard requirement, chosen boundary, or upgrade trigger, return a design-decision candidate rather than treating the change as local plan repair.

Do not block on exact command flags, fixture contents, dashboard details, cleanup polish, or low-level decisions that can be made inside an approved task without changing its boundary.

## Candidate Finding Contract

Each material candidate includes:

- `location`, `evidence`, and concrete `impact`
- `causal_class`: `introduced_by_change | regressed_by_change | activated_by_change | pre_existing | unrelated`
- `violated_contract`: the exact approved design, readiness, DAG, oracle, rollback, or continuity rule
- `confidence`: `high | medium | low`
- `smallest_fix`
- `recommended_disposition`

Only causally linked, high-confidence defects that prevent executing the current milestone are eligible blockers. Future-phase concerns, implementation-level hardening, pre-existing debt, unrelated observations, and low-confidence suggestions are non-blocking. If the plan requires a design, authority, or scope change, return a manual decision candidate instead of inventing a local repair.

Prefer PASS when the plan has a bounded executable DAG, sufficient oracles, correct ownership, rollback, and explicit execution continuity.

## Output

Return:

- `verdict: pass | candidate-findings | manual-decision-required`
- `review_surface` with reasons for supporting files
- `candidate_findings`
- `pass_rationale` when passing

The main agent adjudicates candidate findings and owns any plan repair.
