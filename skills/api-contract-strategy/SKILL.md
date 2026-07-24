---
name: api-contract-strategy
description: "Analyze and design API contract ownership, compatibility gates, provider conformance, consumer adapters, workflow verification, generated-client lifecycle, and incremental legacy adoption. Use for Go or other HTTP providers with web, mobile, firmware, or multi-repository consumers when contract drift, duplicated DTOs, uncontrolled test growth, OpenAPI placement, CDC/Pact, workflow tooling, or client generation decisions need clear boundaries."
---

# API Contract Strategy

## Purpose

Design the smallest sufficient verification architecture for an API system.

Optimize for meaningful boundary evidence, clear ownership, deterministic compatibility, and low operational cost. Do not measure maturity by test count.

## Authority Boundaries

This is a lower-plane discipline. It advises the active sovereign workflow and does not own lifecycle transitions, repository mutation, review, repair, or completion.

Keep adjacent authorities separate:

- `executable-oracle-architecture-selector` selects contract, example, scenario, property, model, characterization, meta, or runtime oracle methods.
- `api-contract-strategy` decomposes API ownership, compatibility, provider, consumer, workflow, and generation boundaries after an API contract oracle is selected.
- `testing-strategy` turns the selected boundaries into concrete suites, fixtures, environments, CI lanes, and diagnosis ownership.
- `architecture-patterns` owns monorepo versus multi-repository structure, service boundaries, independent lifecycle choices, and their economics.

Do not emit a competing implementation plan when design, planning, or implementation owns the response.

## Decision Workflow

1. Map the provider, consumers, repository boundaries, release cadences, existing tests, current contract source, and duplicated representations.
2. Classify existing evidence using [verification layers](references/verification-layers.md).
3. Decide contract ownership, repository placement, workspace inputs, development generation, and release artifacts using [contract lifecycle](references/contract-lifecycle.md).
4. Identify the smallest missing verification layer. Do not answer every gap with more unit tests.
5. Select project-owned gates and tools using [tool selection](references/tool-selection.md).
6. Stage legacy adoption using [legacy adoption](references/legacy-adoption.md). Preserve useful existing oracles.
7. Record rejected approaches and observable upgrade triggers.

## Core Defaults

- Keep a wire contract in the provider repository unless the contract has a genuinely independent owner or lifecycle.
- Treat schema compatibility and semantic compatibility as different evidence.
- Validate provider behavior through the real protocol boundary, not internal function calls.
- Test consumer-owned serialization, mapping, authentication, error, retry, offline, and persistence assumptions; do not extensively retest generated internals.
- Use workflow tests for cross-operation business journeys, not one file per endpoint.
- Keep UI / E2E evidence narrow and user-visible.
- Keep runtime probes orthogonal to pre-merge correctness.
- Prefer explicit workspace inputs over inferred sibling paths.
- Prefer simple local generation for small first-party teams and reproducible versioned artifacts only when release independence requires them.
- Do not automatically add Pact/CDC, a broker, a contract repository, full generated clients, or an API workflow product.

## Output Contract

Render only decision-relevant conclusions in ordinary conversation.

When the user explicitly requests a comprehensive assessment, preserve:

1. Current state analysis.
2. Missing verification layers.
3. Target architecture and ownership.
4. Incremental migration plan.
5. Tool choices, alternatives, and operational cost.
6. Rejected approaches and upgrade triggers.

When another workflow owns the response, contribute these results as a semantic overlay rather than an independent report.

## Guardrails

- Do not let AI-generated prose become contract authority; require deterministic validators and reviewable artifacts.
- Do not relax a schema, fixture, assertion, or compatibility rule merely to make implementation pass.
- Do not claim semantic compatibility from schema diff alone.
- Do not claim provider conformance from handler-unit or service-unit tests that bypass the protocol boundary.
- Do not claim consumer conformance merely because generated code compiles.
- Do not duplicate OpenAPI with endpoint-by-endpoint workflow collections.
- Do not add operational infrastructure without current demand, a named owner, and an upgrade trigger.
