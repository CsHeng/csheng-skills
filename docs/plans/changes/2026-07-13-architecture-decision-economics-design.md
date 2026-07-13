# Architecture Decision Economics Design

## Status

- design_version: 1
- approval_required: true
- approval_status: approved
- recommended_next_phase: plan
- next_entry: plan-change

## Problem

The repository governs scope, ownership, risk, rollback, executable oracles, and execution continuity, but `architecture-patterns` is still primarily a prescriptive catalog. It does not consistently require evidence that the next unit of architectural complexity is worth its lifecycle cost, that simpler alternatives were considered, or that responsibility and incentives match the selected boundary.

The user approved adding marginal-cost, opportunity-cost, incentive, comparative-advantage, and supply-demand reasoning to architecture selection and plan writing, with the detailed theory kept in on-demand references instead of inflating normal skill bodies.

## Goals

- Make architecture selection default to the smallest sufficient option justified by current demand, constraints, ownership, and upgrade triggers.
- Keep detailed economics concepts, decision prompts, and examples in an on-demand `architecture-patterns` reference.
- Make `design-change` own conditional architecture economics, while `plan-change` consumes the approved decision without reopening it.
- Make design and plan review catch material demand-complexity or ownership mismatches without requiring numeric scoring or creating a new review ritual.
- Preserve source/generated skill ownership and validate the behavior with focused contract tests, aggregate checks, and an independent forward-test.

## Non-Goals

- Create a new top-level lifecycle controller or a standalone economics skill.
- Require architecture economics for docs-only work, ordinary existing-boundary edits, or every plan task.
- Introduce financial ROI formulas, weighted scorecards, or false numeric precision.
- Change runner schemas, approval gates, invocation DAG edges, or controller-owned repair behavior.
- Rewrite language, oracle, infrastructure, or testing policies that already provide compatible lower-plane evidence.

## Change Classification

- request_kind: change-definition
- change_class: B
- design_strength: design-lite
- truth_impact: medium
- boundary_impact: medium
- truth_repair: false
- truth_sync_required: true
- parallel_candidate: true

## Boundaries

- `architecture-patterns` owns the selection method, the smallest-sufficient default, pattern fit guidance, and the economics reference.
- `design-change` activates architecture economics only when a change creates, replaces, decomposes, centralizes, distributes, or materially scales a persisted architecture boundary.
- `plan-change` records and stages the approved choice, observable upgrade triggers, and reversible increments; it must not recompute the architecture decision.
- `review-design` checks material architecture economics omissions at the design boundary. `review-plan` checks plan fidelity to the approved choice and must not reopen the tradeoff.
- Detailed theory and worked examples live one level below `architecture-patterns/SKILL.md` in `references/architecture-decision-economics.md`.
- Existing pattern guidance remains available through progressive disclosure rather than being lost during the skill-body reduction.
- Stable project truth describes the new conditional composition at a summary level; stage artifacts remain history rather than runtime truth.

## Architecture Decision Economics

- demand_evidence: The user explicitly requested economics-aware architecture selection and deeper on-demand theory. Current source inspection shows strong execution governance but no common architecture selection gate across design, planning, and review.
- scarce_resource: Agent context, human review attention, implementation time, operational ownership, and the cognitive capacity needed to maintain architecture decisions.
- options:
  - Preserve the current catalog: lowest immediate edit cost, but leaves architecture accumulation and premature enterprise-pattern risk unresolved.
  - Add a conditional selection gate, on-demand theory reference, bounded workflow integration, tests, and stable-truth summary: chosen because it closes the decision gap without adding a controller or universal template tax.
  - Add a new economics skill plus schema-enforced fields across all plans: stronger formalization, but higher routing, context, review, and maintenance costs than current demand warrants.
- marginal_tradeoff: The chosen option adds a small conditional decision surface and focused tests while avoiding a repository-wide metadata/schema migration.
- opportunity_cost: This work defers a broader rewrite of all architecture, language, oracle, and infrastructure skills and avoids spending review budget on numeric scoring machinery.
- owner_and_incentives: Keeping selection in `architecture-patterns`, activation in `design-change`, and fidelity checks in review aligns decision authority with maintenance responsibility. Conditional loading reduces incentives to complete checklists for their own sake.
- comparative_advantage: Existing skills retain their specialized evidence roles; no general economics controller duplicates their lifecycle or domain authority.
- supply_demand_rule: Adopt new architectural supply only when current demand evidence, a constrained resource, or a measurable upgrade trigger justifies it.
- upgrade_trigger: Consider a standalone decision-economics skill or machine-enforced schema only after repeated cross-domain drift proves the shared reference and bounded review checks insufficient.
- chosen_option: Conditional architecture-economics overlay inside the existing skill and lifecycle boundaries.

## Acceptance Conditions

- `architecture-patterns/SKILL.md` becomes a concise selector and links directly to detailed pattern and economics references.
- The economics reference explains marginal cost, opportunity cost, incentives, comparative advantage, and supply-demand reasoning in engineering terms, including a compact decision record and failure modes.
- `design-change` conditionally requires the approved architecture economics decision for material persisted-boundary changes.
- `plan-change` stages approved decisions as reversible increments and measurable triggers without repeating or rescoring the design.
- Design review checks material demand-complexity, owner-cost, and simpler-option gaps; plan review checks fidelity without reopening architecture selection.
- Focused tests protect progressive disclosure, conditional activation, ownership, non-goals, and review boundaries.
- Generated root-flat skill surfaces match `src/skills`, aggregate validation passes, docs boundaries remain valid, and an independent forward-test shows the revised skill selects rather than accumulates patterns.

## Human Gate

- approval_basis: The user explicitly accepted the proposed ownership model and requested implementation, including detailed theory in a docs/reference surface rather than skill bodies.
- approval_required: true
- approval_status: approved
- next_entry: plan-change

## Implementation Surface

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
