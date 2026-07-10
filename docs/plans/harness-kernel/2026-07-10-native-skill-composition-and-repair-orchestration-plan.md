# Native Skill Composition And Repair Orchestration Implementation Plan

Goal: rename the implementation lifecycle controller and evaluator so their hierarchy is clear, move repair-loop ownership into the controller, ship an install-visible local workflow contract, remove the unconditional user-global bootstrap, and verify native workflow-plus-policy composition in isolated repositories.

Architecture: preserve the sovereign harness, source/generated install boundary, same-driver review, and top-level `review-change` gate. Rename `execute-change` to `implement-change`, rename `review-code-impl` to `review-implementation`, keep the cross-skill call graph acyclic, and model repair as a five-round expected/ten-round hard-limit state machine owned only by `implement-change`.

Tech Stack: Markdown skill instructions, TOML contracts parsed by Python `tomllib`, Bash harness/review runners, jq schemas, generated Claude/Codex/root-flat skill surfaces, shell smoke tests, and fresh Codex subagents over isolated Git fixtures.

## Upstream Design

- design_ref: docs/plans/harness-kernel/2026-07-10-native-skill-composition-and-repair-orchestration-design.md
- design_version: 2026-07-10-approved-amended-after-forward-test

## Implementation Scope

- scope_slice: public workflow/evaluator rename, installed controller workflow contract, controller-owned repair state machine, optional session router, deterministic generation, and forward-test evidence
- impl_file_refs:
  - contracts
  - src/skills/workflows
  - src/skills/review-components
  - src/skills/session
  - src/skills/policies
  - src/skills/_internal/_harness-libs
  - src/skills/_internal/_review-libs
  - commands
  - scripts
  - AGENTS.md
  - README.md
  - docs/architecture
  - docs/changelog
  - /Users/csheng/.codex/AGENTS.md
- test_file_refs:
  - tests
  - src/skills/_internal/_harness-libs/smoke-test
  - src/skills/_internal/_review-libs/smoke-test
  - docs/plans/harness-kernel/2026-07-10-native-skill-composition-and-repair-orchestration-plan.md
  - /Users/csheng/tmp/market-csheng-skill-eval
- verification_scope:
  - `bash skills/_harness-libs/design-runner.sh validate docs/plans/harness-kernel/2026-07-10-native-skill-composition-and-repair-orchestration-design.md`
  - `PLAN_RUNNER_TASK_METADATA_MODE=strict bash skills/_harness-libs/plan-runner.sh validate docs/plans/harness-kernel/2026-07-10-native-skill-composition-and-repair-orchestration-plan.md`
  - `python3 scripts/generate-skills-index.py`
  - `python3 scripts/flatten-skills.py --target all`
  - `bash scripts/check.sh`
  - `bash skills/_harness-libs/smoke-test/test-sovereign-command-surface.sh`
  - `bash skills/_harness-libs/smoke-test/test-design-runner.sh`
  - `bash skills/_harness-libs/smoke-test/test-kernel-contracts.sh`
  - `bash skills/_harness-libs/smoke-test/test-kernel-routing.sh`
  - `bash skills/_harness-libs/smoke-test/test-kernel-phase.sh`
  - `bash skills/_harness-libs/smoke-test/test-plan-runner.sh`
  - `bash skills/_harness-libs/smoke-test/test-design-plan-command-control.sh`
  - `bash skills/_harness-libs/smoke-test/test-review-runner.sh`
  - `bash skills/_harness-libs/smoke-test/test-execute-runner.sh`
  - `bash skills/_harness-libs/smoke-test/test-review-execute-command-control.sh`
  - `bash skills/_review-libs/smoke-test/test-review-gating.sh`
  - `bash skills/_review-libs/smoke-test/test-artifact-dag.sh`
  - `jq . skills/_review-libs/schemas/reviewer-output.schema.json >/dev/null`
  - `bash -n skills/_review-libs/smoke-test/smoke-same-driver-review.sh`
  - `skills/_review-libs/smoke-test/smoke-same-driver-review.sh all --reviewer codex --timeout 1800`
  - `uvx --with pyyaml python "$HOME/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py" .`
  - `git diff --check`
- out_of_scope:
  - historical plan rewrites
  - provider-switching review
  - a new runtime service or external state store
  - aliases that expose both old and new skill names
  - unrelated existing `design-change` working-tree modifications
- divergence_from_design: none; the approved design records the forward-test amendment from native-only discovery to a thin deterministic host intent map

## Work Package Readiness

- milestone_objective: deliver one coherent rename and repair-loop boundary change across source, runtime, generated surfaces, user-global bootstrap, and native-discovery tests
- non_goals:
  - redesign the entire sovereign harness
  - merge unrelated policy skills
  - commit or push
- future_phase:
  - optionally generate a repo-wide architecture graph from skill-local runtime contracts
  - collect longer-term production telemetry on trigger precision and token use
- decision_status: ready_for_review
- oracle_strategy: contract and state-machine checks plus characterization smoke tests and fresh-agent behavioral probes
- acceptance_oracles:
  - no active stable surface exposes `execute-change` or `review-code-impl`
  - `implement-change/references/workflow.toml` installs into all selected surfaces and passes graph validation
  - implementation review defaults `max_rounds` to the hard limit ten, records expected convergence as five, and rejects values above ten
  - lower-plane review never owns mutation or lifecycle continuation
  - isolated Go review composes review workflow with Go policy without loading `use-coding-skills`
  - isolated non-coding work does not load the coding bootstrap
- execution_continuity: continuous_after_plan_approval
- max_review_batches: 2
- subagent_ready: true

## Execution Continuity

- execution_mode: continuous_after_plan_approval
- confirmation_clearance:
  - C0: user explicitly authorized plan creation, skill changes, `/Users/csheng/.codex/AGENTS.md` bootstrap removal, isolated fixtures, and fresh-subagent validation
  - C1: execute in the current checkout because `/Users/csheng/.agents/skills/coding` resolves to its generated `skills/` surface; before mutation record the exact seven pre-existing `design-change` paths and a hash of their combined diff, then require the same hash after every regeneration and at closeout
- runtime_contingencies:
  - X1: stop immediately if the recorded pre-existing `design-change` path set or combined diff hash changes during generation
  - X2: stop and report metadata-cache limitation if renamed skills cannot be discovered in any fresh top-level Codex process after filesystem validation passes
  - X3: stop for re-plan if the rename requires compatibility aliases that would cause duplicate description triggers
- planned_stop_points:
  - none
- task_ordering_rationale: establish contracts and source names first, then rewire runtime and stable truth, regenerate all install surfaces once, run deterministic checks, and only then run fresh-agent behavioral probes

## Review Gate

- required_entry: review-change
- required_mode: review-only
- task_review_default_depth: quick
- final_review_default_depth: thorough

## Human Gate

- approval_required: true
- approval_status: approved
- approval_basis: explicit request to write the plan and then execute the skill change and fresh-subagent validation
- next_entry: implement-change
- parallel_execution_approved: false

## Task 1: Add Workflow-Contract Validator Oracles

- task_id: task-contract
- depends_on:
  - root
- scope_slice: add deterministic validator behavior and fixture-level tests before changing the live manifest or skill names
- impl_file_refs:
  - scripts/check-contracts.py
- test_file_refs:
  - tests/test_skill_workflow_contracts.py
- verification_scope:
  - `python3 -m unittest tests/test_skill_workflow_contracts.py`
  - `python3 -m py_compile scripts/check-contracts.py tests/test_skill_workflow_contracts.py`
- executor_mode: inline-serial
- task_review_depth: thorough
- done_when:
  - validator rejects missing runtime contract, unknown call targets, reverse controller calls, multiple repair owners, and cross-skill cycles
  - fixture validation accepts an installed controller contract with expected rounds five and hard limit ten
- rollback_on_failure: plan-incompleteness

Steps:

- [ ] Extend `scripts/check-contracts.py` with deterministic TOML parsing and graph checks.
- [ ] Add temporary-fixture tests for missing runtime contract, unknown targets, reverse controller calls, multiple loop owners, cycles, invalid round limits, and the valid controller case; avoid a new dependency.
- [ ] Keep the live manifest and current generated surfaces untouched until Task 2 performs the atomic rename.

## Task 2: Rename The Public Controller And Implementation Evaluator

- task_id: task-rename
- depends_on:
  - task-contract
- scope_slice: rename source directories, SKILL identities, UI metadata, contracts, public commands, facade routing, and generated public identifiers without compatibility aliases
- impl_file_refs:
  - contracts/skills.toml
  - contracts/lifecycle.toml
  - src/skills/workflows/execute-change
  - src/skills/workflows/implement-change
  - src/skills/review-components/review-code-impl
  - src/skills/review-components/review-implementation
  - src/skills/workflows/plan-change/SKILL.md
  - src/skills/workflows/review-change/SKILL.md
  - commands/execute-change.md
  - commands/implement-change.md
  - commands/review-code-impl.md
  - commands/review-implementation.md
  - src/skills/_internal/_harness-libs/contracts.sh
  - src/skills/_internal/_harness-libs/classifier.sh
  - src/skills/_internal/_harness-libs/router.sh
  - src/skills/_internal/_harness-libs/phase-engine.sh
  - src/skills/_internal/_harness-libs/close-runner.sh
  - src/skills/_internal/_harness-libs/truth-sync-runner.sh
  - src/skills/_internal/_review-libs
  - src/skills/workflows/implement-change/references/workflow.toml
  - src/skills/workflows/implement-change/references/repair-loop.md
  - skills.index.json
- test_file_refs:
  - tests/test_skill_workflow_contracts.py
- verification_scope:
  - `python3 scripts/generate-skills-index.py`
  - `python3 scripts/check-contracts.py`
  - `python3 -m unittest tests/test_skill_workflow_contracts.py`
- executor_mode: inline-serial
- task_review_depth: thorough
- done_when:
  - source and public contracts expose only `implement-change` and `review-implementation`
  - public names express controller versus evaluator roles
  - `review-change` dispatches implementation artifacts to `review-implementation`
  - `skills.index.json` matches the renamed live contract; root-flat and external install surfaces remain intentionally stale until Task 5 generation
- rollback_on_failure: rollback-required

Steps:

- [ ] Rename the two source directories and edit only source-of-truth content.
- [ ] Regenerate `agents/openai.yaml` deterministically for both renamed skills using `$skill-creator` tooling.
- [ ] Update the plan handoff, review facade, command files, contracts, kernel enums, routing, phases, stop-state destinations, and internal review path lookups in the same task.
- [ ] Generate only `skills.index.json` so `check-contracts.py` can validate the renamed live manifest; do not run aggregate install-surface checks before Task 5.
- [ ] Keep internal review mode `code-impl` only where it is an implementation detail and add no public alias skill.

## Task 3: Move Repair Ownership Into The Orchestrator

- task_id: task-repair-loop
- depends_on:
  - task-rename
- scope_slice: make review a pure evaluation gate and make the orchestrator continue in-scope repair through verification and fresh review
- impl_file_refs:
  - src/skills/workflows/implement-change/SKILL.md
  - src/skills/workflows/implement-change/references/workflow.toml
  - src/skills/workflows/implement-change/references/repair-loop.md
  - src/skills/review-components/review-implementation/SKILL.md
  - src/skills/review-components/review-implementation/references/workflow-details.md
  - src/skills/_internal/_review-libs/run-review.sh
  - src/skills/_internal/_review-libs/output-validator.sh
  - src/skills/_internal/_review-libs/prompt-builder.sh
  - commands/implement-change.md
  - commands/review-implementation.md
- test_file_refs:
  - src/skills/_internal/_harness-libs/smoke-test/test-execute-runner.sh
  - src/skills/_internal/_harness-libs/smoke-test/test-review-execute-command-control.sh
  - src/skills/_internal/_review-libs/smoke-test/test-review-gating.sh
  - src/skills/_internal/_review-libs/smoke-test/smoke-same-driver-review.sh
- verification_scope:
  - `bash -n src/skills/_internal/_review-libs/run-review.sh src/skills/_internal/_review-libs/output-validator.sh`
  - `bash src/skills/_internal/_harness-libs/smoke-test/test-execute-runner.sh`
  - `bash src/skills/_internal/_harness-libs/smoke-test/test-review-execute-command-control.sh`
  - `bash src/skills/_internal/_review-libs/smoke-test/test-review-gating.sh`
- executor_mode: inline-serial
- task_review_depth: thorough
- done_when:
  - review output never authorizes the reviewer to edit or re-enter lifecycle control
  - `implement-change` classifies, batch-repairs, verifies, and requests fresh review while scope stays local
  - implementation review defaults the operational cap to ten, expects convergence within five rounds, and rejects eleven
  - plan/design/authority/rollback boundaries exit with typed states rather than more edits
- rollback_on_failure: rollback-required

Steps:

- [ ] Rewrite the controller workflow around explicit implement/verify/review/classify/repair states.
- [ ] Make `review-implementation` a pure findings-and-verdict evaluator; retain prior-findings only as reviewer context.
- [ ] Change code implementation review metadata to a ten-round hard-cap default with five expected convergence rounds while leaving design/plan defaults unchanged.
- [ ] Replace final-review immediate stop in the orchestrator command with controller-owned repair, verification, and fresh-review progression.
- [ ] Add smoke assertions for loop ownership, round limits, batch repair, and forbidden reverse calls.

## Task 4: Enable Native Workflow And Policy Composition

- task_id: task-native-discovery
- depends_on:
  - task-rename
- scope_slice: remove mandatory bootstrap behavior and make workflow and policy descriptions communicate primary versus overlay roles
- impl_file_refs:
  - src/skills/session/use-coding-skills/SKILL.md
  - src/skills/session/use-coding-skills/references/routing.md
  - src/skills/policies/go-guidelines/SKILL.md
  - src/skills/policies/shell-guidelines/SKILL.md
  - /Users/csheng/.codex/AGENTS.md
- test_file_refs:
  - /Users/csheng/tmp/market-csheng-skill-eval
- verification_scope:
  - `rg -n 'use-coding-skills' /Users/csheng/.codex/AGENTS.md`
  - `rg -n 'primary|overlay|review|Go|Shell' src/skills/workflows src/skills/review-components src/skills/policies`
- executor_mode: inline-serial
- task_review_depth: thorough
- done_when:
  - `/Users/csheng/.codex/AGENTS.md` no longer mandates `use-coding-skills` at session start
  - the optional router description no longer matches every conversation
  - review and language policy descriptions support intentional co-triggering
- rollback_on_failure: rollback-required

Steps:

- [ ] Narrow the `use-coding-skills` name/description/body contract without removing the skill.
- [ ] Remove only the unconditional bootstrap bullet from `/Users/csheng/.codex/AGENTS.md`; preserve unrelated local instructions and the `CLAUDE.md` symlink.
- [ ] Clarify the workflow-versus-policy overlay role in review, Go, and Shell descriptions without duplicating full routing logic.

## Task 5: Synchronize Stable Truth And Generated Install Surfaces

- task_id: task-truth-generation
- depends_on:
  - task-repair-loop
  - task-native-discovery
- scope_slice: update active stable truth, runtime references, commands, tests, indexes, source maps, and all generated target surfaces
- impl_file_refs:
  - AGENTS.md
  - README.md
  - docs/architecture
  - docs/changelog
  - contracts
  - src/skills
  - commands
  - skills.index.json
  - skills
  - .dist/claude
  - .dist/codex
- test_file_refs:
  - scripts/check.sh
  - src/skills/_internal/_harness-libs/smoke-test
  - src/skills/_internal/_review-libs/smoke-test
- verification_scope:
  - `python3 scripts/generate-skills-index.py`
  - `python3 scripts/flatten-skills.py --target all`
  - `bash scripts/check.sh`
  - `bash skills/_harness-libs/smoke-test/test-sovereign-command-surface.sh`
  - `bash skills/_harness-libs/smoke-test/test-design-runner.sh`
  - `bash skills/_harness-libs/smoke-test/test-plan-runner.sh`
  - `bash skills/_harness-libs/smoke-test/test-design-plan-command-control.sh`
  - `bash skills/_harness-libs/smoke-test/test-review-runner.sh`
  - `bash skills/_harness-libs/smoke-test/test-execute-runner.sh`
  - `bash skills/_harness-libs/smoke-test/test-review-execute-command-control.sh`
  - `jq . skills/_review-libs/schemas/reviewer-output.schema.json >/dev/null`
  - `bash -n skills/_review-libs/smoke-test/smoke-same-driver-review.sh`
  - `skills/_review-libs/smoke-test/smoke-same-driver-review.sh all --reviewer codex --timeout 1800`
  - `uvx --with pyyaml python "$HOME/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py" .`
  - `git diff --check`
- executor_mode: inline-serial
- task_review_depth: thorough
- done_when:
  - source, root-flat, Claude, and Codex surfaces expose the same new public names and local runtime contract
  - stable docs describe native discovery and controller-owned repair accurately
  - unrelated dirty `design-change` work remains present and semantically unchanged
- rollback_on_failure: rollback-required

Steps:

- [ ] Update active stable references; leave historical plans untouched except this approved design/plan.
- [ ] Update all internal path lookups, routing enums, stop-state destinations, and smoke assertions.
- [ ] Generate the index and all install surfaces once source changes are complete.
- [ ] Run aggregate validation and plugin validation.

## Task 6: Run Fresh-Agent Forward Tests In Isolated Repositories

- task_id: task-forward-tests
- depends_on:
  - task-truth-generation
- scope_slice: observe native skill discovery, composition, read-only boundaries, execution, and non-coding behavior without prompt leakage
- impl_file_refs:
  - /Users/csheng/tmp/market-csheng-skill-eval
- test_file_refs:
  - /Users/csheng/tmp/market-csheng-skill-eval/go-review
  - /Users/csheng/tmp/market-csheng-skill-eval/architecture-readonly
  - /Users/csheng/tmp/market-csheng-skill-eval/lifecycle-json-cli
  - /Users/csheng/tmp/market-csheng-skill-eval/shell-quoting
  - /Users/csheng/tmp/market-csheng-skill-eval/noncoding-summary
- verification_scope:
  - `go test -race ./...`
  - `node --test`
  - `bash -n backup.sh`
  - `bash tests/backup_test.sh`
  - per-fixture `git status --short` and `git diff --check`
- executor_mode: fresh-subagent-per-task
- task_review_depth: thorough
- done_when:
  - each fixture runs in an independent Git root with one fresh `fork_turns: none` agent
  - read-only fixtures remain unchanged
  - implementation fixtures pass their executable oracles
  - reported skill usage demonstrates workflow-plus-policy composition and no mandatory coding bootstrap for non-coding work
  - stale parent-catalog behavior is separated from fresh top-level discovery evidence
  - identical normal-home and neutral-home fresh-process probes capture actual `SKILL.md` read events and vary only the home/bootstrap surface
  - the lifecycle implementation fixture starts from reviewed, explicitly approved design and plan artifacts instead of asking one agent to cross human approval gates
- rollback_on_failure: manual-checkpoint

Steps:

- [ ] Create minimal deterministic fixtures and baseline commits without local AGENTS files.
- [ ] Pre-seed the lifecycle fixture with reviewed `approval_status: approved` design and plan artifacts that authorize only the fixture's JSON-output change; use separate read-only probes if design/plan discovery itself needs observation.
- [ ] Start a new agent per fixture with natural prompts and this fixed authority contract: work only in the named fixture root; respect read-only wording; mutation is allowed only for the two explicit repair/implementation fixtures; do not read sibling fixtures; report commands, final Git state, and a neutral `Skills used:` line listing only fully read `SKILL.md` files.
- [ ] Run identical routing probes through `codex exec --json` first with the normal home and then with a temporary neutral `CODEX_HOME`; vary only the home/bootstrap surface. The neutral home exposes candidate `skills/` directly and references current auth/config by local symlink without printing secrets. Capture actual `SKILL.md` read events for both runs.
- [ ] Record skill usage, worktree diff, commands run, findings, repair rounds, JSONL skill-read events, and final state outside the prompts.
- [ ] If a test reveals a skill defect, repair the source, regenerate surfaces, rerun deterministic checks, and rerun only the affected fixture with another fresh agent.
- [ ] If only the parent thread catalog is stale, verify rename discovery in a fresh top-level Codex process and report the cache boundary accurately.

## Rollback

- Restore old public names atomically across source, contracts, commands, runtime references, tests, and generated surfaces; never leave both names active.
- Restore the old review-round limit and immediate-stop behavior only if controller-owned repair cannot retain scope fences or same-driver isolation.
- Restore the user-global mandatory bootstrap only after a fresh top-level A/B test proves native discovery materially fails and description refinement cannot correct it.
- Preserve the pre-existing `design-change` working-tree changes throughout rollback.
- rollback_entry: design-change
