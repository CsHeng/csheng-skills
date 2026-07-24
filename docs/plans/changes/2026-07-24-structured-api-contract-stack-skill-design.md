# Structured API Contract Stack Skill Design

## Status

- design_version: 1
- approval_required: true
- approval_status: approved
- approval_basis: The user approved capturing the OpenAPI/Arazzo/Respect/Redocly approach as reusable skill knowledge and clarified that this repository owns only the skill change, while `sms-gw` independently implements the described scenario.
- recommended_next_phase: plan
- next_entry: plan-change

## Problem

`api-contract-strategy` already separates wire, provider, consumer, workflow, and UI evidence, but its authoring and workflow guidance is still too generic for the failure mode exposed by a moderately sized real API:

- It does not explain how one canonical OpenAPI contract can remain human-maintainable when a single file grows to thousands of lines.
- It does not distinguish maintained OpenAPI source, deterministic bundles, generated provider/consumer types, and generated human reference documentation.
- It treats workflow runners generically and currently gives Bruno a positive default role even when agents and CI need a structured CLI surface rather than a GUI collection.
- It does not encode Arazzo as the workflow specification, Respect as an executable runner, or the boundary where Python/Shell remain environment lifecycle glue.
- It does not reject a handwritten endpoint-by-endpoint Markdown API reference as a coequal contract source.

The skill should capture this as reusable decision guidance without turning one project's chosen stack or version pins into a universal mandate.

## Goals

- Add a concise structured-contract reference that explains OpenAPI authoring source, multi-file organization, deterministic bundling, generated projections, Arazzo workflows, CLI execution, lifecycle glue, and generated human documentation.
- Make OpenAPI-first the preferred model when several languages or agents need shared wire truth and provider boundary generation is practical, while retaining a conditional typed code-first path.
- Recommend domain-grouped source fragments behind one root when size or ownership makes a single file hostile to review.
- Recommend Arazzo for a small number of cross-operation outcomes and Redocly Respect as the integrated CLI runner when its capability/runtime fit is proven.
- Recommend Redocly as an integrated lint/bundle/Respect/docs tool surface when the repository needs the whole stack, without requiring hosted Redocly services.
- Keep Python or Shell only for process, database, fixture, restart, readiness, and cleanup orchestration when HTTP workflow semantics move to Arazzo.
- Treat human API reference documentation as a generated projection and GUI collections as an explicit external-collaboration trigger.
- Protect the new guidance with semantic contract tests, deterministic generation, skill validation, and a context-clean forward-test.

## Non-Goals

- Implement or inspect the `sms-gw` application migration from this repository.
- Make Redocly, Respect, Arazzo, `oapi-codegen`, Restish, or OpenAPI-first mandatory for every API.
- Encode project-specific paths, operation IDs, workflows, credentials, version pins, or CI commands in the reusable skill.
- Add a lifecycle controller, command, repair owner, hosted service, plugin dependency, or executable helper script.
- Rewrite `testing-strategy`, `executable-oracle-architecture-selector`, or `architecture-patterns` beyond any link required to keep current ownership accurate.
- Remove conditional Pact/CDC, independent repository, generated client, or runtime-probe guidance.

## Change Classification

- request_kind: reusable-skill-knowledge-upgrade
- change_class: B
- design_strength: design-lite
- truth_impact: medium
- boundary_impact: low
- truth_repair: true
- truth_sync_required: true
- parallel_candidate: false

## Boundaries

- `api-contract-strategy` owns the reusable contract authoring, projection, workflow, runner, and documentation decision model.
- `executable-oracle-architecture-selector` continues to own selection of contract and scenario oracle methods.
- `testing-strategy` continues to own concrete suite, fixture, environment, CI lane, and diagnosis placement after the boundary is selected.
- `architecture-patterns` continues to own repository/service lifecycle economics.
- Sovereign harness workflows continue to own design, planning, implementation, review, truth synchronization, and close.
- Project repositories independently decide and implement concrete paths, versions, workflows, and commands using this guidance.

## Structured Contract Model

The skill will define one maintained source per truth kind:

| Truth kind | Preferred maintained source | Derived/executable surface |
| --- | --- | --- |
| HTTP operation and wire shape | OpenAPI root plus referenced fragments | Bundle, provider models, consumer types, fixtures, generated HTML |
| Cross-operation outcome | Arazzo referencing OpenAPI operations | Respect or another conforming CLI runner |
| Environment lifecycle | Existing project-owned glue | Process/database/restart/cleanup orchestration around the workflow runner |
| Non-HTTP domain behavior | Owning code and stable domain docs | Focused tests and links |

OpenAPI and Arazzo are complementary. Arazzo may add sequencing, value chaining, and success criteria, but must not restate operation request/response schemas.

## Authoring Decision

- Prefer OpenAPI-first when several provider/consumer languages or agents need shared structured truth, compatibility must be reviewed before code drift, and generated boundary models are feasible.
- Prefer typed declarative code-first when one provider framework completely and deterministically exports OpenAPI from typed declarations.
- Use annotation/comment-first generation only when the annotations cover every operation/schema and stale/incomplete output is mechanically rejected.
- For legacy ambiguity, characterize the real provider boundary and adjudicate intended behavior instead of silently treating docs or implementation as correct.

## Maintainability And Projections

- Keep one file for a genuinely small contract.
- Split by stable API domain behind one thin root when operation/schema count, ownership, or merge contention makes a single file hostile.
- Provide one pinned project-owned lint/reference/bundle command.
- Treat a bundle as generated; either commit it with stale-output protection when portability and agent context matter, or write it to an ignored build root.
- Generate only the provider/consumer wire boundary needed to remove duplication. Do not generate domain, persistence, transport policy, retries, or UI state by default.
- Generate human reference HTML from OpenAPI instead of maintaining an endpoint-by-endpoint Markdown copy.

## Workflow And Runner Model

- Use Arazzo only for outcomes that require several operations, chained values, or state transitions.
- Keep workflow count proportional to business journeys, not endpoint count.
- Reference stable OpenAPI operation IDs, pass secrets as runtime inputs, use synthetic examples, and keep logs masked.
- Prefer Redocly Respect when the repository needs OpenAPI-linked execution, response status/schema/content-type checks, success criteria, server overrides, secret inputs, deterministic exits, and CLI/CI operation.
- Pin the Arazzo revision the chosen runner can execute; do not adopt a newer revision merely because lint supports it.
- Preserve Python/Shell lifecycle orchestration when it owns dynamic environments, but remove duplicated business HTTP steps after runner equivalence is proven.

## Human And Ad Hoc Interaction

- Generated HTML is optional for agents but useful for human review and external collaboration.
- Publish or host it only when an external audience and owner exist.
- Use Restish, curl, or disposable one-step Arazzo for single-operation exploration without committing a second endpoint catalog.
- Add Bruno/Postman/Yaak only when a named GUI collaboration requirement justifies a generated or synchronized projection; never make that collection contract truth.

## Skill Shape

The source skill remains concise and gains one directly linked reference:

```text
src/skills/disciplines/api-contract-strategy/
├── SKILL.md
├── agents/openai.yaml
└── references/
    ├── structured-contract-stack.md
    ├── verification-layers.md
    ├── contract-lifecycle.md
    ├── legacy-adoption.md
    └── tool-selection.md
```

- `SKILL.md` adds the authoring/projection step and core defaults.
- `structured-contract-stack.md` owns the detailed integrated model.
- Existing references receive only the lifecycle, legacy-migration, layer, and tool-selection deltas that belong there.
- The metadata trigger adds oversized OpenAPI, manual API docs, Swagger annotations, Arazzo, Respect, and Redocly.
- README receives a one-line inventory update; generated root-flat surfaces are refreshed from source.

## Acceptance Conditions

- The skill clearly distinguishes canonical maintained sources from generated bundle/code/docs projections.
- It conditionally selects OpenAPI-first, typed code-first, or annotation-first rather than treating Swagger comments as automatically upstream.
- It recommends domain grouping and deterministic bundling for large contracts.
- It assigns OpenAPI, Arazzo, Respect, lifecycle glue, and generated human docs non-overlapping roles.
- Redocly is the recommended integrated CLI when the full capability set is needed, with no hosted-service dependency.
- Bruno and other GUIs are explicit collaboration triggers, while single-operation CLI use remains ad hoc and untracked.
- Existing lower-plane/lifecycle ownership and conditional CDC/client/repository decisions remain intact.
- Focused semantic tests fail before implementation and pass after source/generated refresh.
- Skill validation, generators, aggregate checks, docs boundaries, Markdown checks, and a context-clean forward-test pass.
- No `sms-gw` file or project-specific implementation detail is touched.

## Human Gate

- approval_required: true
- approval_status: approved
- next_entry: plan-change

## Implementation Surface

- impl_file_refs:
  - src/skills/disciplines/api-contract-strategy/SKILL.md
  - src/skills/disciplines/api-contract-strategy/agents/openai.yaml
  - src/skills/disciplines/api-contract-strategy/references
  - tests/test_api_contract_strategy_contracts.py
  - README.md
  - skills.index.json
  - skills/.source-map.json
  - skills/api-contract-strategy
- test_file_refs:
  - tests/test_api_contract_strategy_contracts.py
