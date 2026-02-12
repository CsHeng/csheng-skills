---
name: clean-architecture
description: "Clean Architecture patterns for layered design. Activates for: clean architecture, layered design, module boundaries, dependency direction, handler/service/repository. 中文触发：Clean Architecture、分层设计、模块边界、依赖方向、handler/service/repository 结构。"
---

# Clean Architecture

## Purpose

Define stable boundaries so business logic stays independent from transport, persistence, and framework choices.

## Scope

In-scope:
- Dependency direction rules and layer responsibilities
- Interface-first design and dependency inversion
- Test strategy aligned to layers

Out-of-scope:
- Language-specific framework setup (see `python-services-dev` and `go-services-dev`)

## Layer Contract

Layers (outer to inner):
- handlers: HTTP/gRPC/CLI adapters, request parsing, response formatting
- services: business rules, validation, orchestration
- repositories: persistence and external IO
- models: domain entities and value objects

Dependency direction:
- outer layers may reference inner layers
- inner layers must not reference outer layers
- cross-boundary calls go through interfaces

## Deterministic Steps

1. Define domain models first (entities, invariants, validation rules).
2. Define repository interfaces in the service layer (what the service needs, not how it is stored).
3. Implement services using interfaces only; pass dependencies via constructors.
4. Implement repositories in outer layers; keep IO and mapping isolated.
5. Implement handlers as thin adapters; no business rules in handlers.
6. Add tests:
   - services: behavioral tests against in-memory or fake repositories
   - repositories: integration tests
   - handlers: minimal routing/serialization tests

## Checklist

- Dependencies point inward (handlers -> services -> repositories -> models)
- Interfaces exist at the boundary where the dependency would otherwise point outward
- Handlers contain no business rules
- Services contain no framework-specific imports
- Repositories contain no business rules
- Tests focus on behavior at the service layer

