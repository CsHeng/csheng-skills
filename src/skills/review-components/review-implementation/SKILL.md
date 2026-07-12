---
name: review-implementation
description: "Review an implementation diff against the approved task slice using a bounded agent-native review brief, change causality, and executable evidence. Return candidate findings only; lifecycle controllers own adjudication and repair."
---

# Review Implementation

Judge whether the supplied diff correctly implements the approved task slice. Do not audit the repository.

## Actor Contract

- The main agent should prefer a reviewer subagent for non-trivial implementation review when delegation is available.
- The main agent may review directly for a small mechanical diff or when delegation is unavailable.
- The bounded review brief declares `actor_role: main | delegated`.
- A delegated reviewer must not delegate recursively, edit files, call lifecycle workflows, or authorize repair.

## Bounded Review Brief

Require:

- approved task-slice objective and non-goals
- acceptance criteria, invariants, and executable oracles
- exact changed files and diff for the task slice
- task-scoped tests and verification evidence
- approved touch set
- a small supporting-file allowlist, with one reason per file

Review changed behavior and the supplied tests. Read an unchanged file only when it is a direct dependency of changed behavior and is necessary to decide whether the diff is correct. Record that reason in `review_surface`. Do not follow references recursively, inspect future plan tasks, or search the repository for adjacent debt.

## Causality

Classify every material candidate:

- `introduced_by_change`: the current diff creates the defect
- `regressed_by_change`: the current diff breaks previously correct behavior
- `activated_by_change`: the diff newly places pre-existing behavior on the approved active path
- `pre_existing`: the issue existed and the diff neither worsens nor activates it
- `unrelated`: the observation is not caused by the task slice

Only the first three classes are eligible for current repair. `activated_by_change` requires evidence that the diff newly executes, exposes, or relies on the behavior. Moving, renaming, formatting, archiving, or relabeling unchanged code does not itself activate pre-existing defects.

## Blocking Eligibility

A candidate is eligible to block only when it:

- is inside the bounded review surface
- has qualifying causality tied to a changed line or behavior
- violates a named task requirement, acceptance criterion, invariant, or oracle
- has a concrete material consequence
- has sufficient evidence and confidence
- has a smallest valid fix inside the approved task slice and touch set

Low-confidence findings never authorize automatic repair. Pre-existing, unrelated, future-phase, general-hardening, stylistic, and plan-expanding concerns are non-blocking and should normally be omitted. A critical incidental security or data-loss observation outside scope may be escalated to the main agent, but it must not be labeled current-scope repair.

Prefer PASS when the approved behavior and declared oracles are satisfied. Do not report possible issues merely to be defensive, and do not optimize for exhaustive finding discovery.

## Candidate Output

Return:

- `verdict: pass | candidate-findings | manual-decision-required`
- `review_surface`: every file read and why
- `candidate_findings`, each with `location`, `evidence`, `impact`, `causal_class`, `violated_contract`, `confidence`, `smallest_fix`, and `recommended_disposition`
- `pass_rationale` when passing

Candidate findings are advisory evidence. The main agent independently assigns their final disposition and only the lifecycle controller may repair accepted findings.
