# Go Implementation Review Checklist

## Purpose

Apply Go-specific evidence to a bounded implementation review. The primary review workflow owns findings, causality, verdict, and repair authority.

## Profile Selection

Identify the changed Go archetype before reviewing architecture:

- CLI or operator tool: read `cli-tool-patterns.md`
- API or network service: read `api-service-patterns.md`
- library or small package: apply only the shared `go-guidelines` baseline
- mixed approved application: read both purpose profiles, but apply each only to its owned surface

Do not require service packages in a CLI, Cobra in an API service, or either profile in a small library.

## Deterministic Evidence

Use the nearest owning module and repository commands. Prefer:

```text
gofmt diff for changed Go files
go test ./...
go vet ./...
project-configured analyzers when configured
```

Add `go test -race ./...` only when concurrent behavior or shared state is in the review slice. Add `govulncheck ./...` when dependency or release risk makes it a declared oracle. Do not assume a workstation-global analyzer version when the module owns a tool directive or other pinning mechanism.

## Shared Review Concerns

- module and Go version consistency
- ignored errors and missing resource cleanup
- error wrapping and stable `errors.Is` or `errors.As` classification where callers require it
- context propagation and cancellation ownership
- goroutine, channel, timer, and shutdown lifecycle
- interfaces introduced only at justified consuming boundaries
- tests that exercise behavior rather than implementation trivia
- build output and generated files staying inside project policy

## CLI Review Concerns

- parser choice matches the approved command shape
- command adapters do not own business logic
- stdout, stderr, exit codes, and machine output are explicit
- completion is side-effect free
- state-changing behavior has preview, confirmation, partial-failure, and recovery semantics
- subprocess invocation does not construct unsafe Shell strings

## API Review Concerns

- transport and application boundaries are explicit without ceremonial layers
- server timeouts, input bounds, graceful shutdown, and contexts are correct
- status and error mapping do not leak sensitive internals
- authentication, authorization, middleware, health, readiness, and observability match the service boundary
- `httptest` or integration evidence covers the changed contract

## Finding Boundary

Report only evidence causally linked to the reviewed diff and its approved oracle. Treat pre-existing architecture, unrelated package debt, optional framework preferences, and unconfigured analyzers as non-blocking unless the current change activates them. Reviewers return candidate findings only; the lifecycle controller owns repair.
