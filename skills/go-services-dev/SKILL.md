---
name: go-services-dev
description: "Go service structure and conventions. Activates for: Go service, HTTP service, gRPC service, Go API, context propagation. 中文触发：Go 服务、HTTP 服务、gRPC 服务、Go API、context 传递。"
---

# Go Services Development

## Purpose

Create a Go service with stable boundaries and predictable IO behavior.

## Deterministic Steps

1. Structure by responsibility (align with `clean-architecture`):
   - handlers: HTTP/gRPC transport
   - services: business rules
   - repositories: persistence/IO
   - models: domain types
2. Use interfaces at boundaries where implementations vary (storage, external clients).
3. Pass `context.Context` through all IO and service calls.
4. Wrap errors with context and return typed errors when appropriate.
5. Test:
   - services against fakes/mocks
   - repositories with integration tests

## Checklist

- No circular imports
- `context.Context` is threaded through IO
- Interfaces defined before implementations
- `go test ./...` passes

