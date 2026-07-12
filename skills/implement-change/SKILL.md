---
name: implement-change
description: "Implement an approved plan end to end with serial tasks, executable oracles, bounded agent-native review, main-agent finding adjudication, focused repair verification, rollback, truth sync, and close routing."
---

# Implement Change

Run an approved plan as one lifecycle unit and keep control until the next typed boundary.

## Use This Skill When

- the user approved a plan and wants it implemented
- the harness must drive task execution, verification, bounded review, repair, and closeout
- the plan defines a serial path or explicitly approved parallel batch

## Runtime Contract

Before implementation, read completely:

- `references/workflow.toml`
- `references/repair-loop.md`

Resolve both relative to this `SKILL.md`. The cross-skill graph stays acyclic; repair is internal controller state.

## Workflow

1. Confirm plan approval, dependency state, execution continuity, and current checkout/worktree decision.
2. Execute ready tasks serially unless the plan explicitly approves a dependency-frozen parallel batch.
3. Maintain a task ledger rather than relying on conversation memory.
4. Run the task's narrow and declared executable oracles.
5. Construct a bounded review brief containing only the approved task slice, exact diff, tests, verification evidence, touch set, and justified supporting files.
6. Route the brief through `review-change`; prefer a reviewer subagent for non-trivial review and permit direct main-agent review for small mechanical changes.
7. Independently adjudicate every material candidate and assign the final disposition.
8. Repair only findings with disposition `accepted`, batching the complete accepted set inside the approved touch set.
9. Rerun affected and declared verification, then perform focused verification review of accepted findings and repair-introduced regressions.
10. Route final evidence to `sync-truth`, `close-change`, or a typed stop.

## Repair Ownership

- This skill is the only implementation repair owner.
- Reviewers return candidate evidence; they do not edit, continue, or decide scope.
- Severity, reviewer confidence, or a reviewer scope label is never sufficient repair authority.
- Only `accepted` findings may be repaired.
- `pre_existing`, `unrelated`, low-confidence, out-of-scope, and future-phase findings never enter local repair.
- One initial bounded review and one focused verification review are the normal path.
- One additional repair attempt is allowed only when focused verification proves the accepted repair is incomplete or introduced a regression in the same bounded slice.
- A repeated finding after that, scope expansion, plan/design change, new authority, or unavailable external evidence exits with the matching typed state instead of more edits.

## Execution Continuity

- `continuous_after_plan_approval`: continue without new questions unless a declared runtime contingency is observed.
- `pre_confirmation_required`: resolve the named `C*` items before mutation.
- `not_ready`: stop and route to the declared design or plan entry.
- Runtime contingencies are reactive evidence conditions, not routine checkpoints.
- Do not reopen plan-approved decisions unless live evidence contradicts the plan.

## Resume And Completion

- After interruption or compaction, recheck the latest user request, task ledger, worktree, and last completed write/deploy step.
- Verification does not imply that a write, install, deploy, commit, or push completed.
- Treat delegated review output as a claim to adjudicate, not an authoritative instruction.
- Do not claim completion without fresh verification from the current execution turn.

## Operating Rules

- Serial-first and no unattended expansion are defaults.
- The approved plan is the atomic execution unit; do not stop while ready in-scope tasks remain.
- Prefer red-green or a narrow reproducer for non-trivial behavior changes.
- Diagnose reproducible root cause before repair.
- Never allow a delegated reviewer to delegate recursively or invoke this controller.
- Report known gate states directly instead of hedging or asking whether to continue.
