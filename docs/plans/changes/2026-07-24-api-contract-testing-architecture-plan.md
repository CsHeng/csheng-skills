# API Contract And Layered Testing Architecture Implementation Plan

## Upstream Design

- design_ref: docs/plans/changes/2026-07-24-api-contract-testing-architecture-design.md
- design_version: 1

## Implementation Scope

- impl_file_refs:
  - src/skills/disciplines/api-contract-strategy
  - src/skills/disciplines/testing-strategy
  - src/skills/disciplines/executable-oracle-architecture-selector/SKILL.md
  - contracts/skills.toml
  - README.md
  - skills.index.json
  - skills/.source-map.json
  - skills/api-contract-strategy
  - skills/testing-strategy
  - skills/executable-oracle-architecture-selector/SKILL.md
- test_file_refs:
  - tests/test_api_contract_strategy_contracts.py
- verification_scope:
  - Focused API-contract skill contract tests with a recorded red-green transition
  - Skill-creator quick validation for the new and materially revised source skills
  - Manifest, index, and root-flat source-generation checks
  - Aggregate repository validation
  - Agent-native review and artifact-DAG smoke tests
  - Docs-boundary and Markdown whitespace checks
  - Independent forward-test using a realistic multi-client legacy API assessment prompt

## Work Package Readiness

- milestone_objective: Add one lower-plane API-contract discipline and refactor concrete testing guidance around explicit verification boundaries without changing sovereign workflow authority.
- non_goals:
  - Add a top-level command, lifecycle controller, runtime contract, or repair owner.
  - Make OpenAPI, Pact, Bruno, generated SDKs, a contract repository, or fixed coverage thresholds universal defaults.
  - Implement any `sms-gw` application change from this repository.
- future_phase:
  - Add helper scripts only after repeated usage proves deterministic automation is needed beyond prose and focused tests.
  - Consider stronger machine-readable assessment schemas only if ordinary skill output repeatedly drifts.
  - Revisit generic language examples in `testing-strategy` only if a later audit proves they conflict with the new boundary model.
- decision_status: ready_for_review
- oracle_strategy: Contract-test-first for ownership, routing, progressive disclosure, and rejected defaults; then source validation, deterministic generation, aggregate checks, bounded review, and an independent qualitative forward-test.
- acceptance_oracles:
  - The focused test fails before implementation because the new source skill and revised contracts are absent, then passes after the source changes.
  - Skill validation accepts the new and revised source skill folders.
  - Manifest and generated surfaces expose exactly one new lower-plane discipline with no lifecycle authority.
  - Aggregate checks and required review/artifact smoke tests pass without unrelated generated drift.
  - A fresh agent given an `sms-gw`-like prompt separates contract, provider, consumer, workflow, and UI verification and rejects premature Pact, a separate contract repository, and blanket test growth.
- execution_continuity: continuous_after_plan_approval
- max_review_batches: 2
- subagent_ready: true

## Execution Continuity

- execution_mode: continuous_after_plan_approval
- confirmation_clearance:
  - C0: Approval of this plan authorizes T1 through T5 as one serial repository-local implementation unit.
- runtime_contingencies:
  - X1: Stop with `needs-design-decision` if implementing the new discipline requires a sovereign command, runtime-contract edge, or ownership transfer not present in the approved design.
  - X2: Stop and diagnose before repair if source flattening changes unrelated skills or manifest generation exposes a collision with an existing public id.
  - X3: Treat a forward-test that recommends a universal tool stack, test-count growth, or a second lifecycle authority as an in-scope verification failure.
  - X4: Stop with `needs-plan-change` if focused tests can protect the wording only through brittle full-document snapshots rather than semantic ownership assertions.
- planned_stop_points:
  - none
- task_ordering_rationale: Establish semantic oracles first, implement the new owner before revising its neighboring skills, then register and generate the public surface, and finish with the widest deterministic and qualitative checks.

## Task 1: Add the failing API-contract skill oracle

- task_id: T1
- depends_on:
  - none
- scope_slice: Add focused source-level tests for the new discipline, corrected verification topology, ownership separation, progressive-disclosure references, conditional tool decisions, testing-strategy refactor, registration, and generated exposure.
- impl_file_refs:
  - tests/test_api_contract_strategy_contracts.py
- test_file_refs:
  - tests/test_api_contract_strategy_contracts.py
- verification_scope:
  - Run `python3 -m unittest tests.test_api_contract_strategy_contracts` before source implementation and record failures caused by the absent skill and old testing contracts.
  - Inspect assertions to ensure they protect stable semantics rather than complete prose snapshots.
- executor_mode: main
- task_review_depth: focused
- done_when:
  - The test module is syntactically valid and fails for the intended missing behavior.
  - Assertions cover single-owner routing, layer topology, schema-versus-semantic compatibility, conditional CDC/repository/generation choices, coverage-threshold removal, and manifest/generated registration.
  - The test does not require exact vendor versions or duplicate the complete skill text.
- rollback_on_failure: Narrow or remove only assertions that exceed the approved design; do not weaken approved ownership or verification-layer semantics.

## Task 2: Add the API contract strategy discipline

- task_id: T2
- depends_on:
  - T1
- scope_slice: Create the concise source skill, OpenAI metadata, and four directly linked references for verification layers, lifecycle, legacy adoption, and tool selection.
- impl_file_refs:
  - src/skills/disciplines/api-contract-strategy
- test_file_refs:
  - tests/test_api_contract_strategy_contracts.py
- verification_scope:
  - Run the focused contract test.
  - Run `python3 "$HOME/.codex/skills/.system/skill-creator/scripts/quick_validate.py" src/skills/disciplines/api-contract-strategy`.
  - Inspect links to confirm every reference is one level below `SKILL.md` and no required reference is orphaned.
- executor_mode: main
- task_review_depth: boundary
- done_when:
  - `SKILL.md` has a clear trigger, non-trigger, ownership model, compact decision workflow, and output contract.
  - The references contain the detailed topology, lifecycle, migration, tool-cost, alternatives, rejected approaches, and upgrade triggers.
  - The comprehensive six-part assessment shape is conditional rather than imposed on ordinary conversational output.
  - The skill does not claim lifecycle, mutation, review, or repair authority.
- rollback_on_failure: Remove the new source skill as one unit and return to the approved design if ownership cannot remain distinct from existing oracle, architecture, and workflow skills.

## Task 3: Refactor testing guidance and add the bounded selector route

- task_id: T3
- depends_on:
  - T2
- scope_slice: Replace universal coverage and vendor-specific CI guidance with boundary-owned verification mapping, and add only the approved multi-client API cross-route to the executable-oracle selector.
- impl_file_refs:
  - src/skills/disciplines/testing-strategy
  - src/skills/disciplines/executable-oracle-architecture-selector/SKILL.md
- test_file_refs:
  - tests/test_api_contract_strategy_contracts.py
- verification_scope:
  - Run the focused contract test.
  - Run skill-creator quick validation for both revised source skill folders.
  - Inspect the diff for preserved red-green, oracle-edit, isolation, and language-example guidance.
  - Confirm `references/ci-config.md` describes capabilities and deterministic readiness rather than one CI provider.
- executor_mode: main
- task_review_depth: boundary
- done_when:
  - No universal coverage percentage remains as a mandatory default.
  - Concrete strategy follows `boundary -> oracle -> fixture/environment -> owning suite -> CI/release lane -> diagnosis owner`.
  - Missing layers are not answered by duplicating endpoint or unit tests.
  - CI guidance separates static contract, compatibility, provider, consumer, workflow, E2E, and runtime evidence without hardcoded sleeps or fixed language versions.
  - The selector directs multi-client API decomposition to `api-contract-strategy` while retaining oracle-method authority.
- rollback_on_failure: Revert the testing and selector edits together while preserving the standalone new skill for another integration design pass.

## Task 4: Register, document, and generate the public skill surface

- task_id: T4
- depends_on:
  - T3
- scope_slice: Register the new discipline, update the human-facing inventory, regenerate the skill index and root-flat compatibility surface, and verify source/generated equality.
- impl_file_refs:
  - contracts/skills.toml
  - README.md
  - skills.index.json
  - skills/.source-map.json
  - skills/api-contract-strategy
  - skills/testing-strategy
  - skills/executable-oracle-architecture-selector/SKILL.md
- test_file_refs:
  - tests/test_api_contract_strategy_contracts.py
- verification_scope:
  - Run `python3 scripts/generate-skills-index.py`.
  - Run `python3 scripts/flatten-skills.py --target root-flat`.
  - Run the focused contract test and `python3 scripts/check-contracts.py`.
  - Compare changed root-flat files with their source equivalents and verify no unrelated generated skill changes.
- executor_mode: main
- task_review_depth: focused
- done_when:
  - `contracts/skills.toml` exposes the skill as an implicit non-mutating, non-spawning discipline for all three install surfaces.
  - README describes the ownership split among API contract, executable oracle, and concrete testing strategy without duplicating the references.
  - `skills.index.json` and all three changed root-flat skill surfaces are generator-owned and current.
  - The diff contains no command-surface or runtime-contract change.
- rollback_on_failure: Revert manifest and README changes, remove the generated new surface, and regenerate root-flat output from the pre-task source state; never hand-edit generated output to force equality.

## Task 5: Verify, forward-test, and review the complete slice

- task_id: T5
- depends_on:
  - T4
- scope_slice: Run the complete deterministic validation set, test the skill with a fresh bounded agent, and route the exact implementation diff through agent-native review.
- impl_file_refs:
  - src/skills/disciplines/api-contract-strategy
  - src/skills/disciplines/testing-strategy
  - src/skills/disciplines/executable-oracle-architecture-selector/SKILL.md
  - contracts/skills.toml
  - README.md
  - skills.index.json
  - skills/.source-map.json
  - skills/api-contract-strategy
  - skills/testing-strategy
  - skills/executable-oracle-architecture-selector/SKILL.md
- test_file_refs:
  - tests/test_api_contract_strategy_contracts.py
- verification_scope:
  - Run `python3 scripts/generate-skills-index.py`, `python3 scripts/flatten-skills.py --target root-flat`, and `python3 scripts/generate-workflow-diagrams.py`.
  - Run `bash scripts/check.sh`.
  - Run `bash skills/_harness-libs/smoke-test/test-agent-native-review.sh` and `bash skills/_harness-libs/smoke-test/test-artifact-dag.sh`.
  - Run `bash skills/organize-docs/scripts/check-doc-boundaries.sh` and `git diff --check`.
  - Forward-test the generated/root-flat skill with a fresh agent using a realistic legacy Go backend, Vue client, and firmware-client prompt without embedding the expected recommendation.
  - Review only the approved diff, declared oracles, command evidence, and named direct dependencies.
- executor_mode: main
- task_review_depth: full
- done_when:
  - Every declared deterministic command passes.
  - The forward-test produces meaningful verification boundaries, incremental adoption, operationally costed tool choices, and explicit rejected approaches without defaulting to more unit tests.
  - Main-agent adjudication leaves no accepted implementation finding unresolved within the review budget.
  - Final changes remain inside the approved implementation surface.
- rollback_on_failure: Apply the rollback of the first failing task; if focused repair cannot converge within two review batches, restore the pre-plan source/generated state and exit with the matching typed stop.

## Review Gate

- required_entry: review-change
- review_component: review-plan
- review_depth: boundary
- max_review_batches: 2
- review_status: passed
- review_evidence: One bounded independent plan review found no candidate findings.
- supporting_files:
  - AGENTS.md: source/generated ownership, lower-plane authority, validation, review, and docs-boundary contract.
  - docs/plans/changes/2026-07-24-api-contract-testing-architecture-design.md: approved goals, non-goals, ownership, topology, and implementation surface.
  - src/skills/workflows/plan-change/SKILL.md: execution-grade DAG, readiness, continuity, and human-gate requirements.
  - src/skills/disciplines/executable-oracle-architecture-selector/SKILL.md: existing oracle-method ownership.
  - src/skills/disciplines/testing-strategy/SKILL.md: current concrete testing guidance being refactored.
- pass_condition: The plan is a bounded serial DAG that implements the approved lower-plane ownership, declares executable semantic and generated-surface oracles, contains sufficient rollback, and does not introduce a second lifecycle authority.

## Human Gate

- approval_required: true
- approval_status: approved
- next_entry: implement-change

## Rollback

- rollback_entry: plan-change
- rollback_target: The clean current checkout before implementation, preserving the approved design and pending plan as stage history.
- rollback_trigger: Required lifecycle or command-surface expansion, ownership conflict with existing skills, brittle oracles, unrelated generated drift, aggregate validation failure that cannot be repaired in-scope, or a non-convergent forward-test/review loop.
