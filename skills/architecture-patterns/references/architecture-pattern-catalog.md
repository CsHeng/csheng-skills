# Architecture Pattern Catalog

Use this catalog only after identifying the protected boundary, demand evidence, constrained resource, and hard requirements. A pattern is a candidate with adoption and lifecycle costs, not a default package.

## Contents

- [Boundary And Modularity Patterns](#boundary-and-modularity-patterns)
- [Communication And Consistency Patterns](#communication-and-consistency-patterns)
- [API And Integration Patterns](#api-and-integration-patterns)
- [Security Patterns](#security-patterns)
- [Scaling Patterns](#scaling-patterns)
- [Resilience Patterns](#resilience-patterns)
- [Evolution Patterns](#evolution-patterns)
- [Pattern Decision Card](#pattern-decision-card)

## Boundary And Modularity Patterns

### Layered Or Clean Boundaries

Fit:

- separate presentation, domain behavior, and infrastructure ownership
- enforce inward dependency direction around stable business rules
- create test seams at caller-visible contracts

Costs and cautions:

- pass-through layers and speculative interfaces add navigation and change cost without isolating real volatility
- generic repository or service interfaces can hide useful domain language

Adopt when behavior, ownership, framework volatility, or test boundaries differ. Apply the deletion test from `interface-and-domain-language.md`: if deleting an abstraction removes only forwarding, it does not carry enough complexity.

### Modular Monolith

Fit:

- one deployment and operational owner remain efficient
- domain or module boundaries need enforcement without distributed coordination
- local transactions and simple failure semantics are valuable

Costs and cautions:

- weak module contracts can decay into shared-state coupling
- one deployment can become a bottleneck when independent release demand is proven

Prefer this as the structural baseline before microservices when one runtime and ownership surface satisfy current demand.

### Microservices

Fit:

- independently owned business capabilities require independent deployment, scaling, security, or failure containment
- service contracts and operational ownership are stable enough to pay the distribution cost

Costs and cautions:

- network failure, versioned contracts, tracing, deployment coordination, incident response, and data consistency become mandatory work
- service count can exceed team and operator supply

Adopt a split only for the boundary whose measured scaling, release, security, or ownership constraint exceeds those costs. Keep each service cohesive, give it clear data ownership, and avoid shared databases that erase the boundary.

## Communication And Consistency Patterns

### Synchronous Request/Response

Fit critical operations that benefit from immediate outcome and simple failure propagation. Define timeouts, cancellation, idempotency where retries are possible, and explicit error semantics.

Avoid deep synchronous chains when partial availability or latency multiplication is the controlling constraint.

### Event-Driven Or Asynchronous Messaging

Fit buffering, decoupled availability, independent consumption, or workflows that naturally represent immutable business facts.

Pay explicitly for message schemas and versioning, idempotency, ordering assumptions, correlation IDs, retry policy, dead-letter handling, backpressure, and processing observability. Do not add a broker merely to avoid defining a direct caller contract.

### Local Transaction

Prefer local transactional consistency while one data owner can satisfy the invariant. It offers the lowest coordination and recovery cost.

### Saga Or Eventual Consistency

Use when independently owned state must coordinate without a global transaction and the domain can define compensations, intermediate states, and recovery ownership. Avoid when partial states are unacceptable or compensations are undefined.

### CQRS And Event Sourcing

Use CQRS when read and write models have proven, materially different constraints. Use event sourcing when an event log is itself the required source of truth and replay, audit, versioning, and correction semantics are owned.

Avoid both for ordinary CRUD or speculative flexibility; they add model duplication, migration, debugging, storage, and operator costs.

## API And Integration Patterns

### REST

Fit resource-oriented public or service boundaries with standard HTTP semantics. Define methods, status and error contracts, authentication, authorization, compatibility, pagination, and content negotiation as caller-visible behavior.

### GraphQL

Fit multiple clients with materially different graph-shaped read demand and an owner able to govern schema evolution, field authorization, query cost, N+1 prevention, and observability.

Avoid when a small stable resource API is sufficient or query flexibility would transfer unbounded cost to the service.

### API Gateway

Fit a proven external boundary that needs centralized routing, authentication enforcement, throttling, or protocol transformation. Avoid using a gateway to conceal unclear service ownership or duplicate business behavior.

## Security Patterns

Treat mandatory security and compliance requirements as constraints before economic comparison.

- Apply least privilege and explicit trust boundaries.
- Use strong service identity and mTLS when the threat model, environment, or policy requires it.
- Use JWT/OIDC only with explicit issuer, audience, validation, expiry, key-rotation, and revocation boundaries.
- Add throttling, WAF, intrusion detection, security audit logs, or SIEM integration when exposure, abuse evidence, or regulation justifies their operational supply.

Do not copy an enterprise security stack into a low-exposure system without a threat or policy owner, but never trade away a proven security invariant for convenience.

## Scaling Patterns

### Stateless Horizontal Scaling

Fit independently replicated request processing after identifying the actual bottleneck. External session state, connection limits, shared dependencies, autoscaling signals, and deployment safety become part of the design.

### Cache

Use after measuring repeated expensive reads and defining ownership, key shape, invalidation, freshness, capacity, and failure behavior. Prefer local or request-scoped caching before shared distributed cache when it meets demand.

### Read Replica

Use when measured read load constrains the primary and consumers can tolerate replication lag. Define read routing and consistency expectations.

### Sharding

Use only when a single data owner cannot meet proven capacity or locality demand within the decision horizon. Shard keys, rebalancing, cross-shard operations, hotspots, and recovery are permanent ownership costs.

### Multi-Region

Use when measured latency, recovery objectives, jurisdiction, or availability requirements justify replication, failover, consistency, data-governance, and testing cost. Backups and tested restore often satisfy current recovery demand more cheaply.

## Resilience Patterns

### Health Checks And Recovery

Define health, readiness, dependency health, degraded modes, backup, restore, and recovery ownership at the boundary that can act on the result.

### Retry And Circuit Breaker

Use retries only for classified transient failures with bounded attempts, backoff, jitter, deadlines, and idempotency. Use circuit breakers when repeated calls amplify a proven cascading-failure risk. Avoid adding them as decoration around unclassified errors.

### Fault Injection And Chaos

Use when rollback, blast-radius controls, hypotheses, runtime observability, and recovery owners are mature enough to learn safely. Prefer narrower conformance or failure-path tests before production chaos.

## Evolution Patterns

### Adapter Or Anti-Corruption Boundary

Use when an external or legacy model is volatile enough that isolating translation protects stable domain behavior. Avoid pass-through wrappers with no translation, policy, or ownership value.

### Feature Flag

Use for controlled rollout or rollback when every flag has an owner, observable success condition, safe default, and removal trigger. Unowned flags create permanent state-space cost.

### Strangler Migration

Use when incremental replacement lowers cutover risk and each slice has explicit routing, compatibility, data ownership, rollback, and retirement conditions.

### Architecture Fitness Function

Use executable dependency, schema, performance, security, or operability checks for boundaries whose drift has material consequences. Do not create a metric merely because it is measurable.

## Pattern Decision Card

For each selected pattern, record only material fields:

- protected boundary and owner
- current demand or hard constraint
- smallest rejected alternative and discard reason
- lifecycle costs and cost bearer
- state, data, dependency, and failure ownership
- executable oracle
- rollout and rollback boundary
- observable upgrade or retirement trigger
