# Structured API Contract Stack Skill Implementation Plan

## Upstream Design

- design_ref: docs/plans/changes/2026-07-24-structured-api-contract-stack-skill-design.md
- design_version: 1

## Implementation Scope

- impl_file_refs:
  - src/skills/disciplines/api-contract-strategy/SKILL.md
  - src/skills/disciplines/api-contract-strategy/agents/openai.yaml
  - src/skills/disciplines/api-contract-strategy/references/structured-contract-stack.md
  - src/skills/disciplines/api-contract-strategy/references/verification-layers.md
  - src/skills/disciplines/api-contract-strategy/references/contract-lifecycle.md
  - src/skills/disciplines/api-contract-strategy/references/legacy-adoption.md
  - src/skills/disciplines/api-contract-strategy/references/tool-selection.md
  - tests/test_api_contract_strategy_contracts.py
  - README.md
  - skills.index.json
  - skills/.source-map.json
  - skills/api-contract-strategy
- test_file_refs:
  - tests/test_api_contract_strategy_contracts.py
- verification_scope:
  - Focused semantic red-green tests for authoring source, multi-file/bundle ownership, Arazzo/Respect, lifecycle glue, generated docs, and GUI rejection
  - Skill-creator validation and OpenAI metadata consistency
  - Source/index/root-flat deterministic generation
  - Aggregate repository and docs-boundary checks
  - Context-clean forward-test against a synthetic legacy multi-client API prompt

## Work Package Readiness

- milestone_objective: Upgrade only the reusable `api-contract-strategy` skill so it can guide projects toward a maintainable OpenAPI/Arazzo/Respect/Redocly structured contract stack without acquiring lifecycle authority or project-specific implementation knowledge.
- non_goals:
  - Modify or inspect `sms-gw`, implement an API contract, or choose concrete project versions/paths/workflows.
  - Change `testing-strategy`, the executable-oracle selector, architecture ownership, sovereign commands, runtime contracts, or repair control.
  - Add scripts, hosted services, GUI collections, or universal vendor mandates.
- future_phase:
  - Add executable helpers only if repeated cross-project use proves prose plus semantic tests insufficient.
  - Extend neighboring skills only if a later independent design finds an ownership gap.
  - Revisit tool recommendations when Arazzo runner interoperability materially changes.
- decision_status: ready_for_review
- oracle_strategy: Use contract-test-first semantic assertions for the reusable decision model, followed by skill schema validation, deterministic source-to-generated equality, aggregate repository checks, and a context-clean qualitative forward-test.
- acceptance_oracles:
  - Focused tests fail against the current skill because the structured stack, Arazzo/Respect, generated-doc, lifecycle-glue, and GUI-trigger semantics are absent.
  - Updated source keeps the main skill concise and routes detailed knowledge to one-level references.
  - Skill validation and metadata generation pass.
  - Root-flat generation reproduces source exactly with no unrelated generated drift.
  - A fresh agent given a synthetic large legacy API prompt recommends one structured truth stack, separates glue from workflows, and does not default to Bruno or handwritten API docs.
- execution_continuity: continuous_after_plan_approval
- max_review_batches: 2
- subagent_ready: true

## Execution Continuity

- execution_mode: continuous_after_plan_approval
- confirmation_clearance:
  - C0:
    - question: Does approval authorize T1 through T4 as one serial market-csheng-only skill update?
    - applies_to: T1-T4
    - resolution: pre_confirmed
    - default_if_unanswered: stop
- runtime_contingencies:
  - X1: Stop with `needs-design-decision` if the guidance cannot remain a lower-plane semantic overlay or requires changing another skill's authority.
  - X2: Stop with `needs-plan-change` if semantic protection requires brittle full-document snapshots rather than stable concept assertions.
  - X3: Stop and diagnose before repair if flattening changes unrelated skills or generated source mapping.
  - X4: Treat a forward-test that defaults to a GUI collection, parallel Markdown API catalog, project-specific versions, or duplicated Python HTTP workflow as an in-scope failure.
  - X5: Stop with `needs-plan-change` if accepted findings cannot converge within two bounded review batches.
- planned_stop_points:
  - none
- task_ordering_rationale: Freeze the reusable semantics in focused tests, update only the source skill and directly owned references, refresh metadata/generated surfaces after source stabilizes, and finish with aggregate validation plus a context-clean forward-test.

## Task 1: Add failing structured-contract semantic oracles

- task_id: T1
- depends_on:
  - none
- scope_slice: Extend the focused contract test with semantic assertions for authoring-source choice, domain-split OpenAPI and deterministic bundle ownership, generated projections, Arazzo/Respect roles, lifecycle glue, generated human docs, ad hoc single-operation CLI use, and GUI-only upgrade triggers.
- impl_file_refs:
  - tests/test_api_contract_strategy_contracts.py
- test_file_refs:
  - tests/test_api_contract_strategy_contracts.py
- verification_scope:
  - Run `python3 -m unittest tests.test_api_contract_strategy_contracts` before source edits and record failures caused by missing approved semantics.
  - Review assertions to ensure they accept equivalent concise wording and do not pin project paths, tool versions, or a complete prose snapshot.
- executor_mode: main
- task_review_depth: focused
- done_when:
  - Tests fail only for the newly approved knowledge delta.
  - Existing assertions for ownership, verification topology, conditional lifecycle, registration, and generated equality remain.
  - The Bruno assertion changes from positive default presence to conditional GUI/collaboration placement.
- rollback_on_failure: Narrow only brittle wording assertions while preserving every approved concept; stop under X2 if stable semantic assertions cannot express the design.

## Task 2: Update the source skill and one-level references

- task_id: T2
- depends_on:
  - T1
- scope_slice: Add the compact authoring/projection workflow and defaults to `SKILL.md`, create `structured-contract-stack.md`, and update only the lifecycle, legacy, tool, and verification references needed to keep details non-duplicated.
- impl_file_refs:
  - src/skills/disciplines/api-contract-strategy/SKILL.md
  - src/skills/disciplines/api-contract-strategy/references/structured-contract-stack.md
  - src/skills/disciplines/api-contract-strategy/references/verification-layers.md
  - src/skills/disciplines/api-contract-strategy/references/contract-lifecycle.md
  - src/skills/disciplines/api-contract-strategy/references/legacy-adoption.md
  - src/skills/disciplines/api-contract-strategy/references/tool-selection.md
- test_file_refs:
  - tests/test_api_contract_strategy_contracts.py
- verification_scope:
  - Run the focused contract test after source edits.
  - Run `python3 "$HOME/.codex/skills/.system/skill-creator/scripts/quick_validate.py" src/skills/disciplines/api-contract-strategy`.
  - Check reference links, line counts, imperative wording, and duplication between `SKILL.md` and references.
  - Inspect the diff to confirm no project-specific path, operation, secret, or version entered the reusable skill.
- executor_mode: main
- task_review_depth: full
- done_when:
  - `SKILL.md` remains below 220 lines and routes the integrated details directly to the new reference.
  - OpenAPI, bundle, generated code/docs, Arazzo, Respect, lifecycle glue, and optional GUI roles are unambiguous and non-overlapping.
  - OpenAPI-first is preferred conditionally; typed code-first and annotation-first have explicit completeness/staleness gates.
  - Redocly is recommended for the integrated capability set without requiring its hosted platform.
  - Existing lower-plane authority and conditional Pact/CDC/client/repository guidance remain intact.
- rollback_on_failure: Revert the source skill/reference delta as one slice while retaining T1's failing semantic oracle for a revised design.

## Task 3: Refresh metadata, inventory, and generated skill surfaces

- task_id: T3
- depends_on:
  - T2
- scope_slice: Align OpenAI metadata and the human skill inventory with the expanded trigger surface, regenerate the skill index and root-flat compatibility surface from source, and prove exact source/generated equality.
- impl_file_refs:
  - src/skills/disciplines/api-contract-strategy/agents/openai.yaml
  - README.md
  - skills.index.json
  - skills/.source-map.json
  - skills/api-contract-strategy
- test_file_refs:
  - tests/test_api_contract_strategy_contracts.py
- verification_scope:
  - Regenerate `agents/openai.yaml` with the skill-creator metadata generator and validate the short description/default prompt constraints.
  - Run `python3 scripts/generate-skills-index.py`.
  - Run `python3 scripts/flatten-skills.py --target root-flat`.
  - Run the focused contract test and compare source/root-flat skill trees.
- executor_mode: main
- task_review_depth: focused
- done_when:
  - Metadata triggers and default prompt reflect contract authoring, workflow, and generated projection decisions.
  - README inventory is concise and does not duplicate the skill body.
  - Generated files are current and no unrelated skill changes.
  - Manifest ownership/capability flags remain unchanged.
- rollback_on_failure: Revert metadata/inventory changes and regenerate root-flat from the pre-task source; never hand-edit generated output to force equality.

## Task 4: Validate and forward-test the isolated skill change

- task_id: T4
- depends_on:
  - T3
- scope_slice: Run the complete market-csheng validation surface and a fresh-agent forward-test using only a synthetic legacy API scenario plus the generated skill, then route the exact implementation diff through bounded implementation review.
- impl_file_refs:
  - src/skills/disciplines/api-contract-strategy
  - tests/test_api_contract_strategy_contracts.py
  - README.md
  - skills.index.json
  - skills/.source-map.json
  - skills/api-contract-strategy
- test_file_refs:
  - tests/test_api_contract_strategy_contracts.py
- verification_scope:
  - Run `python3 scripts/generate-skills-index.py`, `python3 scripts/flatten-skills.py --target root-flat`, and `python3 scripts/generate-workflow-diagrams.py`.
  - Run `bash scripts/check.sh`.
  - Run `bash skills/organize-docs/scripts/check-doc-boundaries.sh` and `git diff --check`.
  - Forward-test with a fresh agent using a synthetic large Go provider plus web/firmware clients, manual API Markdown, and Python smoke script; do not pass the intended recommendation or access the `sms-gw` repository.
  - Review only the approved market-csheng diff, declared oracles, and named direct dependencies.
- executor_mode: main
- task_review_depth: full
- done_when:
  - Every deterministic command passes.
  - The fresh agent selects a maintainable structured truth stack, distinguishes OpenAPI/Arazzo/runner/glue/docs, and gives explicit alternative triggers without defaulting to GUI duplication.
  - No `sms-gw` path, file, fact, or implementation change enters the diff or forward-test context.
  - Main-agent adjudication leaves no accepted implementation finding unresolved within the review budget.
- rollback_on_failure: Apply the rollback of the first failing task; if focused repair cannot converge within two review batches, restore the pre-plan source/generated state and exit through X5.

## Review Gate

- required_entry: review-change
- review_component: review-plan
- actor_role: delegated
- review_depth: boundary
- max_review_batches: 2
- review_status: passed
- review_evidence: One delegated bounded review found no candidate findings; it confirmed the T1-T4 DAG, reusable-skill-only boundary, executable semantic/generated oracles, rollback, continuity, and adjacent-skill authority.
- supporting_files:
  - AGENTS.md: source/generated ownership, lower-plane authority, validation, and review contract.
  - docs/AGENTS.md: stage artifact and stable truth boundary.
  - docs/plans/changes/2026-07-24-structured-api-contract-stack-skill-design.md: approved scope and reusable decision model.
  - src/skills/disciplines/api-contract-strategy/SKILL.md: current skill surface being extended.
  - src/skills/disciplines/api-contract-strategy/references/contract-lifecycle.md: current projection lifecycle guidance.
  - src/skills/disciplines/api-contract-strategy/references/legacy-adoption.md: current migration order and workflow guidance.
  - src/skills/disciplines/api-contract-strategy/references/tool-selection.md: current Bruno/tool selection guidance.
  - tests/test_api_contract_strategy_contracts.py: current semantic contract oracle.
- pass_condition: The plan is a bounded market-csheng-only serial DAG that upgrades one lower-plane skill, protects semantics before source edits, refreshes only generator-owned surfaces, forward-tests without `sms-gw` context, and leaves project implementation to a separate repository plan.

## Human Gate

- approval_required: true
- approval_status: pending
- next_entry: implement-change

## Rollback

- rollback_entry: plan-change
- rollback_target: The clean market-csheng checkout before T1, preserving the approved design and pending plan as stage history.
- rollback_trigger: Lifecycle ownership expansion, project-specific leakage, brittle semantic tests, unrelated generated drift, failed context-clean forward-test, or failure to converge within two bounded review batches.
