---
name: testing-strategy
description: "Translate an approved executable-oracle strategy into concrete unit, component, integration, contract, workflow, UI/E2E, performance, or runtime suites with owned fixtures, environments, CI/release lanes, and failure diagnosis. Use when implementing or reviewing project test placement, coverage gates, test isolation, red-green verification, or CI commands after oracle selection."
---

# Testing Strategy

## Purpose

Turn a selected executable oracle into the smallest concrete verification set that protects the intended boundary.

For architecture or planning decisions, use `executable-oracle-architecture-selector` first. For multi-client API contract ownership and layer decomposition, use `api-contract-strategy`.

Do not measure maturity by test count or impose universal coverage percentages.

## Strategy Mapping

Record this chain before adding tests:

```text
boundary -> oracle -> fixture/environment -> owning suite -> CI/release lane -> diagnosis owner
```

1. Name the behavior or system boundary and its owner.
2. Carry forward the selected executable oracle and record the failure class it detects.
3. Choose the smallest realistic fixture and environment.
4. Place the check in the suite that owns diagnosis.
5. Assign fast, merge, release, or runtime execution.
6. Define what a failure means and who repairs it.

A missing verification layer is not repaired by duplicating lower-value unit tests.

## Verification Placement

| Boundary | Typical oracle | Owning suite |
| --- | --- | --- |
| Function or module behavior | Examples, tables, properties | Unit or component |
| Internal component collaboration | Examples, fakes, real local dependency | Component or integration |
| Public wire shape | Schema and compatibility | Contract |
| Provider implementation | Real protocol request/response | Provider integration |
| Consumer assumptions | Mapping, serialization, adapter fixtures | Consumer adapter |
| Cross-operation business behavior | Scenarios | Workflow |
| Browser/app-owned behavior | User journey | UI / E2E |
| Load-sensitive behavior | Workload and threshold | Performance |
| Production-only behavior | SLO, canary, synthetic probe | Runtime |

For API systems, keep schema compatibility and semantic compatibility separate. Structural diffing cannot prove units, retry behavior, consistency, migration semantics, or status meaning.

## Coverage Policy

Treat line, branch, mutation, and scenario coverage as diagnostic evidence, not universal goals.

Add a numeric gate only when:

- it protects a named boundary or regression class
- the repository has a stable baseline
- the threshold has an owner and review rationale
- failure diagnosis is actionable
- raising the threshold will not incentivize low-semantic tests

Critical paths may justify stronger gates than glue or generated code. Generated internals usually need version pinning, deterministic generation, compilation, and boundary fixtures rather than handwritten coverage.

## Red-Green Verification

- For behavior changes and bug fixes, write or identify a failing test or narrow reproducer before implementation.
- Confirm the oracle fails for the expected reason, not a typo or environment error.
- Implement the smallest change that makes the reproducer pass.
- Rerun the narrow oracle and declared verification scope before claiming success.
- For docs-only, config-only, generated, or exploratory changes, record the substitute command or manual evidence.
- When the user asks for TDD, test-first work, red-green-refactor, or vertical slices, read [TDD Vertical Slices](references/tdd-vertical-slices.md).

## Oracle Integrity

- Do not delete, weaken, or bulk-update an oracle to make implementation pass without explicit review.
- Record the oracle type for non-trivial changes: example, scenario, contract, property, model, current-behavior snapshot, meta-oracle, or runtime oracle.
- Treat test deletion, assertion weakening, snapshot updates, contract changes, and security-oracle changes as elevated-risk diffs.
- Do not add sleeps, retries, broad status ranges, or existence-only assertions to hide deterministic failures.
- Preserve exact negative and boundary behavior where it carries domain meaning.

## Fixtures And Environments

- Prefer deterministic fixtures and explicit setup/cleanup.
- Exercise the real owned boundary; mock only dependencies outside that boundary.
- Keep each test independent and avoid shared mutable state.
- Use readiness checks instead of fixed sleeps.
- Isolate databases, ports, caches, temporary files, and environment variables.
- Do not require live credentials, production state, or hardware unless the owning plan explicitly authorizes that evidence.

## Test Design

- Use Arrange-Act-Assert or an equally clear scenario structure.
- Name tests by behavior, condition, and outcome.
- Prefer table-driven examples for stable rule matrices.
- Prefer properties or fuzzing when invariants matter more than examples.
- Prefer characterization tests for unknown legacy behavior before refactoring.
- Keep workflows focused on business sequences rather than endpoint catalogs.
- Keep UI/E2E narrow and user-visible.

## CI And Release Placement

Read [Capability-Based CI](references/ci-config.md) when assigning lanes.

Fast failures should precede expensive evidence. Keep commands project-owned and deterministic. Separate current-state validation from checks that require an explicit comparison base, deployment, hardware, or production authority.

## Output Contract

When this skill owns the response, lead with the recommended suite placement and commands. Include only:

- protected boundary and oracle
- fixture/environment and owning suite
- CI/release lane and diagnosis owner
- concrete verification order
- material discard reasons and failure modes

When another lifecycle skill owns the response, contribute these results as a semantic overlay.

## References

- [Python Testing Examples](references/examples-python.md)
- [Go Testing Examples](references/examples-go.md)
- [Capability-Based CI](references/ci-config.md)
- [TDD Vertical Slices](references/tdd-vertical-slices.md)
