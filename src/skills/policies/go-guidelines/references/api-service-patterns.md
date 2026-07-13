# Go API Service Patterns

## Purpose

Build Go HTTP and network services with explicit transport boundaries, bounded lifecycle behavior, testable application logic, and production-safe defaults.

## Framework Selection

Prefer `net/http` for new services when its router and middleware capabilities satisfy the API contract. Add a lightweight router or framework only for concrete routing, binding, middleware, or project-consistency benefits.

Preserve the existing framework in an established service unless an approved redesign justifies migration. Gin, Chi, gRPC, or another existing framework is a project boundary, not an automatic defect. Keep application logic independent from framework-specific request and response types.

## Boundaries

Use the smallest structure that keeps responsibilities clear:

- transport adapters decode requests, authenticate and authorize, call an application operation, and encode responses
- application operations own use-case sequencing and domain decisions
- external adapters own databases, filesystems, queues, subprocesses, and remote APIs
- domain types describe stable business data without depending on HTTP framework types

Do not require handlers, services, repositories, and interfaces as four packages for every API. Add a boundary only when it separates behavior, ownership, testing, or replacement concerns. Define interfaces at the consuming package and keep them narrow.

## Server Lifecycle

- Configure header, read, write, idle, and shutdown timeouts appropriate to the protocol and workload.
- Propagate request contexts through blocking and external calls.
- Implement graceful shutdown so new work stops and in-flight work receives a bounded drain period.
- Handle listener, serve, and shutdown errors explicitly.
- Bound request bodies and other attacker-controlled resource use.
- Close response bodies, rows, files, and other acquired resources on all paths.

## HTTP Contract

- Validate inputs at the transport boundary and return stable status and error shapes.
- Keep error classification separate from internal error text; do not expose stack or credential details.
- Make idempotency and retry safety explicit for state-changing endpoints.
- Apply authentication, authorization, CORS, rate limiting, and request-size policy according to the service's actual exposure.
- Use middleware for cross-cutting transport concerns, not hidden business control flow.

## Health And Observability

Expose health and readiness separately when startup or dependency state makes the distinction meaningful. Liveness should prove the process can serve; readiness should prove it may receive traffic. Do not make health checks perform unbounded or state-changing work.

Use structured logs with request or correlation identifiers where the surrounding platform supports them. Emit metrics and traces for decision-relevant latency, errors, saturation, and external dependency behavior. Redact tokens, credentials, authorization headers, and sensitive payload fields.

## Configuration And Secrets

Load typed configuration explicitly, validate it before serving, and make precedence deterministic. Prefer environment or project-owned secret providers for credentials. Do not log the complete environment or configuration. Keep runtime configuration separate from image build inputs.

## Testing

- Test application operations without starting a network listener when the transport is not the behavior under test.
- Use `httptest` for handlers, middleware, status codes, headers, bodies, cancellation, and error mapping.
- Use contract or integration tests for databases, queues, and external APIs when fakes cannot protect the real boundary.
- Cover shutdown, timeout, malformed input, authorization denial, dependency failure, and partial-response behavior when material.
- Use race detection for shared state and concurrent request handling when the risk warrants it.

## Delivery

Build an explicit binary or runtime-neutral container image. Use a minimal runtime image only when it still provides required certificates, timezone data, user identity, and debugging or health behavior. Run as a non-root user when the service does not require elevated privileges. Keep immutable image identity and runtime placement with the owning deployment system.

## Checklist

- framework choice is justified or inherited from the existing service
- transport types do not leak into application or domain logic
- server timeouts and graceful shutdown are explicit
- authentication, authorization, input bounds, and error exposure match the threat boundary
- health, readiness, logging, metrics, and redaction are operationally meaningful
- `httptest` and integration tests cover the material service contract
