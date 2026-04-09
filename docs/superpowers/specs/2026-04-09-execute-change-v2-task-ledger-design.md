# Execute Change V2 Task-Ledger Design

## Status

- proposal_date: 2026-04-09
- approval_status: approved
- basis: interactive design discussion on `execute-change` progress control, task tracking, and execution completion behavior
- related_design:
  - docs/superpowers/specs/2026-04-06-sovereign-harness-kernel-v1-design.md

## Problem

The current sovereign kernel already has strong macro control:

- explicit top-level entries
- explicit phase transitions
- explicit approval boundaries
- explicit review and verification gates
- explicit rollback escalation

That macro control is not the current weakness.

The weakness is inside `execute-change`.

Today, the execution entry can validate an approved plan, derive an allowed touch set,
derive verification commands, and normalize review plus verification outcomes.
What it does not yet own is a task-level execution ledger.

That missing runtime object creates five practical failures:

1. Plan execution does not have a canonical answer to "what task is active now?"
2. Progress is inferred from conversational memory instead of a machine-checkable task ledger.
3. The agent is more likely to stop mid-plan and ask whether to continue, even though an approved plan should already be the current execution unit.
4. Review cadence is clear only at the full implementation gate, not during task-by-task execution.
5. The human-facing mental model is naturally `design -> plan -> execute`, while the current execution experience still feels like generic change handling without fine-grained execution state.

This is why the current harness can produce acceptable completion quality on some runs but still feels less controllable and less self-propelling than a stronger task-loop harness such as Superpowers.

## Goals

- Make an approved plan the default atomic execution unit.
- Introduce a task ledger that tells the harness what is done, active, blocked, and remaining.
- Make `execute-change` continue automatically until a real gate or stop condition is reached.
- Improve human progress perception during execution without weakening the sovereign kernel.
- Add a default one-time worktree reminder before implementation starts when execution is about to happen in the current checkout.
- Preserve the seven top-level kernel entries as the only top-level authority.
- Keep serial-first execution as the default posture.
- Add a task-level execute/review micro-loop without collapsing the final converge/review/verify gates.
- Express the human-facing workflow more naturally as `design -> plan -> execute` while keeping `*-change` as the kernel authority names.

## Non-Goals

- Do not rename or replace the seven top-level kernel entries.
- Do not introduce a second top-level harness authority.
- Do not require full heavy `review-code-impl` repair loops after every tiny task by default.
- Do not enable unattended parallel execution by default.
- Do not add a central artifact registry or external execution database.
- Do not weaken human approval at design, plan, truth-sync, or close.
- Do not force worktree usage when the user explicitly chooses to continue in the current checkout.

## Change Classification

- request_kind: change-definition
- change_class: C
- design_strength: design-full
- truth_impact: medium
- boundary_impact: high
- recommended_next_phase: plan

## Decision Summary

`execute-change v2` keeps the current sovereign kernel and adds a lower-plane task-ledger execution loop.

The V2 execution model is:

1. `design-change` defines boundaries.
2. `plan-change` emits a granular task catalog that is executable as a ledger.
3. `execute-change` performs a one-time worktree preflight before the first code mutation.
4. `execute-change` materializes a runtime task ledger from the approved plan.
5. The harness executes one ready task at a time, with task verification and task review before that task becomes done.
6. The harness does not return control to the human merely because one task or one informal step completed.
7. The harness returns control only at a real gate:
   - blocker requiring human input
   - rollback or re-plan requirement
   - final converge/review/verify decision
   - truth-sync or close boundary

This preserves the current macro kernel while importing the most useful micro-loop property from Superpowers: explicit task progress with deterministic continuation until the plan unit is exhausted or blocked.

## Human-Facing Mental Model

The repository should keep the sovereign kernel names:

- `design-change`
- `plan-change`
- `execute-change`

But the recommended human-facing narrative should become:

- design
- plan
- execute

The rule is:

- `change` remains the kernel and policy term
- `design / plan / execute` becomes the presentation and progress term

This keeps the architecture stable while matching how humans naturally think about the workflow.

## Runtime Model Extension

Kernel V1 stabilized six runtime objects.

`execute-change v2` adds three execution-local runtime objects:

- `task_catalog`
- `task_ledger`
- `execution_result`

### `task_catalog`

`task_catalog` is the immutable task definition extracted from the approved plan artifact.

It is the execution baseline and must not drift during the run.

Each task record should carry at least:

- `task_id`
- `title`
- `depends_on`
- `impl_file_refs`
- `test_file_refs`
- `verification_commands`
- `executor_mode`
- `task_review_depth`
- `done_when`
- `human_gate_required`

### `task_ledger`

`task_ledger` is the mutable runtime state for the current execution session.

It may live as a temp JSON sidecar or an equivalent machine-checkable runtime record, but it must remain reconstructable from the approved plan plus current run state.

Each ledger entry should carry at least:

- `task_id`
- `status`: `pending | ready | in_progress | in_review | blocked | done`
- `attempt_count`
- `review_attempt_count`
- `failure_count`
- `last_failure_kind`
- `active_impl_file_refs`
- `active_test_file_refs`
- `started_at`
- `completed_at`
- `notes`

The approved plan remains the immutable baseline.
The task ledger is the mutable progress state.
Execution must not mutate the approved plan artifact merely to track progress.

### `execution_result`

`execution_result` is the deterministic stop-state object returned by `execute-change`.

It should include:

- `execution_unit`: `plan`
- `plan_path`
- `current_phase`
- `active_task_id`
- `completed_task_count`
- `remaining_task_count`
- `stop_reason`
- `review_status`
- `verify_status`
- `next_entry`
- `next_phase`
- `human_input_required`

This object is the replacement for vague prose such as "should I continue?"

## Plan Contract Changes

`plan-change` must produce a task catalog that is fit for execution, not just a prose task list.

The plan remains markdown, but each task must become structurally predictable enough for the harness to materialize a task ledger without guesswork.

Each task should declare:

- `task_id`
- `depends_on`
- `scope_slice`
- `impl_file_refs`
- `test_file_refs`
- `verification_scope`
- `executor_mode`
- `task_review_depth`
- `done_when`
- `rollback_on_failure`

The key correction is:

- a plan is not only "ordered tasks"
- a plan is an executable task catalog with deterministic continuation rules

If a plan lacks these fields or stays too coarse to drive a task ledger, `plan-change` should treat that as plan incompleteness rather than allowing execution to guess.

## Execution Modes

`execute-change v2` should support these execution modes:

- `inline-serial`
- `fresh-subagent-per-task`
- `approved-parallel-batch` (future-safe, opt-in only)

Rules:

- `inline-serial` is the compatibility default.
- `fresh-subagent-per-task` is the preferred mode when the host supports subagents and the task is locally independent enough to isolate.
- `approved-parallel-batch` remains forbidden unless the plan explicitly freezes dependencies and the human explicitly approves that batch.

This keeps kernel sovereignty intact while allowing the task loop to become much stronger where subagent support exists.

## Worktree Preflight

Before the first implementation task starts, `execute-change` should perform a one-time workspace-isolation preflight.

Rules:

- If execution is already happening inside a repository-local feature worktree or another clearly isolated checkout, do not ask again.
- If execution is about to happen in the current primary checkout and no prior worktree decision is recorded for this run, remind the user that isolated worktree development is available.
- The reminder should point to the existing `git-worktrees` execution-support skill instead of inventing a new worktree workflow.
- If the user chooses worktree isolation, perform that transition before task execution starts.
- If the user declines, record that decision for the current run and continue without repeating the prompt mid-plan.

The worktree reminder is a start-of-execution preflight only.
It is not permission to keep interrupting execution after the plan has started.

## Execute Loop

The canonical V2 execute loop is:

1. Validate the approved plan.
2. Run the one-time worktree preflight.
3. Materialize `task_catalog`.
4. Materialize `task_ledger`.
5. Resolve the next ready task.
6. Execute only that task's approved scope.
7. Run task verification.
8. Run task review.
9. If the task passes, mark it `done`.
10. Continue to the next ready task automatically.
11. When all tasks are `done`, move to `converge`.
12. Run final `review-change`.
13. Run final verification.
14. Normalize into `sync-truth` or `close-change` as applicable.

The harness must not ask whether to continue while:

- the approved plan is still active
- a ready task exists
- no human gate is required
- no rollback or re-plan condition has been triggered

That behavior is not optional style.
It is the semantic consequence of treating the approved plan as the execution unit.

## Stop Conditions

`execute-change v2` should stop only for one of these reasons:

- `worktree_decision_required`
- `task_blocked_requires_human`
- `scope_violation_requires_replan`
- `rollback_required`
- `plan_incomplete`
- `final_review_failed`
- `final_verification_failed`
- `truth_sync_required`
- `ready_for_close`

It should not stop for:

- "one task completed"
- "some progress was made"
- "the next task is obvious but not yet started"
- "the model wants reassurance before continuing"

If the next state is still machine-determined, the harness should proceed.
If the next state is no longer machine-determined, the harness should stop with an explicit `execution_result`.

## Task Review Cadence

The execution micro-loop should distinguish task review from final implementation review.

### Main Loop Ownership

The primary lifecycle owner remains `execute-change`.

That means:

- task selection
- task progress tracking
- task completion judgment
- rollback escalation
- final converge/review/verify progression

all stay in the main execution loop rather than being delegated to `repair-review`.

`review-code-impl --repair-review` may remain available, but only as an optional bounded accelerator inside the broader `execute-change` lifecycle.
It must not become the sovereign execution loop.

### Task Review

Every task must run:

- narrow task verification
- task-scoped review

Default task review should use the existing review gate in a narrow form:

- route through `review-change`
- artifact class remains `code-impl`
- scope is restricted to the current task slice
- default depth is `quick`

Task review should answer:

- did this task match its scoped intent?
- did it introduce obvious correctness or quality problems?
- should the task be marked done?

If task review returns blocking findings:

- fix within the same task loop
- rerun narrow verification
- rerun narrow review

### Repair-Review Role

`repair-review` is useful when the main loop wants a bounded helper that:

- consumes the current plan baseline
- fixes a small set of `in_scope_blocking` findings
- returns a structured batch result

It is not responsible for:

- deciding what task comes next
- deciding whether the plan is complete
- deciding whether execution should continue overall

If the top-level execute loop is reliable, `repair-review` becomes optional rather than foundational.
That is acceptable and does not weaken the design.

### Escalated Task Review

Task review depth should escalate to `thorough` when the task touches higher-risk surfaces such as:

- public interfaces or command surfaces
- schema or data migrations
- security-sensitive paths
- multi-file coordination across boundaries
- changes that already failed one quick review round

### Final Review

Final implementation review remains mandatory and heavier than task review.

It should keep the existing macro gate behavior:

- converge the full implementation delta
- route through `review-change`
- use the full plan baseline
- use the normal code-implementation review path
- keep bounded repair rules and batch/round controls

This preserves the current strong evaluator plane while adding earlier, cheaper feedback loops.

## Review Scope Versus Repair Scope

Read scope and write scope should be separated explicitly.

### Read Scope

For both `review-only` and `repair-review`, reviewer read scope should be allowed to expand to the relevant plan or design surface so long as it stays within the current artifact lineage.

That means read scope may be wider than the exact repair set when needed to understand:

- surrounding runtime contracts
- nearby integration points
- sibling files inside the same stable module or directory surface
- targeted tests and verification context

This is the "wide enough to understand" boundary.

### Repair Scope

Repair scope remains bounded by `allowed_touch_set`.

That means automatic edits must still stay inside:

- `plan.impl_file_refs`
- `plan.test_file_refs`

This is the "narrow enough to trust" boundary.

### Surface Representation

The preferred representation is:

- stable file paths
- stable module paths
- stable directory-prefix surfaces

The design should not rely on arbitrary globs such as `backend/**`.

Stable directory or module surfaces are acceptable because they preserve auditability while avoiding the brittleness of exact-file-only review fences in larger repositories.

### Batch Return Semantics

When `repair-review` is used, each batch should return to the main execution context after:

- success
- `max_rounds` reached
- `manual_review_required`

The main execution loop then decides:

- continue with the next task
- rerun a task
- escalate to rollback or re-plan
- stop for a human gate

Human involvement is required only when a true manual gate has been reached.
Successful bounded repair batches do not require a new human confirmation by default.

## Failure And Rollback Semantics

Task-level looping does not replace rollback.
It makes rollback more accurate.

The harness should treat these as immediate upward stop conditions:

- touching files outside the approved task or plan surface
- repeated task verification failure
- repeated task review failure beyond local retry budget
- task dependency ambiguity
- ledger desynchronization between task state and approved plan

Preferred handling:

- local task fix when the failure is still clearly in-scope
- rollback to `implement-serial` or `dependency-freeze` when repeated task failures indicate unstable execution
- rollback to `plan` when the task catalog is too coarse, contradictory, or missing scope detail
- rollback to `design-lite` or `design-full` only when repeated failures indicate a boundary mistake rather than an execution mistake

## Progress Reporting

Human progress perception should become a first-class output of `execute-change`.

At minimum, execution updates should report:

- current workspace mode
- current task title
- completed task count
- remaining task count
- current review/verification state
- whether the run is still auto-continuing or waiting at a real gate

This is not a separate authority layer.
It is a user-visible projection of the task ledger.

The same ledger can drive:

- command output summaries
- in-session progress updates
- a future `TodoWrite` / `update_plan` mirror

## Boundaries

### In Scope

- strengthen `plan-change` so task structure is execution-grade
- strengthen `execute-change` so plan completion is deterministic
- add a default worktree reminder before first implementation
- add a task-ledger runtime helper
- add task-level review cadence
- improve user-facing progress semantics
- preserve final converge, review, verify, truth-sync, and close gates

### Out Of Scope

- renaming top-level kernel entries away from `*-change`
- replacing `review-change` with a new top-level reviewer
- per-task mandatory full repair-review with three-round cross-model loops
- unattended parallel execution by default
- external execution databases or long-lived orchestration services
- redesigning `skills/git-worktrees/SKILL.md` beyond reuse of its current workflow

## Human Gate

- approval_required: true
- approval_status: approved
- next_entry: plan-change

## Implementation Surface

- impl_file_refs:
  - skills/plan-change/SKILL.md
  - skills/execute-change/SKILL.md
  - skills/review-code-impl/SKILL.md
  - skills/review-code-impl/references/workflow-details.md
  - commands/execute-change.md
  - README.md
  - AGENTS.md
  - skills/_harness-libs/plan-runner.sh
  - skills/_harness-libs/execute-runner.sh
  - skills/_harness-libs/phase-engine.sh
  - skills/_harness-libs/contracts.sh
  - skills/_harness-libs/task-ledger.sh
  - skills/_review-libs/artifact-dag.sh
  - skills/_review-libs/run-review.sh
  - skills/_review-libs/workspace.sh
- test_file_refs:
  - skills/_harness-libs/smoke-test/test-plan-runner.sh
  - skills/_harness-libs/smoke-test/test-execute-runner.sh
  - skills/_harness-libs/smoke-test/test-review-execute-command-control.sh
  - skills/_harness-libs/smoke-test/test-task-ledger.sh
  - skills/_review-libs/smoke-test/test-artifact-dag.sh
- out_of_scope_file_refs:
  - skills/_review-libs/drivers/claude.sh
  - skills/_review-libs/drivers/codex.sh
  - skills/_review-libs/drivers/gemini.sh
  - skills/_review-libs/schemas/adversarial-reviewer-output.schema.json

## Validation

- `bash -n skills/_harness-libs/plan-runner.sh`
- `bash -n skills/_harness-libs/execute-runner.sh`
- `bash -n skills/_harness-libs/task-ledger.sh`
- `bash skills/_harness-libs/smoke-test/test-plan-runner.sh`
- `bash skills/_harness-libs/smoke-test/test-execute-runner.sh`
- `bash skills/_harness-libs/smoke-test/test-task-ledger.sh`
- `bash skills/_harness-libs/smoke-test/test-review-execute-command-control.sh`
- `rg -n "worktree|git-worktrees|workspace mode" skills/execute-change/SKILL.md commands/execute-change.md docs/superpowers/plans/2026-04-09-execute-change-v2-task-ledger.md`
- targeted command-surface checks for `commands/execute-change.md`

## Rollout And Compatibility

- Keep the current serial-first kernel semantics.
- Add task-ledger support in a backward-compatible path first.
- Allow older plans to keep working temporarily in compatibility mode.
- Require execution-grade task fields for new plans after the task-ledger path is stable.
- Do not remove the existing final review and evaluation gates.

## Success Criteria

Success means:

- an approved plan runs as one execution unit by default
- `execute-change` can always report the active task and remaining tasks
- `execute-change` reminds once about isolated worktree development before first code mutation when not already in an isolated worktree
- `execute-change` no longer asks whether to continue while ready tasks remain
- task-level verification and task-level review happen before task completion
- final converge, review, verify, truth-sync, and close remain explicit macro gates
- human operators can understand current progress without reconstructing it from chat history
