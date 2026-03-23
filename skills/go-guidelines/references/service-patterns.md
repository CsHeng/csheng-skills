# Go Service Patterns

## Purpose

Create a Go service with stable boundaries and predictable IO behavior.

## Structure by Responsibility

Align with clean-architecture principles:

- handlers: HTTP/gRPC transport
- services: business rules
- repositories: persistence/IO
- models: domain types

## Conventions

1. Use interfaces at boundaries where implementations vary (storage, external clients).
2. Pass `context.Context` through all IO and service calls.
3. Wrap errors with context and return typed errors when appropriate.

## Testing

- services: test against fakes/mocks
- repositories: integration tests

## Checklist

- No circular imports
- `context.Context` is threaded through IO
- Interfaces defined before implementations
- `go test ./...` passes
