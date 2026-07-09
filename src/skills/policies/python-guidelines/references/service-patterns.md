# Python Service Patterns

## Purpose

Create a Python service with predictable structure and clean layering.

## Dependencies

- Python 3.13+ (or project standard)
- uv for dependency management
- ruff for formatting and linting

## Structure

Align with clean-architecture principles:

- handlers: transport adapters
- services: business rules
- repositories: persistence/IO
- models: domain entities

## Conventions

1. Add an application entrypoint under `cmd/` (thin).
2. Configure logging once at startup; use structured context fields.
3. Add a minimal health endpoint.

## Testing

- unit tests for services
- integration tests for repositories when needed

## Checklist

- Handlers contain no business logic
- Services contain no framework-specific imports
- Repository interfaces are defined at the service boundary
- `ruff format` and `ruff check` pass
- Tests cover service behavior
