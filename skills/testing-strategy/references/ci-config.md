# Capability-Based CI

## Principle

Expose stable project-owned commands and map them to evidence lanes. Do not make a CI vendor, runner image, language version, service container, or coverage percentage the reusable strategy.

## Lane Order

### Static contract

Run formatting, lint, type, schema, reference, generated-output, and configuration checks first.

These checks should require no service startup and should explain whether failure is syntax, policy, or stale generated truth.

### Compatibility

Compare explicit base and head artifacts for public APIs, persisted formats, migrations, or other compatibility boundaries.

Keep this lane separate from current-state validation because it requires a resolvable base. Distinguish first introduction from missing required evidence.

### Provider

Exercise the real provider boundary with isolated dependencies. Validate routing, middleware, authentication, status, headers, response body, and cleanup.

### Consumer

Compile generated projections and run consumer-owned adapter, mapping, serialization, authentication, retry, offline, and error tests.

Do not retest generated internals extensively.

### Workflow

Run critical business scenarios and historical cross-operation regressions after provider and consumer failures are cheaper to diagnose.

### UI / E2E

Run only user-visible journeys that cannot be proven below the UI. Keep browser, device, and app setup deterministic and bounded.

### Performance

Run load or resource checks only for named load-sensitive behavior. Record workload, environment, threshold rationale, and owner.

### Runtime

Run canaries, synthetic probes, and SLO evaluation only with explicit deployment and rollback authority. Runtime evidence does not replace pre-merge lanes.

## Deterministic Environment

- pin project dependencies and generators
- use isolated temporary data
- use explicit environment contracts
- wait on readiness with a bounded probe
- capture diagnostic logs and artifacts
- clean up in success and failure paths
- avoid fixed sleeps and order-dependent state

## Gate Design

For every gate, record:

- project-owned command
- protected boundary
- expected runtime and required environment
- failure diagnosis owner
- whether the gate blocks merge, release, or runtime promotion
- fallback or typed stop when external evidence is unavailable

Run narrow affected gates during implementation and the declared aggregate gates before completion.

## Coverage

If coverage is used, treat it as one signal. Set project-specific thresholds from risk and baseline, exclude generated or irrelevant code deliberately, and review threshold changes as oracle changes.

Do not create low-semantic tests merely to satisfy a percentage.
