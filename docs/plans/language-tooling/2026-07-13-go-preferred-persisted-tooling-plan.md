# Go-Preferred Persisted Tooling Skill Boundary Implementation Plan

Goal: separate plan-time implementation-language selection from agent ad hoc command composition, make persisted Shell escalation language-neutral with a non-mandatory Go preference, split Go guidance into CLI-tool and API-service profiles, and preserve existing Python project stability.

Architecture: `plan-change` conditionally composes `language-decision-tree` for new persisted implementation boundaries; `tool-decision-tree` owns temporary agent command composition; `shell-guidelines` detects when persisted Shell should be reconsidered without mandating a replacement language; `go-guidelines` provides a shared baseline plus purpose-specific CLI and API references; `python-guidelines` continues to maintain approved Python implementations.

Tech Stack: Markdown skill contracts and references, Python unittest contract checks, Bash harness validation, generated root-flat/Claude/Codex skill surfaces, and stable routing documentation.

## Upstream Design

- design_ref: docs/plans/language-tooling/2026-07-13-go-preferred-persisted-tooling-design.md
- design_version: 2026-07-13-approved-boundary

## Implementation Scope

- scope_slice: plan-time language routing, ad hoc command-composition safety, persisted Shell escalation, Go CLI/API progressive disclosure, minimal Python boundary correction, contract tests, generated surfaces, and stable routing truth
- impl_file_refs:
  - AGENTS.md
  - README.md
  - docs/architecture
  - src/skills/disciplines/language-decision-tree
  - src/skills/disciplines/tool-decision-tree
  - src/skills/policies/go-guidelines
  - src/skills/policies/python-guidelines
  - src/skills/policies/shell-guidelines
  - src/skills/session/use-coding-skills
  - src/skills/workflows/plan-change
  - skills
- test_file_refs:
  - tests
  - docs/plans/language-tooling/2026-07-13-go-preferred-persisted-tooling-plan.md
- verification_scope:
  - `bash src/skills/_internal/_harness-libs/design-runner.sh validate docs/plans/language-tooling/2026-07-13-go-preferred-persisted-tooling-design.md`
  - `PLAN_RUNNER_TASK_METADATA_MODE=strict bash src/skills/_internal/_harness-libs/plan-runner.sh validate docs/plans/language-tooling/2026-07-13-go-preferred-persisted-tooling-plan.md`
  - `PYTHONDONTWRITEBYTECODE=1 PYTHONPYCACHEPREFIX="$HOME/.cache/python/market-csheng" python3 -m unittest tests.test_language_tooling_boundaries`
  - `python3 scripts/generate-skills-index.py`
  - `python3 scripts/flatten-skills.py --target root-flat`
  - `python3 scripts/generate-workflow-diagrams.py`
  - `bash scripts/check.sh`
  - `bash skills/_harness-libs/smoke-test/test-design-plan-command-control.sh`
  - `bash skills/_harness-libs/smoke-test/test-agent-native-review.sh`
  - `bash skills/_harness-libs/smoke-test/test-artifact-dag.sh`
  - `git diff --check`
- out_of_scope:
  - migration or rewrite of `../homelab-config` tools
  - changes to existing Python project dependency stacks
  - mandatory Go for all automation
  - universal prohibition of inline or nested interpreters
  - plugin version bump, installation, commit, push, or deployment
  - sovereign harness phase or approval-gate redesign
- divergence_from_design: none

## Work Package Readiness

- milestone_objective: deliver one coherent skill contract that routes new persisted implementation choices through planning, keeps ad hoc command composition with the tool decision tree, prefers but does not mandate Go for long-lived operational tooling, and gives Go CLI and API work separate architecture references
- non_goals:
  - rewrite existing product code or sibling repositories
  - remove Python or Shell as supported implementation languages
  - prescribe one Go framework for every project
- future_phase:
  - audit `../homelab-config` against the resulting migration triggers
  - select and plan a separate Go pilot only after the skill contract is verified
- decision_status: ready_for_review
- oracle_strategy: contract tests for skill ownership and negative wording, characterization of existing Python maintenance guarantees, artifact-DAG validation for the design and plan, and generation checks for install-surface parity
- acceptance_oracles:
  - `language-decision-tree` explicitly applies to design and plan decisions for new persisted implementations and excludes agent ad hoc command choice
  - `plan-change` conditionally records implementation archetype, language, and rationale when a task introduces or replaces a persisted code boundary
  - `tool-decision-tree` prefers direct and single-layer commands, routes procedural ad hoc logic to reviewable external scratch scripts, and uses avoid rather than blanket forbid semantics for nested Shell and Python
  - hard prohibitions for ad hoc composition are limited to uncontrolled code execution, untrusted interpolation, and opaque irreversible mutation without preview
  - `shell-guidelines` no longer names Python as the required escalation target and expresses Go only as a preference for suitable long-lived tooling
  - `go-guidelines` exposes separate CLI-tool and API-service references with shared Go defaults and optional project-specific analyzers
  - `python-guidelines` retains uv, Ruff, ty, pytest, cache isolation, dependency preflight, and existing-project maintenance semantics
  - root-flat and temporary target install surfaces remain synchronized with source skills
  - aggregate validation and focused harness smoke tests pass
- execution_continuity: continuous_after_plan_approval
- max_review_batches: 2
- subagent_ready: true

## Execution Continuity

- execution_mode: continuous_after_plan_approval
- confirmation_clearance:
  - C0: approving this plan authorizes the complete repo-local source, reference, test, generated-surface, and stable-routing update without additional implementation checkpoints
- runtime_contingencies:
  - X1: stop and return to design if a current harness contract requires `language-decision-tree` to govern ad hoc execution rather than only persisted implementation planning
  - X2: stop and replan if conditional plan-time language metadata requires a machine-schema or task-ledger change beyond skill and contract-test wording
  - X3: stop before removing or renaming the existing Go service reference if an active source consumer outside the approved touch set is discovered
  - X4: stop for focused repair if generated install surfaces or aggregate checks reveal a source/generated boundary regression
- planned_stop_points: []
- task_ordering_rationale: establish the shared test harness and freeze existing Python maintenance behavior first, then add and satisfy task-scoped language-routing, ad hoc and Shell, and Go-profile oracles in dependency order before synchronizing stable routing truth, generated surfaces, and aggregate validation

## Review Gate

- required_entry: review-change
- required_mode: review-only
- task_review_default_depth: boundary
- final_review_default_depth: boundary
- planning_review_method: one delegated reviewer receives only the approved design, this plan, the artifact validation results, and the directly named source references; the main agent adjudicates candidate findings and applies only accepted in-scope plan repairs
- review_status: pass
- review_batches: 2
- review_evidence: the initial bounded review found that preloading all future contract tests would make Tasks 1 through 3 fail on downstream red tests; the accepted repair made Task 1 a passing characterization harness and moved each new failing oracle into its owning Task 2, 3, or 4; focused re-review passed without additional findings

## Task 1: Freeze Existing Python Contracts And Establish The Test Harness

- task_id: language-tooling-010
- depends_on:
  - root
- scope_slice: establish the focused contract-test harness and characterize existing Python maintenance guarantees without preloading failing assertions owned by later tasks
- impl_file_refs:
  - tests
- test_file_refs:
  - tests
- verification_scope:
  - `PYTHONDONTWRITEBYTECODE=1 PYTHONPYCACHEPREFIX="$HOME/.cache/python/market-csheng" python3 -m unittest tests.test_language_tooling_boundaries`
  - `git diff --check`
- executor_mode: inline-serial
- task_review_depth: boundary
- done_when:
  - the focused test module loads and runs independently
  - characterization tests preserve uv, Ruff, ty, pytest, project ownership, dependency preflight, and cache-isolation semantics
  - shared helpers support later positive and negative source-contract assertions without treating unimplemented later tasks as current-task failures
  - no assertion owned by Tasks 2 through 4 is added early as an unresolved red test
- rollback_on_failure: rollback-required

Steps:

- [ ] Add `tests/test_language_tooling_boundaries.py` with shared source-reading helpers and characterization assertions for the existing Python maintenance boundary.
- [ ] Cover uv, Ruff, ty, pytest, project ownership, dependency preflight, and cache isolation without changing `python-guidelines`.
- [ ] Run the focused module to a passing state before closing Task 1.
- [ ] Leave plan-routing, ad hoc composition, Shell escalation, and Go-profile assertions to the tasks that own those changes.

## Task 2: Route New Persisted Implementations Through Planning

- task_id: language-tooling-020
- depends_on:
  - language-tooling-010
- scope_slice: narrow `language-decision-tree` to new persisted implementation decisions and conditionally compose it from `plan-change`
- impl_file_refs:
  - src/skills/disciplines/language-decision-tree
  - src/skills/workflows/plan-change
  - src/skills/session/use-coding-skills
- test_file_refs:
  - tests
- verification_scope:
  - `PYTHONDONTWRITEBYTECODE=1 PYTHONPYCACHEPREFIX="$HOME/.cache/python/market-csheng" python3 -m unittest tests.test_language_tooling_boundaries`
  - `rg -n 'implementation_archetype|implementation_language|language_rationale|persisted' src/skills/workflows/plan-change src/skills/disciplines/language-decision-tree`
  - `git diff --check`
- executor_mode: inline-serial
- task_review_depth: boundary
- done_when:
  - the language skill description and scope target design and plan work for new persisted projects, tools, services, and migrations
  - existing-language edits and agent ad hoc command composition are explicit non-triggers
  - `plan-change` conditionally invokes the language decision when a task creates or replaces a persisted implementation boundary
  - relevant plan tasks record implementation archetype, language, and rationale without changing top-level lifecycle authority
  - session routing distinguishes persisted language selection from ad hoc tool selection
- rollback_on_failure: rollback-required

Steps:

- [ ] Add task-scoped tests for persisted-only language selection, explicit ad hoc exclusion, and conditional plan metadata; confirm the new assertions fail for the intended missing contract before editing source.
- [ ] Rewrite the language decision entry conditions around persisted implementation boundaries rather than general command complexity.
- [ ] Preserve existing-language-by-default behavior and record explicit migration triggers instead of authorizing incidental rewrites.
- [ ] Add conditional language-selection metadata guidance to `plan-change`; do not make irrelevant docs-only or existing-language tasks carry placeholder fields.
- [ ] Update session routing so agents can select the correct skill without a mandatory bootstrap sequence.

## Task 3: Make Ad Hoc Composition Reviewable And Shell Escalation Language-Neutral

- task_id: language-tooling-030
- depends_on:
  - language-tooling-020
- scope_slice: give `tool-decision-tree` explicit ad hoc composition ownership, replace fragile inline fallback examples, and remove Python-only escalation from Shell guidance
- impl_file_refs:
  - src/skills/disciplines/tool-decision-tree
  - src/skills/policies/shell-guidelines
  - src/skills/policies/python-guidelines
- test_file_refs:
  - tests
- verification_scope:
  - `PYTHONDONTWRITEBYTECODE=1 PYTHONPYCACHEPREFIX="$HOME/.cache/python/market-csheng" python3 -m unittest tests.test_language_tooling_boundaries`
  - `rg -n 'AVOID|scratch|preview|untrusted|irreversible' src/skills/disciplines/tool-decision-tree src/skills/policies/shell-guidelines`
  - `git diff --check`
- executor_mode: inline-serial
- task_review_depth: boundary
- done_when:
  - direct tools and simple single-layer commands precede procedural scratch scripts in ad hoc selection
  - nested `bash -c` plus `python -c`, Shell heredoc Python, and generated code strings use avoid-by-default semantics rather than a universal prohibition
  - uncontrolled input interpolation and opaque irreversible mutation retain hard safety constraints
  - structured ad hoc Python fallbacks use a reviewable repo-external scratch script instead of nested inline source
  - Shell escalation is capability-based, language-neutral, and only prefers Go when its operational fit is material
  - Python maintenance rules remain intact and inline examples no longer contradict the composition boundary
- rollback_on_failure: rollback-required

Steps:

- [ ] Add task-scoped tests for direct-tool preference, reviewable scratch scripts, avoid semantics, hard mutation safety boundaries, language-neutral Shell escalation, and minimal Python preservation; confirm the intended failures before editing source.
- [ ] Add `references/adhoc-command-composition.md` under `tool-decision-tree` and keep the main skill as the compact routing surface.
- [ ] Replace `python3 -c` and Python heredoc fallback examples with scratch-script invocation guidance while retaining stdlib-only and uvx dependency boundaries.
- [ ] Distinguish avoid guidance from hard prohibitions and anchor irreversible operations to COUNT, PREVIEW, rollback, and exact-target validation.
- [ ] Replace line-count and Python-specific Shell escalation rules with capability signals and a non-mandatory Go preference.
- [ ] Make only the minimal Python wording and example edits required for consistency.

## Task 4: Split Go Guidance Into CLI Tool And API Service Profiles

- task_id: language-tooling-040
- depends_on:
  - language-tooling-030
- scope_slice: establish a shared Go baseline and two purpose-specific progressive-disclosure references with explicit architecture and library-selection rules
- impl_file_refs:
  - src/skills/policies/go-guidelines
- test_file_refs:
  - tests
- verification_scope:
  - `PYTHONDONTWRITEBYTECODE=1 PYTHONPYCACHEPREFIX="$HOME/.cache/python/market-csheng" python3 -m unittest tests.test_language_tooling_boundaries`
  - `rg -n 'cli-tool-patterns.md|api-service-patterns.md' src/skills/policies/go-guidelines/SKILL.md`
  - `test -f src/skills/policies/go-guidelines/references/cli-tool-patterns.md`
  - `test -f src/skills/policies/go-guidelines/references/api-service-patterns.md`
  - `git diff --check`
- executor_mode: inline-serial
- task_review_depth: boundary
- done_when:
  - the shared Go skill covers modules, formatting, compile and vet, errors, context, tests, tool dependencies, and source hygiene without forcing a framework
  - the CLI profile selects standard `flag` for small commands and Cobra for growing formal CLIs while covering completion, adapters, IO, safety, tests, build, and distribution
  - the API profile defaults to `net/http`, preserves existing framework choices, and covers server lifecycle, boundaries, middleware, health, observability, security, tests, and delivery
  - golangci-lint is project-configured rather than universally required
  - custom error types and interfaces are introduced only when callers or boundaries need them
  - the Go review checklist evaluates the selected purpose profile instead of applying one service structure to every Go file
- rollback_on_failure: rollback-required

Steps:

- [ ] Add task-scoped tests for both Go purpose references, shared standard-toolchain defaults, optional project analyzers, and conditional error/interface rules; confirm the intended failures before editing source.
- [ ] Rewrite the shared deterministic baseline around standard Go toolchain checks and project-owned optional analyzers.
- [ ] Add `cli-tool-patterns.md` with selection, architecture, library, safety, test, and delivery guidance.
- [ ] Replace the generic service reference with `api-service-patterns.md`, preserving existing Gin or other framework projects while defaulting new simple services to `net/http`.
- [ ] Update the Go review checklist to detect the project archetype and load only the matching reference.
- [ ] Keep library recommendations criterion-based and avoid version pinning in prose.

## Task 5: Synchronize Stable Routing, Generated Surfaces, And Final Verification

- task_id: language-tooling-050
- depends_on:
  - language-tooling-040
- scope_slice: align stable repository routing, regenerate install surfaces, run aggregate validation, and perform the final bounded implementation review
- impl_file_refs:
  - AGENTS.md
  - README.md
  - docs/architecture
  - skills
- test_file_refs:
  - tests
  - docs/plans/language-tooling/2026-07-13-go-preferred-persisted-tooling-plan.md
- verification_scope:
  - `python3 scripts/generate-skills-index.py`
  - `python3 scripts/flatten-skills.py --target root-flat`
  - `python3 scripts/generate-workflow-diagrams.py`
  - `bash scripts/check.sh`
  - `bash skills/_harness-libs/smoke-test/test-design-plan-command-control.sh`
  - `bash skills/_harness-libs/smoke-test/test-agent-native-review.sh`
  - `bash skills/_harness-libs/smoke-test/test-artifact-dag.sh`
  - `git diff --check`
- executor_mode: inline-serial
- task_review_depth: boundary
- done_when:
  - root and session routing describe plan-time persisted language selection separately from ad hoc tool composition
  - workflow architecture records the conditional plan-time policy overlay without changing sovereign phase ownership
  - README inventory describes the two Go purpose profiles and the narrowed language/tool decision responsibilities
  - generated root-flat, Claude, and Codex install surfaces pass source-map and parity checks
  - the focused contract tests, aggregate validation, required smoke tests, and final bounded review pass
  - no sibling repository, plugin installation, commit, push, or deployment change is included
- rollback_on_failure: rollback-required

Steps:

- [ ] Update only stable routing summaries affected by the new ownership model; do not duplicate detailed reference content into root docs.
- [ ] Regenerate the tracked root-flat skill surface and target-specific temporary validation surfaces from source.
- [ ] Run focused contract tests, aggregate checks, artifact-DAG smoke tests, and `git diff --check`.
- [ ] Build a bounded implementation-review brief containing the approved design, plan, exact diff, focused tests, aggregate evidence, and justified direct dependencies.
- [ ] Adjudicate reviewer candidates and repair only accepted findings inside the approved touch set, followed by focused verification.

## Human Gate

- approval_required: true
- approval_status: approved
- approval_effect: approval authorizes continuous serial execution of `language-tooling-010` through `language-tooling-050`; it does not authorize changes to sibling repositories, plugin installation, commit, push, or deployment
- next_entry: implement-change

## Rollback

- Revert source skills, tests, stable routing docs, and generated root-flat output as one coherent unit if ownership contract tests or aggregate validation cannot pass.
- Restore `service-patterns.md` and its original progressive-disclosure link if renaming it breaks an active consumer that cannot be updated inside the approved touch set.
- Keep Python toolchain and cache-isolation behavior unchanged if minimal example cleanup causes project-maintenance drift.
- Do not partially retain plan-time routing if `language-decision-tree` and `tool-decision-tree` ownership remains ambiguous after focused repair.
- Preserve this approved design and pending plan as stage-history artifacts even if implementation is rolled back.
- rollback_entry: plan-change
