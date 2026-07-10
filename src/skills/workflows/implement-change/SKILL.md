---
name: implement-change
description: "Implement an approved plan or design end to end with serial tasks, verification, controller-owned repair convergence, review gates, rollback, truth sync, and close routing. Use as the single lifecycle controller whenever the user asks to execute, implement, deliver, or repair an already approved change, including small plan-bound changes; do not use for read-only review."
---

# Implement Change

Run an approved plan as one lifecycle unit and keep control until the next typed boundary.

## Use This Skill When

- the user wants implementation work against an approved plan
- the harness must drive task execution, convergence, repair, review, and verification
- the change has a declared serial path or an explicitly approved parallel batch

## Do Not Use This Skill When

- the request still needs design or plan approval
- the user only wants a read-only review
- the task is only truth sync or close

## Runtime Contract

Before implementation, read these files completely:

- `references/workflow.toml` for the installed invocation DAG, roles, allowed calls, and loop ownership
- `references/repair-loop.md` for repair states, finding classification, convergence rules, and typed exits

Resolve both paths relative to the directory containing this `SKILL.md`, not relative to the shared skills root or target repository.

Treat the cross-skill invocation graph as acyclic. Repair is an internal state transition owned by this skill, not a reverse call from a reviewer.

## Workflow

1. Confirm the approved plan, dependency state, and current phase.
2. Read `## Execution Continuity` if present and resolve whether execution is continuous, pre-confirmation-blocked, or not ready.
3. Run a one-time worktree preflight before the first code mutation when execution starts in the current checkout.
4. Execute ready tasks serially unless the plan defines a human-approved parallel batch.
5. Keep progress in a task-level execution ledger instead of relying on chat memory alone.
6. After each task slice, run its executable oracles, then route the implementation through `review-change`.
7. Classify the normalized review result as `pass`, `local-repair`, `replan`, `redesign`, `needs-authority`, or `rollback`.
8. For `local-repair`, batch all current in-scope blocking findings, diagnose their root causes, repair only the approved touch set, rerun verification, and request a fresh complete review.
9. Continue the controller-owned repair loop while the work remains in scope and evidence is converging.
10. Normalize final review and verification into `sync-truth`, `close-change`, or a typed stop state.

## Repair Ownership

- This skill is the only implementation repair-loop owner.
- `review-change` and `review-implementation` return evidence and verdicts; they do not edit implementation, re-enter this controller, or decide lifecycle completion.
- The expected convergence budget is 5 review-repair rounds.
- The hard safety limit is 10 rounds. Reaching round 5 does not stop a converging loop.
- A repeated finding enters root-cause diagnosis before another repair attempt.
- Plan, design, authority, scope, or rollback boundary changes stop the current loop immediately with the matching typed exit.
- One round fixes the complete accepted finding batch, reruns affected and declared verification, and then performs a fresh full review.

## Execution Continuity Handling

Use the plan's `## Execution Continuity` section as the execution contract.

- If `execution_mode: continuous_after_plan_approval`, execute the approved plan without asking more human questions unless a declared `runtime_contingency` is triggered by observed evidence.
- If any `confirmation_clearance` item has `resolution: needs_confirmation_before_execution`, stop before the first mutation and ask the exact `C*` question(s). Do not partially execute low-risk tasks unless the plan explicitly separates them from the blocked task range.
- If a `confirmation_clearance` item is `pre_confirmed`, do not ask again; record it in the execution ledger when its task range is reached.
- If `execution_mode: not_ready`, stop and route back to `plan-change` or `design-change` as declared by the plan.
- Treat `runtime_contingencies` as reactive stop conditions only. They do not block normal execution until the declared trigger is actually observed.
- Legacy plans without `## Execution Continuity` may be executed in compatibility mode, but if a known human decision appears during preflight, stop before mutation and route the missing clearance back to `plan-change`.

## Resume And Completion Gates

- After interruption, compaction, rollback, or resumed execution, re-check the latest user request, the current ledger state, and the last completed write/install/deploy command before continuing.
- Verification passing does not imply that an install, deploy, write, or commit step completed. Record those as complete only after their own command succeeds.
- If execution stopped after verification but before the requested write/install/deploy step, report the incomplete step instead of declaring the change done.
- Do not claim completion, pass status, fixed status, or readiness without fresh verification evidence from the current execution turn.
- Treat delegated-agent success reports as claims to verify with local diff, review output, or command evidence before advancing the harness gate.

## Operating Rules

- This is a top-level harness entry.
- Serial-first is the default.
- No unattended execution is the default.
- Parallel execution requires explicit human approval after dependency freeze.
- The approved plan is the atomic execution unit for this entry.
- Do not stop mid-plan merely because one task completed while another ready task remains.
- Do not re-open plan-approved or pre-confirmed decisions during execution unless live evidence contradicts the plan.
- Do not convert known planning decisions into runtime contingencies; unresolved known decisions belong in `plan-change`.
- Task verification and task-scoped review happen before a task is marked done.
- For behavior changes, prefer red-green verification: create a failing test or narrow reproducer, confirm it fails for the expected reason, implement the smallest fix, then rerun the narrow and declared plan verification.
- For failures, identify the reproducible symptom and root cause before applying fixes; do not stack patches that lack a new hypothesis or measurable oracle progress.
- Never let a lower-plane evaluator call this skill, call itself, or mutate the repository.
- When the next state is already determined by review, verification, truth-sync, or rollback gates, report it directly instead of asking whether to continue.
