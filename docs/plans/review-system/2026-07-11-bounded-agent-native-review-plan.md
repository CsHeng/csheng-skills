# Bounded Agent-Native Review Implementation Plan

Goal: replace external Bash/model review orchestration with bounded agent-native review, constrain reviewer context and finding causality, require main-agent adjudication before repair, preserve artifact-DAG enforcement under the harness, and simplify review convergence without provider-specific or adversarial review behavior.

Architecture: the main coding agent constructs a bounded review brief and preferably delegates non-trivial review to a subagent, while retaining direct main-agent review for simple changes or hosts without delegation. Reviewers return candidate findings only. The main agent accepts, rejects, defers, or escalates each candidate. External reviewer runners, provider drivers, same-driver policy, and runner-specific schemas are retired; deterministic artifact-DAG support moves to `_harness-libs`.

Tech Stack: Markdown skill contracts, TOML exposure/workflow contracts, Bash deterministic harness helpers, Python generation scripts, shell smoke tests, generated root-flat/Claude/Codex plugin surfaces, and fresh agent/subagent behavioral probes.

## Upstream Design

- design_ref: docs/plans/review-system/2026-07-11-bounded-agent-native-review-design.md
- design_version: 2026-07-11-approved-boundary

## Implementation Scope

- scope_slice: bounded review briefs, causal findings, main-agent adjudication, agent-native reviewer delegation, retirement of external semantic review orchestration, artifact-DAG support relocation, convergence simplification, generated surfaces, and stable truth
- impl_file_refs:
  - contracts
  - src/skills/workflows
  - src/skills/review-components
  - src/skills/_internal/_harness-libs
  - src/skills/_internal/_review-libs
  - commands
  - scripts
  - AGENTS.md
  - README.md
  - docs/architecture
- test_file_refs:
  - tests
  - src/skills/_internal/_harness-libs/smoke-test
  - src/skills/_internal/_review-libs/smoke-test
  - docs/plans/review-system/2026-07-11-bounded-agent-native-review-plan.md
- verification_scope:
  - `bash src/skills/_internal/_harness-libs/design-runner.sh validate docs/plans/review-system/2026-07-11-bounded-agent-native-review-design.md`
  - `PLAN_RUNNER_TASK_METADATA_MODE=strict bash src/skills/_internal/_harness-libs/plan-runner.sh validate docs/plans/review-system/2026-07-11-bounded-agent-native-review-plan.md`
  - `python3 scripts/generate-skills-index.py`
  - `python3 scripts/flatten-skills.py --target root-flat`
  - `python3 scripts/generate-workflow-diagrams.py`
  - `bash scripts/check.sh`
  - `bash skills/_harness-libs/smoke-test/test-sovereign-command-surface.sh`
  - `bash skills/_harness-libs/smoke-test/test-design-runner.sh`
  - `bash skills/_harness-libs/smoke-test/test-plan-runner.sh`
  - `bash skills/_harness-libs/smoke-test/test-design-plan-command-control.sh`
  - `bash skills/_harness-libs/smoke-test/test-agent-native-review.sh`
  - `bash skills/_harness-libs/smoke-test/test-execute-runner.sh`
  - `bash skills/_harness-libs/smoke-test/test-review-execute-command-control.sh`
  - `uvx --with pyyaml python "$HOME/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py" .`
  - `git diff --check`
- out_of_scope:
  - repo-wide security or hardening redesign
  - product-code test or static-analysis removal
  - provider-specific review fallback support
  - external review services or persistent reviewer state
  - historical `docs/plans/` wording cleanup
  - unrelated skill, plugin, or global-agent configuration changes
- divergence_from_design: none

## Work Package Readiness

- milestone_objective: deliver one coherent active review contract in which agent-native bounded review replaces external reviewer orchestration and only causally attributable, approved-scope findings can enter repair
- non_goals:
  - eliminate all review budgets or typed stop states
  - require subagent creation for trivial reviews
  - modify user repositories outside this plugin source
- future_phase:
  - gather longer-term review precision data from normal repository work
  - add an explicit broad security-audit mode only if later use cases require it
- decision_status: ready_for_review
- oracle_strategy: contract and characterization tests for review semantics, artifact-DAG conformance tests for preserved harness boundaries, and fresh agent behavioral probes for delegation and adjudication
- acceptance_oracles:
  - active review skills require a bounded review brief and prohibit default repo-wide discovery
  - candidate blockers require qualifying change causality and an explicit approved-contract violation
  - main-agent dispositions gate repair; reviewer severity or scope labels alone cannot authorize edits
  - active review source and command surfaces do not invoke or select external reviewer tools, models, or providers and do not use adversarial/same-driver/cross-driver framing
  - non-trivial review prefers a subagent when available, trivial review may remain with the main agent, and a delegated reviewer cannot recursively delegate
  - artifact-DAG and allowed-touch-set checks still protect design, plan, execution, and truth-sync workflows after relocation
  - mechanical move/rename characterization passes without promoting pre-existing defects to blockers
  - aggregate generation, harness smoke tests, and plugin validation pass
- execution_continuity: continuous_after_plan_approval
- max_review_batches: 2
- subagent_ready: true

## Execution Continuity

- execution_mode: continuous_after_plan_approval
- confirmation_clearance:
  - C0: approving this plan authorizes the complete repo-local source, test, command, generated-surface, and stable-truth change without additional implementation checkpoints
- runtime_contingencies:
  - X1: stop and replan if artifact-DAG support cannot be separated from external reviewer invocation without weakening plan or touch-set enforcement
  - X2: stop and request a design decision if an active non-review workflow has a verified dependency on reviewer CLI/provider selection rather than deterministic artifact validation
  - X3: stop before deleting a review support file if current source inspection proves it owns a still-required non-review oracle that has no planned destination
  - X4: stop at manual review if fresh behavioral probes show recursive delegation, uncontrolled repo-wide context expansion, or automatic repair without main-agent adjudication
- planned_stop_points: []
- task_ordering_rationale: freeze behavioral contracts and characterization tests first, then change skill semantics and controller adjudication, relocate deterministic harness support before deleting external orchestration, update commands/truth/generated surfaces after source convergence, and run fresh behavioral probes only against the final install surface

## Review Gate

- required_entry: review-change
- required_mode: review-only
- task_review_default_depth: boundary
- final_review_default_depth: boundary
- planning_review_method: main-agent bounded review against the approved design because this plan explicitly retires the external reviewer runner and current multi-agent policy does not authorize spawning a planning reviewer

## Task 1: Freeze Bounded Review And Causality Oracles

- task_id: review-native-010
- depends_on:
  - root
- scope_slice: add deterministic characterization and contract tests for the approved bounded-review behavior before removing the existing runner
- impl_file_refs:
  - src/skills/_internal/_harness-libs/smoke-test
  - tests
- test_file_refs:
  - src/skills/_internal/_harness-libs/smoke-test
  - tests
- verification_scope:
  - `bash src/skills/_internal/_harness-libs/smoke-test/test-review-execute-command-control.sh`
  - `git diff --check`
- executor_mode: inline-serial
- task_review_depth: boundary
- done_when:
  - tests define the required bounded review brief fields
  - tests define all five causal classes and all seven main-agent dispositions
  - tests reject severity-only blocking and low-confidence automatic repair
  - tests distinguish mechanical move/rename, changed-behavior regression, future-phase state, and out-of-scope critical escalation
  - tests require preferred subagent review, direct-review fallback, and delegated-review recursion prevention without naming a provider or tool
- rollback_on_failure: rollback-required

Steps:

- [ ] Replace runner-centric smoke expectations with behavior-contract assertions that can initially fail against the current skills.
- [ ] Add a mechanical move/rename fixture whose unchanged legacy defect must be classified `pre_existing` and remain non-blocking.
- [ ] Add a changed-behavior fixture whose diff directly violates an acceptance oracle and must be eligible for `accepted` disposition.
- [ ] Add future-phase and incidental critical fixtures that require defer/manual escalation rather than current-scope repair.
- [ ] Add negative searches for external reviewer invocation, model/provider selection, adversarial framing, and severity-only repair authority in active review surfaces.

## Task 2: Define Agent-Native Bounded Review Skills

- task_id: review-native-020
- depends_on:
  - review-native-010
- scope_slice: rewrite design, plan, and implementation review components around bounded briefs, causal candidates, portable subagent preference, and direct-review fallback
- impl_file_refs:
  - src/skills/review-components/review-design
  - src/skills/review-components/review-plan
  - src/skills/review-components/review-implementation
  - contracts/skills.toml
- test_file_refs:
  - src/skills/_internal/_harness-libs/smoke-test
  - tests
- verification_scope:
  - `rg -n 'bounded review brief|introduced_by_change|regressed_by_change|activated_by_change|pre_existing|unrelated' src/skills/review-components`
  - `rg -n 'accepted|rejected_no_causal_link|rejected_pre_existing|rejected_out_of_scope|rejected_insufficient_evidence|deferred_followup|needs_plan_change' src/skills/review-components`
  - `bash src/skills/_internal/_harness-libs/smoke-test/test-review-execute-command-control.sh`
- executor_mode: inline-serial
- task_review_depth: boundary
- done_when:
  - all review components describe review work without external CLI, model, provider, or same-driver concepts
  - reviewer context defaults to the approved task slice, exact diff, tests, oracles, and justified supporting-file allowlist
  - unchanged files may be read only as direct dependencies necessary to judge changed behavior
  - findings are candidate evidence with causality and approved-contract linkage rather than automatic repair commands
  - skills prefer a reviewer subagent for non-trivial work, permit main-agent review, and prevent recursive delegation
  - public review entry skills allow subagent use by the main agent while runtime instructions deny delegated-review recursion
- rollback_on_failure: rollback-required

Steps:

- [ ] Replace invocation and runner sections with a portable agent-native role contract.
- [ ] Add the bounded review brief and supporting-file justification rules to each review mode, scaled to design, plan, or implementation artifacts.
- [ ] Replace exhaustive/adversarial prompt guidance with task-slice correctness and PASS-when-acceptance-is-met guidance.
- [ ] Replace severity-driven blocking semantics with causal candidate semantics and omit/defer rules for pre-existing, unrelated, adjacent, and future-phase concerns.
- [ ] Remove provider-specific CLI examples, reviewer security rules tied to external processes, and runner-schema output requirements from active skill references.
- [ ] Set public review entry skills to allow subagent capability, require the review brief to identify `main` versus `delegated` actor role, and forbid reviewer subagents from spawning another reviewer.

## Task 3: Make Main-Agent Adjudication The Repair Gate

- task_id: review-native-030
- depends_on:
  - review-native-020
- scope_slice: update review-change and implement-change so the main agent constructs review briefs, adjudicates candidates, and repairs only accepted causally linked findings
- impl_file_refs:
  - src/skills/workflows/review-change
  - src/skills/workflows/implement-change
  - src/skills/workflows/implement-change/references
  - contracts/skills.toml
- test_file_refs:
  - src/skills/_internal/_harness-libs/smoke-test
  - tests
- verification_scope:
  - `bash src/skills/_internal/_harness-libs/smoke-test/test-agent-native-review.sh`
  - `bash src/skills/_internal/_harness-libs/smoke-test/test-execute-runner.sh`
  - `bash src/skills/_internal/_harness-libs/smoke-test/test-review-execute-command-control.sh`
- executor_mode: inline-serial
- task_review_depth: boundary
- done_when:
  - review-change produces a main-agent disposition for every material candidate
  - implement-change repairs only `accepted` candidates and records why each was accepted
  - pre-existing, unrelated, insufficient-evidence, and out-of-scope candidates cannot enter local repair
  - plan/design expansion exits through `needs_plan_change` or the existing typed design/authority boundary
  - later review focuses on accepted-finding closure and repair-introduced regressions instead of reopening full-repository discovery
  - the old expected-five/hard-ten review contract is absent; normal flow is initial bounded review plus focused verification, with at most one additional same-slice repair attempt before typed stop
- rollback_on_failure: rollback-required

Steps:

- [ ] Add bounded review-brief construction to the top-level review gate and implementation controller.
- [ ] Define candidate adjudication and require a concise main-agent reason for accepted or materially rejected findings.
- [ ] Remove any rule that trusts reviewer severity or self-assigned scope classification as sufficient repair authority.
- [ ] Update the repair-loop contract so verification review cannot reopen unrelated discovery.
- [ ] Replace the expected-five/hard-ten loop with initial bounded review, accepted repair, focused verification, at most one additional same-slice repair attempt for a proven incomplete or regressive repair, and typed stop states.

## Task 4: Retire External Review Orchestration And Preserve Harness Contracts

- task_id: review-native-040
- depends_on:
  - review-native-030
- scope_slice: remove external semantic reviewer runners/drivers/schemas and relocate artifact-DAG validation required by non-review harness workflows
- impl_file_refs:
  - src/skills/_internal/_review-libs
  - src/skills/_internal/_harness-libs
  - contracts/skills.toml
- test_file_refs:
  - src/skills/_internal/_harness-libs/smoke-test
  - src/skills/_internal/_review-libs/smoke-test
  - tests
- verification_scope:
  - `bash -n src/skills/_internal/_harness-libs/artifact-dag.sh`
  - `bash src/skills/_internal/_harness-libs/smoke-test/test-plan-runner.sh`
  - `bash src/skills/_internal/_harness-libs/smoke-test/test-execute-runner.sh`
  - `bash src/skills/_internal/_harness-libs/smoke-test/test-truth-sync-runner.sh`
  - `git diff --check`
- executor_mode: inline-serial
- task_review_depth: boundary
- done_when:
  - `run-review.sh` and external reviewer drivers are absent from active source and generated runtime support
  - prompt-builder, reviewer-workspace, reviewer-output normalization/schema, health/eval, and runner-only smoke code are removed when they have no remaining owner
  - artifact-DAG parsing and allowed-touch-set helpers live under `_harness-libs`
  - design, plan, execute, and truth-sync runners source the relocated deterministic helper and retain prior validation behavior
  - no dormant provider/tool review adapter remains as a fallback
- rollback_on_failure: rollback-required

Steps:

- [ ] Build an exact dependency inventory of `_review-libs` and classify every file as delete, relocate, or retain-with-new-owner before deletion.
- [ ] Move `artifact-dag.sh` and its still-relevant tests to `_harness-libs`, updating all source paths atomically.
- [ ] Remove `run-review.sh`, model/provider drivers, prompt builder, semantic workspace builder, reviewer schemas/normalizers, runner health/eval code, and runner-specific smoke fixtures after consumers are removed.
- [ ] Remove review-gate/review-runner shell layers whose only purpose was invoking or validating external semantic reviewers.
- [ ] Replace their deterministic smoke coverage with `test-agent-native-review.sh` and focused artifact-DAG/harness tests; do not retain a runner-named compatibility shim.
- [ ] Preserve ordinary executable-oracle commands in their product or harness owners instead of deleting them with the reviewer runner.

## Task 5: Update Commands, Stable Truth, And Generated Surfaces

- task_id: review-native-050
- depends_on:
  - review-native-040
- scope_slice: remove retired runner semantics from command entry points and stable docs, regenerate install surfaces, and keep active architecture truth aligned
- impl_file_refs:
  - commands
  - AGENTS.md
  - README.md
  - docs/architecture
  - contracts
  - scripts
  - src/skills
  - skills.index.json
  - skills
- test_file_refs:
  - src/skills/_internal/_harness-libs/smoke-test
  - tests
- verification_scope:
  - `python3 scripts/generate-skills-index.py`
  - `python3 scripts/flatten-skills.py --target root-flat`
  - `python3 scripts/generate-workflow-diagrams.py`
  - `bash scripts/check.sh`
  - `bash skills/_harness-libs/smoke-test/test-sovereign-command-surface.sh`
  - `bash skills/_harness-libs/smoke-test/test-design-plan-command-control.sh`
  - `bash skills/_harness-libs/smoke-test/test-review-execute-command-control.sh`
  - `uvx --with pyyaml python "$HOME/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py" .`
- executor_mode: inline-serial
- task_review_depth: boundary
- done_when:
  - command entry points instruct the coding agent to construct bounded review briefs and prefer subagent review without invoking external scripts
  - active stable docs no longer describe same-driver, cross-model, adversarial, provider-selected, or reviewer-CLI workflows
  - historical plans remain unchanged
  - generated skill and internal-support surfaces contain no retired runner files
  - aggregate and plugin validation pass
- rollback_on_failure: rollback-required

Steps:

- [ ] Replace command-level runner discovery/invocation with thin agent-native review instructions and main-agent adjudication flow.
- [ ] Update AGENTS, README, workflow architecture, diagrams, and validation commands to the new review ownership model.
- [ ] Remove retired smoke commands from aggregate checks and add bounded-review contract checks.
- [ ] Regenerate root-flat and temporary target-specific install surfaces from source.
- [ ] Search active source, commands, stable docs, and generated output for retired runner/provider/adversarial terminology while excluding historical `docs/plans/`.

## Task 6: Run Agent-Native Forward Tests And Final Review

- task_id: review-native-060
- depends_on:
  - review-native-050
- scope_slice: prove that bounded review works through preferred subagent interaction and direct main-agent fallback without external reviewer tooling or scope expansion
- impl_file_refs:
  - src/skills
  - contracts
  - commands
  - docs/architecture
- test_file_refs:
  - tests
  - src/skills/_internal/_harness-libs/smoke-test
- verification_scope:
  - `bash scripts/check.sh`
  - `git diff --check`
  - fresh non-trivial bounded-review probe with reviewer subagent
  - fresh trivial mechanical-review probe with main-agent review
  - fresh out-of-scope critical-observation probe requiring main-agent escalation without repair
- executor_mode: fresh-agent-behavioral-probes
- task_review_depth: boundary
- done_when:
  - a non-trivial fixture uses a reviewer subagent when the host supports delegation and returns candidate findings to the main agent
  - a trivial mechanical fixture is allowed to remain with the main agent and does not create ceremony or false blockers
  - moved-but-unchanged code does not cause pre-existing defects to enter the repair batch
  - a real changed-behavior acceptance violation is accepted and repaired
  - an incidental critical issue outside scope is escalated without mutation or plan expansion
  - no probe invokes an external reviewer CLI, selects another model/provider, or delegates recursively
  - final main-agent review confirms the implementation stayed within this design and plan
- rollback_on_failure: manual-checkpoint

Steps:

- [ ] Create or reuse minimal isolated fixtures for mechanical move, changed behavior, and incidental out-of-scope critical evidence.
- [ ] Give each reviewer only the bounded review brief and record every supporting file it reads.
- [ ] Confirm the main agent emits dispositions before any repair and that only `accepted` findings are fixed.
- [ ] Re-run deterministic aggregate checks after behavioral probes.
- [ ] Record final PASS or a typed manual stop without extending the approved milestone.

## Human Gate

- approval_required: true
- approval_status: approved
- approval_effect: approval authorizes continuous execution of `review-native-010` through `review-native-060`; no commit or push is included unless separately requested
- next_entry: implement-change

## Rollback

- Revert the source and generated changes as one unit if agent-native review cannot preserve bounded context, causal findings, or main-agent adjudication.
- Restore relocated artifact-DAG support to its previous path if any design/plan/execute/truth-sync contract regresses.
- Do not restore individual external provider drivers or runner fragments as an undocumented fallback.
- Preserve this design and plan as historical evidence even if implementation rolls back.
- rollback_entry: design-change
