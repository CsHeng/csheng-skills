---
name: python-services-dev
description: "Python HTTP service structure and conventions. Activates for: Python service, Flask service, FastAPI service, Python API, service layering. 中文触发：Python 服务、Flask 服务、FastAPI 服务、Python API、服务分层。"
---

# Python Services Development

## Purpose

Create a Python service with predictable structure and clean layering.

## Dependencies

- Python 3.13+ (or project standard)
- uv for dependency management
- ruff for formatting and linting

## Deterministic Steps

1. Create structure aligned to `clean-architecture`:
   - handlers: transport adapters
   - services: business rules
   - repositories: persistence/IO
   - models: domain entities
2. Add an application entrypoint under `cmd/` (thin).
3. Configure logging once at startup; use structured context fields.
4. Add a minimal health endpoint.
5. Add tests:
   - unit tests for services
   - integration tests for repositories when needed

## Checklist

- Handlers contain no business logic
- Services contain no framework-specific imports
- Repository interfaces are defined at the service boundary
- `ruff format` and `ruff check` pass
- Tests cover service behavior

