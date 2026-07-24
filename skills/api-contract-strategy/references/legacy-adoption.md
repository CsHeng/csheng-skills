# Legacy Adoption

## Principle

Introduce the minimum missing verification layer while preserving useful current evidence.

Do not rewrite all tests, replace stable adapters, or declare a partial schema complete.

## Migration Order

1. Map registered provider boundaries, consumers, semantic documentation, fixtures, release ownership, and current tests.
2. Create a contract baseline for an explicit complete scope. If adoption is partial, label the included and excluded surface precisely.
3. Add parsing, lint, reference, naming, operation-id, and example validation.
4. Add base-versus-head schema compatibility and a separate semantic review obligation.
5. Add Provider Conformance through the real protocol boundary and deterministic data.
6. Retain or add Business Workflow tests for critical cross-operation journeys.
7. Add Consumer Adapter evidence for serialization, decoding, authentication, errors, retries, offline behavior, and platform policy.
8. Introduce generated types or clients gradually where they remove real duplication.
9. Add CDC only when independently released consumers and hidden assumptions justify its lifecycle.

## Baseline Rules

- Derive scope from registered routes or protocol definitions, not documentation alone.
- Give every excluded operation a reviewed reason.
- Distinguish the first baseline from an unavailable required comparison base.
- Use synthetic public examples and prevent secrets or private data from entering fixtures.
- Keep semantic behavior in stable owning documentation instead of forcing it into schema extensions.

## Provider Rules

- Reuse real-router and integration fixtures where they already exist.
- Add a shared conformance helper rather than duplicating one test suite per tool.
- Do not broadly relax schemas when provider evidence conflicts with the baseline.
- Record which operations have response conformance and which only have route completeness.

## Consumer Rules

- Start with the smallest projection that removes current drift.
- Keep view models and local form state manual when they are not wire DTOs.
- Share contract-validated examples with constrained firmware clients before considering generated C++ or Lua SDKs.
- Keep platform behavior in the owning consumer tests.

## Workflow Rules

- Preserve valuable smoke and regression journeys.
- Add workflows for cross-operation behavior, not contract-shaped endpoint catalogs.
- Treat browser tests as evidence only for browser-owned behavior.

## CDC Decision

Use consumer-driven contracts when consumers release independently, providers cannot execute consumer evidence, hidden assumptions repeatedly escape, or many long-lived API versions coexist.

Avoid CDC when one team owns a small set of visible first-party consumers and provider-owned schema plus consumer adapter evidence closes the known gap.

Pact adds a broker, version lifecycle, provider states, publishing, and a verification matrix. Demand evidence must justify that cost.

## Stop Conditions

- provider implementation and stable semantic truth conflict
- compatibility base cannot be resolved deterministically
- generation would replace consumer policy outside the approved scope
- required evidence needs live credentials, hardware, or production authority
- the proposed layer duplicates an existing oracle without closing a named gap
