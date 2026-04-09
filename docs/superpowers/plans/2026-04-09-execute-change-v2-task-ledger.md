# Execute Change V2 Task-Ledger Implementation Plan

> For agentic workers: required execution workflow is task-by-task with explicit checkboxes and review checkpoints. Subagent-driven execution is preferred when implementation starts, but the approved plan remains the execution unit.

Goal: make `execute-change` run an approved plan as one deterministic execution unit by adding an execution-grade task contract, a task-ledger runtime helper, a default worktree preflight reminder, task-level review cadence, and a "wide read, narrow write" review fence without weakening the existing sovereign kernel.

Architecture: keep the seven-entry sovereign kernel unchanged, extend `plan-change` so plans become task-ledger-ready, extend `execute-change` with a lower-plane execute/review micro-loop, keep `repair-review` as an optional bounded accelerator rather than the main loop, and preserve the existing macro gates for converge, final review, verification, truth-sync, and close.

Tech Stack: Markdown skill files, Bash runtime helpers, jq-backed runtime state, shell smoke tests, existing review gate and review runner under `skills/_review-libs`

---

## Upstream Design

- design_ref: docs/superpowers/specs/2026-04-09-execute-change-v2-task-ledger-design.md
- design_version: 2026-04-09-initial

## Implementation Scope

- scope_slice: execution-grade plan contracts plus task-ledger-driven `execute-change` progression, default worktree preflight, task-level review cadence, and separation of review read scope from repair write scope
- impl_file_refs:
  - AGENTS.md
  - README.md
  - skills/plan-change/SKILL.md
  - skills/execute-change/SKILL.md
  - skills/review-code-impl/SKILL.md
  - skills/review-code-impl/references/workflow-details.md
  - commands/execute-change.md
  - skills/_harness-libs/contracts.sh
  - skills/_harness-libs/plan-runner.sh
  - skills/_harness-libs/execute-runner.sh
  - skills/_harness-libs/phase-engine.sh
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
- verification_scope:
  - `bash -n skills/_harness-libs/contracts.sh skills/_harness-libs/plan-runner.sh skills/_harness-libs/execute-runner.sh skills/_harness-libs/task-ledger.sh`
  - `bash skills/_harness-libs/smoke-test/test-plan-runner.sh`
  - `bash skills/_harness-libs/smoke-test/test-execute-runner.sh`
  - `bash skills/_harness-libs/smoke-test/test-task-ledger.sh`
  - `bash skills/_harness-libs/smoke-test/test-review-execute-command-control.sh`
  - `bash skills/_review-libs/smoke-test/test-artifact-dag.sh`
  - `bash skills/_harness-libs/design-runner.sh validate docs/superpowers/specs/2026-04-09-execute-change-v2-task-ledger-design.md`
  - `bash skills/_harness-libs/plan-runner.sh validate docs/superpowers/plans/2026-04-09-execute-change-v2-task-ledger.md`
  - `rg -n "task_ledger|task_catalog|execution_result|task review|Do NOT ask whether to continue|approved plan remains the execution unit|worktree|git-worktrees|workspace mode|wide enough to understand|narrow enough to trust|repair-review" skills/plan-change/SKILL.md skills/execute-change/SKILL.md skills/review-code-impl/SKILL.md skills/review-code-impl/references/workflow-details.md commands/execute-change.md AGENTS.md README.md docs/superpowers/specs/2026-04-09-execute-change-v2-task-ledger-design.md`
  - `git diff --check`
- out_of_scope:
  - changes to `skills/_review-libs` driver implementations or schemas
  - renaming top-level kernel entries away from `*-change`
  - unattended parallel execution
  - external state stores or orchestration services
- divergence_from_design: none

## Review Gate

- required_entry: review-change
- required_mode: review-only
- task_review_default_depth: quick
- final_review_default_depth: thorough

## Human Gate

- approval_required: true
- approval_status: approved
- next_entry: execute-change
- parallel_execution_approved: false

## File Structure

- `skills/_harness-libs/task-ledger.sh`
  New execution-support helper for task catalog parsing, task ledger initialization, ready-task resolution, status mutation, and execution-result emission.
- `skills/_harness-libs/plan-runner.sh`
  Extend plan validation to require execution-grade task metadata and expose any helper entry points needed for task-catalog materialization.
- `skills/_harness-libs/execute-runner.sh`
  Extend execution contract helpers to materialize task-ledger behavior, worktree preflight behavior, deterministic continuation rules, and task-level stop-state reporting.
- `skills/_review-libs/artifact-dag.sh`
  Expand implementation-surface handling from exact-file-only matching to stable directory or module-prefix matching without introducing arbitrary glob semantics.
- `skills/_review-libs/workspace.sh`
  Separate reviewer read scope from repair write scope so readonly review can see the needed plan-bound context while automatic edits remain bounded by `allowed_touch_set`.
- `skills/review-code-impl/SKILL.md`
  Clarify that `repair-review` is an optional bounded accelerator inside the main execution loop rather than the primary lifecycle owner.
- `skills/review-code-impl/references/workflow-details.md`
  Clarify that review read scope may be wider than repair scope while still remaining inside the active design/plan lineage.
- `skills/_harness-libs/contracts.sh`
  Add any new enums or helper validators required for task-ledger statuses and execution-result fields.
- `skills/_harness-libs/smoke-test/test-task-ledger.sh`
  New smoke test for task-catalog parsing, ledger initialization, ready-task resolution, and task state transitions.
- `skills/_harness-libs/smoke-test/test-plan-runner.sh`
  Update plan validation coverage for execution-grade task fields.
- `skills/_harness-libs/smoke-test/test-execute-runner.sh`
  Update execution coverage for task-ledger-derived continuation rules and deterministic stop conditions.
- `skills/_harness-libs/smoke-test/test-review-execute-command-control.sh`
  Extend command-control assertions for task review cadence and no-mid-plan continuation prompts.
- `skills/plan-change/SKILL.md`
  Update planning instructions so plans compile into execution-grade task catalogs rather than prose-only task lists.
- `skills/execute-change/SKILL.md`
  Update execution instructions so the approved plan is treated as the atomic execution unit with a task-level micro-loop.
- `commands/execute-change.md`
  Update command-surface guidance for task-ledger materialization, worktree preflight, task-level review, progress reporting, and deterministic continuation.
- `AGENTS.md`
  Clarify the kernel-level distinction between macro authority and task-level execution support.
- `README.md`
  Clarify the human-facing mental model as `design -> plan -> execute` while preserving the sovereign kernel naming.

## Task 1: Make The Design And Plan Contracts Execution-Grade

- task_id: task-contracts
- depends_on:
  - root
- scope_slice: require execution-grade task metadata in plan artifacts and validation
- impl_file_refs:
  - skills/plan-change/SKILL.md
  - skills/_harness-libs/plan-runner.sh
- test_file_refs:
  - skills/_harness-libs/smoke-test/test-plan-runner.sh
- verification_scope:
  - `bash -n skills/_harness-libs/plan-runner.sh skills/_harness-libs/smoke-test/test-plan-runner.sh`
  - `bash skills/_harness-libs/smoke-test/test-plan-runner.sh`
- executor_mode: inline-serial
- task_review_depth: thorough
- done_when:
  - plan validation fails on missing task metadata and passes on execution-grade task metadata fixtures
- rollback_on_failure: plan-incompleteness

**Files:**
- Modify: `skills/plan-change/SKILL.md`
- Modify: `skills/_harness-libs/plan-runner.sh`
- Modify: `skills/_harness-libs/smoke-test/test-plan-runner.sh`
- Test: `skills/_harness-libs/plan-runner.sh`
- Test: `skills/_harness-libs/smoke-test/test-plan-runner.sh`

- [ ] **Step 1: Update `skills/plan-change/SKILL.md` to require execution-grade task metadata**

Add planning rules that require each task to carry:
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

State explicitly that a prose checklist alone is not an execution-grade plan.

- [ ] **Step 2: Extend `skills/_harness-libs/plan-runner.sh` validation for task-ledger readiness**

Teach plan validation to fail when:
- no task metadata block can be found
- a task omits `task_id`
- a task omits `depends_on`
- a task omits task-scoped file refs
- a task omits `verification_scope`
- task fields cannot be deterministically parsed

Keep existing required sections and approval-state checks intact.

- [ ] **Step 3: Update `skills/_harness-libs/smoke-test/test-plan-runner.sh`**

Add positive coverage for:
- a valid task metadata block
- multiple tasks with dependency order

Add negative coverage for:
- missing `task_id`
- missing `depends_on`
- missing task-scoped verification
- prose-only task sections without execution metadata

- [ ] **Step 4: Run targeted validation**

Run:

```bash
bash -n skills/_harness-libs/plan-runner.sh skills/_harness-libs/smoke-test/test-plan-runner.sh
bash skills/_harness-libs/smoke-test/test-plan-runner.sh
```

Expected:
- syntax check passes
- task-ledger-ready plan validation passes for the positive fixture
- negative fixtures fail for the right reasons

## Task 2: Add Task-Ledger Runtime Helpers

- task_id: task-ledger-runtime
- depends_on:
  - task-contracts
- scope_slice: task catalog parsing, ledger initialization, and runtime status mutation helpers
- impl_file_refs:
  - skills/_harness-libs/contracts.sh
  - skills/_harness-libs/task-ledger.sh
- test_file_refs:
  - skills/_harness-libs/smoke-test/test-task-ledger.sh
- verification_scope:
  - `bash -n skills/_harness-libs/contracts.sh skills/_harness-libs/task-ledger.sh skills/_harness-libs/smoke-test/test-task-ledger.sh`
  - `bash skills/_harness-libs/smoke-test/test-task-ledger.sh`
- executor_mode: inline-serial
- task_review_depth: quick
- done_when:
  - task-ledger helpers materialize deterministic catalog and ledger state for execution-grade plans
- rollback_on_failure: plan-incompleteness

**Files:**
- Create: `skills/_harness-libs/task-ledger.sh`
- Modify: `skills/_harness-libs/contracts.sh`
- Create: `skills/_harness-libs/smoke-test/test-task-ledger.sh`
- Test: `skills/_harness-libs/task-ledger.sh`
- Test: `skills/_harness-libs/smoke-test/test-task-ledger.sh`

- [ ] **Step 1: Add task-ledger enums and validators in `skills/_harness-libs/contracts.sh`**

Introduce canonical task-ledger statuses:
- `pending`
- `ready`
- `in_progress`
- `in_review`
- `blocked`
- `done`

Add any helper validation needed for execution-result stop reasons.

- [ ] **Step 2: Implement `skills/_harness-libs/task-ledger.sh`**

Add helpers for:
- extracting a task catalog from the approved plan
- initializing a ledger from that catalog
- computing ready tasks from `depends_on`
- marking task state transitions
- emitting a deterministic execution result

The helper should keep the approved plan immutable and track mutable progress in runtime state only.

- [ ] **Step 3: Add smoke coverage in `skills/_harness-libs/smoke-test/test-task-ledger.sh`**

Cover:
- task catalog extraction from a fixture plan
- ledger initialization
- first ready task selection
- advancing a task from `ready -> in_progress -> in_review -> done`
- unblocking the next dependent task
- producing an `execution_result` with completed and remaining counts

- [ ] **Step 4: Run targeted validation**

Run:

```bash
bash -n skills/_harness-libs/contracts.sh skills/_harness-libs/task-ledger.sh skills/_harness-libs/smoke-test/test-task-ledger.sh
bash skills/_harness-libs/smoke-test/test-task-ledger.sh
```

Expected:
- syntax check passes
- task-ledger smoke coverage passes with no output

## Task 3: Teach Execute Runner To Continue Until A Real Gate

- task_id: task-execute-loop
- depends_on:
  - task-ledger-runtime
- scope_slice: execute-runner worktree preflight, task-ledger execution state, and deterministic stop behavior
- impl_file_refs:
  - skills/_harness-libs/execute-runner.sh
  - skills/execute-change/SKILL.md
- test_file_refs:
  - skills/_harness-libs/smoke-test/test-execute-runner.sh
- verification_scope:
  - `bash -n skills/_harness-libs/execute-runner.sh skills/_harness-libs/smoke-test/test-execute-runner.sh`
  - `bash skills/_harness-libs/smoke-test/test-execute-runner.sh`
- executor_mode: inline-serial
- task_review_depth: thorough
- done_when:
  - execute-runner exposes deterministic task-level continuation and rejects non-execution-grade plans
- rollback_on_failure: plan-incompleteness

**Files:**
- Modify: `skills/_harness-libs/execute-runner.sh`
- Modify: `skills/execute-change/SKILL.md`
- Modify: `skills/_harness-libs/smoke-test/test-execute-runner.sh`
- Test: `skills/_harness-libs/execute-runner.sh`
- Test: `skills/_harness-libs/smoke-test/test-execute-runner.sh`

- [ ] **Step 1: Extend `skills/_harness-libs/execute-runner.sh` with task-ledger-aware helpers**

Add helpers for:
- worktree preflight detection and reminder-state handling
- materializing a task catalog from an approved plan
- materializing an initial ledger
- resolving the next ready task
- computing deterministic stop reasons
- emitting an `execution_result`

Keep existing helpers for:
- approved-plan validation
- allowed touch set derivation
- verification command derivation
- truth-sync requirement derivation
- rollback target resolution

- [ ] **Step 2: Update `skills/execute-change/SKILL.md`**

Make the workflow explicit:
- perform a one-time worktree reminder before the first code mutation when not already in an isolated worktree
- an approved plan is the atomic execution unit
- one ready task at a time
- task verification then task review before task completion
- continue automatically while ready tasks remain and no human gate is required
- stop only at a real gate or deterministic rollback condition

- [ ] **Step 3: Update `skills/_harness-libs/smoke-test/test-execute-runner.sh`**

Add coverage for:
- worktree preflight behavior and one-time reminder semantics
- task-ledger helper availability
- deterministic continuation while ready tasks remain
- explicit stop reasons such as `worktree_decision_required`, `task_blocked_requires_human`, `rollback_required`, `truth_sync_required`, and `ready_for_close`
- refusal to treat "one task finished" as a final stop state

- [ ] **Step 4: Run targeted validation**

Run:

```bash
bash -n skills/_harness-libs/execute-runner.sh skills/_harness-libs/smoke-test/test-execute-runner.sh
bash skills/_harness-libs/smoke-test/test-execute-runner.sh
```

Expected:
- syntax check passes
- execution runner smoke coverage confirms deterministic continuation semantics

## Task 4: Separate Review Read Scope From Repair Write Scope

- task_id: task-review-fence
- depends_on:
  - task-execute-loop
- scope_slice: widen readonly review context while preserving narrow repair write fences
- impl_file_refs:
  - skills/_review-libs/artifact-dag.sh
  - skills/_review-libs/workspace.sh
  - skills/review-code-impl/SKILL.md
  - skills/review-code-impl/references/workflow-details.md
  - skills/_review-libs/run-review.sh
- test_file_refs:
  - skills/_review-libs/smoke-test/test-artifact-dag.sh
- verification_scope:
  - `bash -n skills/_review-libs/artifact-dag.sh skills/_review-libs/workspace.sh`
  - `bash skills/_review-libs/smoke-test/test-artifact-dag.sh`
- executor_mode: inline-serial
- task_review_depth: thorough
- done_when:
  - review readonly scope is wide enough to understand the plan-bound lineage while repair writes stay fenced to the approved slice
- rollback_on_failure: plan-incompleteness

**Files:**
- Modify: `skills/_review-libs/artifact-dag.sh`
- Modify: `skills/_review-libs/workspace.sh`
- Modify: `skills/review-code-impl/SKILL.md`
- Modify: `skills/review-code-impl/references/workflow-details.md`
- Modify: `skills/_review-libs/smoke-test/test-artifact-dag.sh`
- Test: `skills/_review-libs/artifact-dag.sh`
- Test: `skills/_review-libs/workspace.sh`
- Test: `skills/_review-libs/smoke-test/test-artifact-dag.sh`

- [ ] **Step 1: Update `skills/_review-libs/artifact-dag.sh` to support stable directory or module-prefix surfaces**

Allow implementation and test refs to match:
- exact file paths
- stable directory-prefix paths
- stable module-prefix paths represented as concrete repository-relative prefixes

Do not add arbitrary glob matching.

- [ ] **Step 2: Update `skills/_review-libs/workspace.sh` to keep read scope wider than repair scope**

Make the code-implementation review path distinguish:
- readonly review context that may expand to the relevant plan/design surface
- repair authority that stays constrained to `allowed_touch_set`

Keep automatic edits bounded, but stop shrinking readonly review to exact-file-only scope.

- [ ] **Step 3: Update review docs for the new fence semantics**

Clarify in:
- `skills/review-code-impl/SKILL.md`
- `skills/review-code-impl/references/workflow-details.md`

that:
- `repair-review` is optional
- the main lifecycle owner remains `execute-change`
- readonly review may widen within the current artifact lineage
- repair writes remain strictly bounded

- [ ] **Step 4: Extend `skills/_review-libs/smoke-test/test-artifact-dag.sh`**

Add coverage for:
- stable directory-prefix refs in design and plan surfaces
- in-scope changed files underneath an allowed directory surface
- out-of-scope files still being reported correctly
- exact repair fence preservation even when readonly review context widens

- [ ] **Step 5: Run targeted validation**

Run:

```bash
bash -n skills/_review-libs/artifact-dag.sh skills/_review-libs/workspace.sh skills/_review-libs/smoke-test/test-artifact-dag.sh
bash skills/_review-libs/smoke-test/test-artifact-dag.sh
```

Expected:
- syntax checks pass
- directory-prefix review fences work
- repair scope remains bounded and auditable

## Task 5: Add Task-Level Review Cadence To The Command Surface

- task_id: task-command-surface
- depends_on:
  - task-review-fence
- scope_slice: command-surface guidance for task-ledger execution, worktree preflight, and per-task review cadence
- impl_file_refs:
  - commands/execute-change.md
- test_file_refs:
  - skills/_harness-libs/smoke-test/test-review-execute-command-control.sh
- verification_scope:
  - `bash skills/_harness-libs/smoke-test/test-review-execute-command-control.sh`
- executor_mode: inline-serial
- task_review_depth: thorough
- done_when:
  - execute command docs describe worktree reminder timing, task progress reporting, and no mid-plan continuation prompt
- rollback_on_failure: plan-incompleteness

**Files:**
- Modify: `commands/execute-change.md`
- Modify: `skills/_harness-libs/smoke-test/test-review-execute-command-control.sh`
- Test: `commands/execute-change.md`
- Test: `skills/_harness-libs/smoke-test/test-review-execute-command-control.sh`

- [ ] **Step 1: Update `commands/execute-change.md`**

Add command-surface guidance for:
- worktree preflight using the existing `git-worktrees` workflow
- asking once whether to switch to isolated worktree development when execution is starting in the current checkout
- skipping the prompt when already in an isolated worktree or when the run has already recorded a decline
- task-ledger materialization from the approved plan
- per-task progress reporting
- task-level `review-change` invocation with task-scoped files and default `--depth quick`
- escalation to `--depth thorough` for higher-risk tasks
- deterministic continuation while ready tasks remain
- an explicit prohibition on asking whether to continue mid-plan when the next task is machine-determined

- [ ] **Step 2: Extend `skills/_harness-libs/smoke-test/test-review-execute-command-control.sh`**

Assert that `commands/execute-change.md` now mentions:
- worktree preflight or `git-worktrees`
- one-time reminder semantics before first code mutation
- task-ledger or task catalog materialization
- task-level review cadence
- quick vs thorough task review depth behavior
- progress reporting with completed and remaining tasks
- no mid-plan "should I continue" prompt when a ready task exists

- [ ] **Step 3: Run targeted validation**

Run:

```bash
bash skills/_harness-libs/smoke-test/test-review-execute-command-control.sh
```

Expected:
- command-control assertions pass

## Task 6: Align Human-Facing Documentation With The New Execution Model

- task_id: task-docs-alignment
- depends_on:
  - task-command-surface
- scope_slice: align stable truth docs with design-plan-execute mental model and lower-plane task-ledger execution support
- impl_file_refs:
  - AGENTS.md
  - README.md
- test_file_refs:
  - AGENTS.md
  - README.md
- verification_scope:
  - `rg -n "design|plan|execute|task-ledger|approved plan|worktree|wide read|narrow write|top-level authority|execution unit" AGENTS.md README.md`
- executor_mode: inline-serial
- task_review_depth: quick
- done_when:
  - AGENTS and README explain the new human-facing mental model without weakening the sovereign kernel boundary
- rollback_on_failure: plan-incompleteness

**Files:**
- Modify: `AGENTS.md`
- Modify: `README.md`
- Test: `AGENTS.md`
- Test: `README.md`

- [ ] **Step 1: Update `AGENTS.md`**

Clarify that:
- the seven-entry kernel remains the only top-level authority
- task-ledger execution is a lower-plane execution-support layer
- `repair-review` is an optional bounded helper, not the main lifecycle owner
- worktree preflight is the default execution-start reminder, not a mid-plan interruption loop
- `execute-change` now treats an approved plan as the execution unit and should not stop mid-plan without a real gate

- [ ] **Step 2: Update `README.md`**

Clarify the human-facing workflow as:
- design
- plan
- execute

While also stating that the underlying sovereign kernel still uses:
- `design-change`
- `plan-change`
- `execute-change`

Mention that execution should normally start from an isolated worktree when the user wants that workflow, and the harness should remind once before first implementation when still in the current checkout.

Mention that bounded review works on a "wide read, narrow write" rule:
- reviewer context may widen to the relevant plan-bound surface
- automatic edits remain fenced to the current plan slice

- [ ] **Step 3: Run targeted grep checks**

Run:

```bash
rg -n "design -> plan -> execute|task-ledger|approved plan.*execution unit|seven-entry kernel|top-level authority|worktree|git-worktrees" AGENTS.md README.md
```

Expected:
- the new mental model and kernel boundary language are both present

## Rollback

- failure_kind: plan-incompleteness
- rollback_entry: plan-change
- rollback_triggers:
  - task contract cannot be parsed deterministically
  - task-ledger runtime object cannot be reconciled with plan state
  - command-surface behavior cannot be made deterministic without changing top-level kernel boundaries
