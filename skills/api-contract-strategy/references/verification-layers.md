# Verification Layers

## Topology

The Wire Contract should fan out into two independently owned branches:

```text
                         Wire Contract
                          /          \
                         v            v
              Provider Conformance  Consumer Adapter
                         \            /
                          v          v
                       Business Workflow
                               |
                               v
                       Critical UI / E2E
```

Provider and consumer evidence join at Business Workflow verification. Neither branch substitutes for the other.

Runtime probes, canaries, synthetic checks, and SLOs observe deployed behavior across this topology. They are orthogonal runtime evidence, not a later test rung and not a substitute for pre-merge correctness.

## Wire Contract

Question: What communication is structurally allowed?

Typical evidence:

- operations and methods
- path, query, and header parameters
- request and response schemas
- status codes and content types
- authentication and authorization requirements
- stable error envelopes
- examples and deprecation metadata

Schema compatibility detects structural changes. semantic compatibility covers meaning that a schema cannot prove, such as units, retry policy, ordering, consistency, migration behavior, and status semantics.

## Provider Conformance

Question: Does the provider implement the contract?

Exercise the real HTTP or protocol boundary with the real router, middleware, authentication path, deterministic data store, and isolated fixtures. Validate request acceptance, response status, headers, content type, schema, and errors.

Do not replace this layer with service-method or handler-function calls that bypass the boundary under contract.

## Consumer Adapter

Question: Does each consumer correctly use the contract?

Own this evidence in the consumer repository or domain. Cover serialization, decoding, DTO mapping, authentication, token refresh, error mapping, retries, offline behavior, persistence, and platform-specific transport.

Generated types or clients reduce duplication but do not prove consumer policy. Trust generated internals through pinned generator versions, deterministic generation checks, compilation, and a few boundary fixtures.

## Business Workflow

Question: Does an important cross-operation scenario work?

Cover critical journeys, historical regressions, deployment smoke, and state transitions across operations. Prefer business sequences such as login -> create -> update -> query -> delete.

Do not create one workflow file per endpoint. That duplicates the Wire Contract.

## Critical UI / E2E

Question: Can a user complete behavior owned by the browser, app, or device UI?

Keep this layer narrow: authentication, payment, high-value workflows, and behavior that cannot be proven below the UI.

Do not use UI tests to discover schema, serialization, or provider-contract failures that should fail in earlier layers.

## Duplication Smells

- the same schema is maintained manually in provider, web, mobile, and fixtures
- workflow collections mirror every operation instead of business journeys
- E2E tests diagnose wire-shape failures
- unit tests mock away the real provider or consumer boundary
- generated-client internals receive broad handwritten test duplication
- runtime probes are used as the first compatibility signal
- test count grows while a missing verification layer remains unowned
