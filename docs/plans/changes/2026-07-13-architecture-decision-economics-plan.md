# Architecture Decision Economics Implementation Plan

## Upstream Design

- design_ref: docs/plans/changes/2026-07-13-architecture-decision-economics-design.md
- design_version: 1

## Implementation Scope

- impl_file_refs:
  - src/skills/disciplines/architecture-patterns
  - src/skills/workflows/design-change/SKILL.md
  - src/skills/workflows/plan-change/SKILL.md
  - src/skills/review-components/review-design/SKILL.md
  - src/skills/review-components/review-plan/SKILL.md
  - skills/architecture-patterns
  - skills/design-change/SKILL.md
  - skills/plan-change/SKILL.md
  - skills/review-design/SKILL.md
  - skills/review-plan/SKILL.md
  - README.md
  - docs/architecture/workflow-orchestration.md
- test_file_refs:
  - tests/test_architecture_economics_contracts.py
- verification_scope:
  - Focused architecture-economics contract tests
  - Skill-folder validation for the updated architecture selector
  - Source-to-root-flat generation and repository aggregate checks
  - Agent-native review and artifact-DAG smoke tests
  - Docs-boundary validation and Markdown whitespace checks
  - Independent forward-test using a realistic architecture-choice request

## Work Package Readiness

- milestone_objective: Add conditional economics-aware architecture selection with progressive-disclosure references and bounded lifecycle integration.
- non_goals:
  - Add a top-level economics controller or standalone skill.
  - Require economics metadata for ordinary edits or every task.
  - Add numeric ROI scoring or change runner schemas and invocation DAG edges.
- future_phase:
  - Consider machine-enforced economics metadata only if repeated plan or design drift proves the reference-based contract insufficient.
  - Extend the same reference into other decision disciplines only after concrete cross-domain demand appears.
- decision_status: ready_for_review
- oracle_strategy: Contract-test-first for skill semantics, followed by skill validation, aggregate repository checks, bounded review, and an independent qualitative forward-test.
- acceptance_oracles:
  - A focused test fails before implementation because the economics reference and lifecycle contracts are absent, then passes after the change.
  - The architecture skill validates and directly links one-level pattern-selection and economics references.
  - Design owns conditional economics selection; plan consumes rather than rescores; review boundaries enforce the same ownership.
  - Generated root-flat skills match source and all required repository checks pass.
  - A fresh agent selects the smallest sufficient option from demand evidence instead of accumulating patterns.
- execution_continuity: continuous_after_plan_approval
- max_review_batches: 2
- subagent_ready: true

## Execution Continuity

- execution_mode: continuous_after_plan_approval
- confirmation_clearance:
  - C0: Plan approval authorizes the complete serial task range without another routine checkpoint.
- runtime_contingencies:
  - X1: Stop with `needs-plan-change` if focused tests reveal that runner schema or command-surface changes are required outside the approved touch set.
  - X2: Stop and diagnose before repair if generation changes unrelated root-flat skills or stable docs outside the approved surface.
  - X3: Treat a forward-test that still recommends pattern accumulation without demand evidence as an in-scope verification failure.
- planned_stop_points:
  - none
- task_ordering_rationale: Establish the semantic oracle first, implement the selection owner before its lifecycle consumers, then sync stable/generated truth and finish with the widest checks and independent behavior evidence.

## Task 1: Add the failing architecture-economics contract oracle

- task_id: T1
- depends_on:
  - none
- scope_slice: Add focused source-level contract tests for progressive disclosure, conditional activation, lifecycle ownership, and review boundaries.
- impl_file_refs:
  - tests/test_architecture_economics_contracts.py
- test_file_refs:
  - tests/test_architecture_economics_contracts.py
- verification_scope:
  - Run only the new unittest module and capture the expected pre-implementation failure caused by missing references or contract wording.
- executor_mode: main
- task_review_depth: focused
- done_when:
  - The new test module is syntactically valid.
  - Its failing assertions directly correspond to approved acceptance conditions rather than incidental prose.
  - The red result is recorded before source-skill implementation.
- rollback_on_failure: Remove or narrow assertions that exceed the approved design; do not weaken approved ownership or progressive-disclosure requirements.

## Task 2: Convert architecture-patterns into an economics-aware selector

- task_id: T2
- depends_on:
  - T1
- scope_slice: Replace the prescriptive catalog-shaped skill body with a concise selection workflow and add one-level pattern and economics references while preserving interface/domain guidance.
- impl_file_refs:
  - src/skills/disciplines/architecture-patterns
- test_file_refs:
  - tests/test_architecture_economics_contracts.py
- verification_scope:
  - Run the focused contract test.
  - Run skill-creator quick validation for `src/skills/disciplines/architecture-patterns`.
  - Inspect the reference links and confirm detailed theory is not duplicated into the skill body.
- executor_mode: main
- task_review_depth: boundary
- done_when:
  - The skill defaults to the smallest sufficient architecture justified by demand and constraints.
  - `references/architecture-decision-economics.md` covers all five approved concepts, compact decision evidence, failure modes, and upgrade triggers.
  - Existing pattern guidance remains available through a directly linked pattern-selection reference.
  - The interface/domain-language reference remains directly linked and valid.
- rollback_on_failure: Restore the previous skill body and remove only the new references if progressive disclosure cannot preserve existing guidance.

## Task 3: Integrate the decision into design, planning, and bounded review

- task_id: T3
- depends_on:
  - T2
- scope_slice: Make design conditionally own architecture economics, make planning consume approved choices as reversible increments, and align design/plan review boundaries.
- impl_file_refs:
  - src/skills/workflows/design-change/SKILL.md
  - src/skills/workflows/plan-change/SKILL.md
  - src/skills/review-components/review-design/SKILL.md
  - src/skills/review-components/review-plan/SKILL.md
- test_file_refs:
  - tests/test_architecture_economics_contracts.py
- verification_scope:
  - Run the focused contract test.
  - Inspect the four changed skill diffs for conditional activation, single-owner semantics, no rescoring, and no universal template requirement.
- executor_mode: main
- task_review_depth: boundary
- done_when:
  - Material persisted-boundary architecture changes activate `architecture-patterns`; ordinary edits do not.
  - Planning records the approved decision reference, reversible staging, and measurable upgrade triggers without reopening the tradeoff.
  - Design review can block a material demand-complexity, simpler-option, or owner-cost mismatch without demanding numeric scoring.
  - Plan review checks fidelity and executable staging without rerunning architecture selection.
- rollback_on_failure: Revert the lifecycle overlay edits as one unit while preserving the standalone architecture selector and references for a later design iteration.

## Task 4: Sync stable and generated truth

- task_id: T4
- depends_on:
  - T3
- scope_slice: Update the stable skill/workflow summary and regenerate root-flat compatibility skills from source.
- impl_file_refs:
  - README.md
  - docs/architecture/workflow-orchestration.md
  - skills/architecture-patterns
  - skills/design-change/SKILL.md
  - skills/plan-change/SKILL.md
  - skills/review-design/SKILL.md
  - skills/review-plan/SKILL.md
- test_file_refs:
  - tests/test_architecture_economics_contracts.py
- verification_scope:
  - Run the focused contract test against source.
  - Run skills-index and root-flat generation.
  - Compare changed generated skills with their source counterparts.
  - Run docs-boundary and whitespace checks.
- executor_mode: main
- task_review_depth: focused
- done_when:
  - README and workflow-orchestration summarize the conditional architecture-economics ownership without copying the detailed theory.
  - Generated skill folders contain the new references and match source.
  - No unrelated generated or stable-truth files change.
- rollback_on_failure: Revert stable-doc edits and regenerate root-flat output from the pre-task source state; do not hand-edit generated files.

## Task 5: Verify, forward-test, and review the complete slice

- task_id: T5
- depends_on:
  - T4
- scope_slice: Run the declared aggregate oracles, test behavior with a fresh bounded agent, and route the exact implementation diff through agent-native review.
- impl_file_refs:
  - src/skills/disciplines/architecture-patterns
  - src/skills/workflows/design-change/SKILL.md
  - src/skills/workflows/plan-change/SKILL.md
  - src/skills/review-components/review-design/SKILL.md
  - src/skills/review-components/review-plan/SKILL.md
  - skills/architecture-patterns
  - skills/design-change/SKILL.md
  - skills/plan-change/SKILL.md
  - skills/review-design/SKILL.md
  - skills/review-plan/SKILL.md
  - README.md
  - docs/architecture/workflow-orchestration.md
- test_file_refs:
  - tests/test_architecture_economics_contracts.py
- verification_scope:
  - Run the focused and full Python test suites.
  - Run skill quick validation, required generators, `scripts/check.sh`, review smoke tests, artifact-DAG smoke tests, docs-boundary validation, and `git diff --check`.
  - Forward-test the installed/root-flat architecture skill on a realistic architecture-choice request without giving the expected answer.
  - Review only the approved diff, declared tests, verification evidence, and justified direct dependencies.
- executor_mode: main
- task_review_depth: full
- done_when:
  - Every declared command passes.
  - Forward-test evidence demonstrates demand-first, smallest-sufficient selection and explicit upgrade triggers.
  - Main-agent adjudication leaves no accepted implementation finding unresolved.
  - Final diff remains inside the approved touch set.
- rollback_on_failure: Apply the task-specific rollback for the first failing slice; if focused repair cannot converge within the review budget, restore the pre-plan source/generated state and exit with the matching typed stop.

## Review Gate

- required_entry: review-change
- review_component: review-plan
- review_depth: boundary
- max_review_batches: 2
- supporting_files:
  - AGENTS.md: repository source/generated, lifecycle, review, docs, and validation contract.
  - docs/plans/changes/2026-07-13-architecture-decision-economics-design.md: approved scope and implementation surface.
  - src/skills/workflows/plan-change/SKILL.md: execution-grade task and continuity requirements.
- pass_condition: The plan is a bounded serial DAG with sufficient oracles, approved ownership, rollback, and continuous execution after approval.

## Human Gate

- approval_required: true
- approval_status: approved
- next_entry: implement-change

## Rollback

- rollback_entry: plan-change
- rollback_target: The clean `main` checkout before implementation begins, preserving the approved design and plan artifacts as stage history.
- rollback_trigger: Scope expansion, required runner-schema changes, unrelated generated drift, failed aggregate checks that cannot be repaired in-scope, or a non-convergent forward-test/review loop.
