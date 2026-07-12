# Implementation Repair Loop

## Ownership

`implement-change` owns mutation, candidate adjudication, continuation, and exit decisions. Review gates and evaluators provide evidence only.

## States

1. `implement`: apply the approved task slice.
2. `verify`: run affected and declared executable oracles.
3. `review`: provide a bounded review brief and collect candidate findings.
4. `classify`: assign a main-agent disposition to every material candidate.
5. `diagnose`: form a root-cause hypothesis for the complete accepted batch.
6. `repair`: fix only accepted findings inside the approved touch set.

## Candidate Adjudication

The controller assigns one of:

- `accepted`
- `rejected_no_causal_link`
- `rejected_pre_existing`
- `rejected_out_of_scope`
- `rejected_insufficient_evidence`
- `deferred_followup`
- `needs_plan_change`

Only `accepted` enters `diagnose` and `repair`. Severity and reviewer recommendation are evidence, not authority.

## Review Pass Contract

The normal path is:

1. initial bounded review of the approved task slice
2. one batched repair of all accepted findings
3. affected and declared verification
4. focused verification review of accepted findings and repair-introduced regressions

Focused verification is not a fresh exhaustive review. It cannot reopen repository-wide discovery, future plan phases, pre-existing debt, or general hardening.

One additional same-slice repair attempt is allowed only when focused verification proves that the accepted repair is incomplete or introduced a regression. Repetition after that exits `non-convergent`. Plan, design, authority, scope, external-evidence, or rollback boundaries exit immediately with the matching typed state.

## Typed Exits

- `pass`: bounded review and declared verification pass
- `replan`: approved task graph or touch set is insufficient
- `redesign`: approved architecture boundary is invalid
- `needs-authority`: repair requires new user authority or external decision
- `rollback`: safe forward repair is unavailable or a rollback trigger fired
- `non-convergent`: focused same-slice repair did not converge

Never convert pre-existing, unrelated, future-phase, plan-expanding, or insufficient-evidence observations into local edits.
