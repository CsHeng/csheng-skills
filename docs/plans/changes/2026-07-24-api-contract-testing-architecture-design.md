# API Contract And Layered Testing Architecture Design

## Status

- design_version: 1
- approval_required: true
- approval_status: approved
- recommended_next_phase: plan
- next_entry: plan-change

## Problem

The repository has a strong executable-oracle selector and a concrete `testing-strategy` skill, but it does not have one lower-plane owner for multi-client API contract lifecycle decisions. `testing-strategy` currently mixes test categories, universal coverage thresholds, and one vendor-specific CI example; it does not clearly separate wire compatibility, provider conformance, consumer assumptions, business workflows, and user-visible behavior.

The user approved adding a reusable API-contract discipline, correcting the verification-layer model, and integrating it with the existing oracle and testing skills without creating another top-level workflow.

## Goals

- Add an agent-agnostic `api-contract-strategy` discipline for API ownership, contract location, compatibility, provider and consumer boundaries, generated artifacts, legacy adoption, and tool economics.
- Make the verification topology explicit: wire contract fans out into provider conformance and consumer adapter verification, those branches join at business workflow verification, and critical user behavior remains a narrow E2E layer.
- Refactor `testing-strategy` from test-count and universal-coverage guidance into boundary-owned suites, fixtures, environments, CI lanes, and diagnosis ownership.
- Preserve `executable-oracle-architecture-selector` as the owner of oracle-method selection and `architecture-patterns` as the owner of repository and lifecycle architecture choices.
- Keep the new skill concise through directly linked references and protect its routing and ownership contracts with focused tests.

## Non-Goals

- Add an eighth sovereign harness entry, command, lifecycle controller, or repair owner.
- Make OpenAPI, Pact, Bruno, generated SDKs, a contract repository, or any named vendor universally mandatory.
- Move monorepo versus multi-repository selection out of `architecture-patterns`.
- Replace the executable-oracle selector or let API-contract guidance independently emit a competing plan.
- Require global percentage thresholds or one CI provider across all projects.
- Implement the `sms-gw` migration in this repository.

## Change Classification

- request_kind: skill-architecture-change
- change_class: B
- design_strength: design-lite
- truth_impact: medium
- boundary_impact: medium
- truth_repair: false
- truth_sync_required: true
- parallel_candidate: false

## Current State Analysis

- `executable-oracle-architecture-selector` already selects contract/schema conformance for public APIs and service boundaries, but it does not own contract lifecycle or multi-client repository decisions.
- `testing-strategy` translates a selected oracle into concrete tests, but its mandatory 80/95/90/85 percent thresholds conflict with its later instruction not to chase coverage that does not protect the intended boundary.
- `testing-strategy/references/ci-config.md` assumes GitHub Actions, fixed language versions, fixed service containers, fixed sleeps, and a universal 80 percent gate rather than describing capability-based lanes.
- No existing discipline owns provider-versus-consumer conformance, schema-versus-semantic compatibility, development-versus-release generation, or the decision to reject CDC and a standalone contract repository.
- The repository already supports source-first skill authoring, root-flat generation, manifest validation, focused semantic contract tests, agent-native review, and independent forward-testing.

## Boundaries

- The new behavior is a lower-plane discipline and may advise a sovereign workflow only as a semantic overlay.
- API contract lifecycle decisions remain distinct from executable-oracle method selection, concrete suite design, persisted repository architecture, and lifecycle control.
- Source truth stays under `src/skills/` and `contracts/skills.toml`; `skills/` and `skills.index.json` remain generated compatibility surfaces.
- Comprehensive assessment structure is owned by the new skill only when explicitly requested; ordinary responses continue to use `output-styles`.
- The implementation changes no command surface, runtime invocation contract, approval gate, review ownership, or repair loop.

## Ownership Model

- `api-contract-strategy` owns API contract assessment, ownership placement, verification-layer boundaries, generated-client lifecycle, incremental legacy adoption, tool operational cost, and explicit rejected approaches.
- `executable-oracle-architecture-selector` owns selection among contract, example, scenario, property, model, characterization, meta, and runtime oracles.
- `testing-strategy` consumes the selected oracle and owns concrete suite placement, fixtures, test environments, CI/release lanes, and failure diagnosis.
- `architecture-patterns` owns monorepo versus multi-repository structure, service boundaries, independent lifecycle decisions, and demand-first architecture economics.
- Sovereign harness workflows continue to own phase routing, approval, implementation, review, truth synchronization, and close judgment.
- Language and tool policy skills apply only after the implementation boundary or ad hoc command need is known.

## Verification Topology

```text
                         +----------------------+
                         |    Wire Contract     |
                         +----------+-----------+
                                    |
                     +--------------+--------------+
                     |                             |
                     v                             v
          +----------------------+      +----------------------+
          | Provider Conformance |      | Consumer Adapter     |
          +----------+-----------+      +----------+-----------+
                     |                             |
                     +--------------+--------------+
                                    |
                                    v
                         +----------------------+
                         |  Business Workflow   |
                         +----------+-----------+
                                    |
                                    v
                         +----------------------+
                         | Critical UI / E2E    |
                         +----------------------+
```

Runtime probes, canaries, and SLOs observe deployed behavior across this topology; they are not another rung that substitutes for pre-merge contract or workflow verification.

Each layer answers one bounded question:

- Wire contract: What requests, responses, authentication, and errors are structurally allowed?
- Provider conformance: Does the real HTTP provider implement the declared contract?
- Consumer adapter: Does each client correctly serialize, decode, authenticate, retry, and map errors at its owned boundary?
- Business workflow: Do important cross-endpoint scenarios and historical regressions work?
- Critical UI/E2E: Can users complete the few journeys whose browser or device behavior cannot be proven below the UI?

Schema compatibility and semantic compatibility remain separate. Machine diffing can detect many structural breaks; unit changes, retry semantics, consistency promises, migration behavior, and status meaning still require reviewed semantic truth.

## Skill Shape

The new source skill will use:

```text
src/skills/disciplines/api-contract-strategy/
  SKILL.md
  agents/openai.yaml
  references/
    verification-layers.md
    contract-lifecycle.md
    legacy-adoption.md
    tool-selection.md
```

- `SKILL.md` contains trigger boundaries, ownership, a compact decision workflow, progressive-disclosure routing, and the output contract.
- `verification-layers.md` contains the topology, layer responsibilities, duplication smells, and runtime-probe relationship.
- `contract-lifecycle.md` contains provider-owned versus independent contract repositories, sibling-repository workspace contracts, and development versus release generation.
- `legacy-adoption.md` contains incremental baseline, lint, compatibility, provider, workflow, consumer, generation, and conditional CDC staging.
- `tool-selection.md` contains capability-based selection, operational cost, alternatives, and rejection/upgrade triggers rather than one universal tool stack.

## Output Contract

Ordinary invocations render only decision-relevant findings. When the user explicitly asks for a comprehensive assessment, the skill preserves:

1. Current state analysis.
2. Missing verification layers.
3. Target architecture.
4. Incremental migration plan.
5. Tool selection with operational cost and alternatives.
6. Rejected approaches and upgrade triggers.

The fixed six-part shape belongs to the comprehensive assessment mode, not every conversational response.

## `testing-strategy` Refactor

- Remove mandatory global percentage thresholds and replace them with risk- and boundary-specific gates whose rationale and owner are explicit.
- Replace the flat unit/integration/E2E checklist with the chain `protected boundary -> oracle -> fixture/environment -> owning suite -> CI/release lane -> diagnosis owner`.
- State that a missing verification layer is not repaired by duplicating lower-value unit tests.
- Keep red-green verification, oracle edit risk, isolation, naming, and existing language examples where they remain compatible.
- Rewrite `references/ci-config.md` into capability-based CI guidance: fast static gates, contract compatibility, provider/consumer checks, workflow smoke, narrow E2E, deterministic readiness, cleanup, and project-owned commands.
- Do not prescribe a CI vendor, fixed runtime versions, fixed service containers, fixed sleeps, or universal coverage numbers.

## Selector Integration

`executable-oracle-architecture-selector` receives only a bounded cross-route: multi-client public API changes should use `api-contract-strategy` to decompose contract ownership and verification layers after the selector chooses contract/schema conformance. The selector retains method authority and does not absorb lifecycle details.

## Registration

- Add `api-contract-strategy` to `contracts/skills.toml` as category `discipline`.
- Install it for Claude, Codex, and root-flat surfaces.
- Set `lifecycle_owner = false`, `implicit_invocation = true`, `may_mutate_repo = false`, and `may_spawn_agent = false`.
- Add a concise README inventory entry beside executable-oracle and testing strategy.
- Generate `skills.index.json` and the root-flat `skills/api-contract-strategy` surface from source; do not hand-edit generated files.

## Acceptance Conditions

- The new skill owns API contract lifecycle and layered verification without becoming a top-level controller.
- The layer topology branches provider and consumer verification from the wire contract and joins them at workflow verification.
- The skill distinguishes schema compatibility from semantic compatibility and development generation from reproducible release artifacts.
- Contract-repository, generated-client, Pact/CDC, Bruno/workflow, and monorepo/multi-repository choices are conditional on observed demand and operational cost.
- `testing-strategy` has no universal coverage mandate or vendor-specific default CI workflow and instead maps boundaries to owned executable gates.
- The executable-oracle selector cross-routes multi-client API work without surrendering oracle-method authority.
- Focused contract tests protect routing, ownership, output shape, progressive disclosure, rejected defaults, and generated registration.
- Source validation, generators, aggregate checks, review smoke tests, artifact-DAG smoke tests, docs boundaries, Markdown whitespace checks, and an independent `sms-gw`-like forward-test all pass.

## Human Gate

- approval_basis: The user accepted the proposed 1-4 skill direction and explicitly requested `plan-change` for the current repository.
- approval_required: true
- approval_status: approved
- next_entry: plan-change

## Implementation Surface

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
