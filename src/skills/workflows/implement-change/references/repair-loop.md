# Implementation Repair Loop

## Ownership

`implement-change` is the only owner of implementation repair state, mutation, continuation, and exit decisions. `review-change` normalizes review results and `review-implementation` supplies evidence; neither reviewer mutates implementation or calls back into the controller.

## States

1. `implement`: apply only the current approved plan slice.
2. `verify`: run the affected narrow oracle and the task's declared verification scope.
3. `review`: request a fresh complete implementation review through `review-change`.
4. `classify`: map every blocking finding to local repair, replan, redesign, authority, external verification, or rollback.
5. `diagnose`: form a new root-cause hypothesis when evidence repeats or expands.
6. `repair`: fix the complete accepted in-scope finding batch inside the allowed touch set, then return to `verify`.

The cross-skill invocation graph stays acyclic. The `repair -> verify` transition is internal controller state, not a call from a reviewer to the controller.

## Round Contract

One round consists of:

1. one complete implementation review
2. classification of the complete finding set
3. one batched repair for all accepted `in_scope_blocking` findings
4. affected and declared verification
5. a fresh complete review

Expected convergence is five rounds. Continue beyond five when scope remains approved and oracle evidence is improving. Ten rounds is the hard safety limit; reaching it without PASS exits as `non-convergent` with the remaining evidence.

## Progress And Repetition

- Treat fewer findings, lower severity, passing additional oracles, or a narrower reproducer as progress.
- A repeated finding enters `diagnose`; do not apply the same patch hypothesis again.
- New findings caused by a repair must be classified with the full current batch.
- Non-monotonic finding growth requires reclassification before more edits.

## Typed Exits

- `pass`: review and verification pass; route to truth sync or close.
- `replan`: the approved task graph or touch set is insufficient.
- `redesign`: architecture intent or an approved boundary is invalid.
- `needs-authority`: repair requires a user decision or broader authorization.
- `rollback`: a declared rollback trigger fires or safe forward repair is unavailable.
- `non-convergent`: ten rounds complete without a verified pass.

Never convert plan, design, authority, or rollback findings into local code edits.
