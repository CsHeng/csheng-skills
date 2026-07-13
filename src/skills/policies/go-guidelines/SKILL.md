---
name: go-guidelines
description: "Apply Go-specific policy to existing or approved Go modules, CLI tools, API services, tests, and reviews: module hygiene, standard toolchain checks, explicit errors and context, purpose-specific architecture, and delivery. Use as a language overlay; do not own language selection or lifecycle control."
---

# Go Guidelines

## Purpose

Define the shared Go policy baseline, then load only the architecture reference that matches the implementation archetype. The primary workflow owns lifecycle order and `language-decision-tree` owns any unfixed implementation-language decision.

## Scope

In-scope:

- editing or creating approved Go code and modules
- Go CLI tools and API services
- Go tests, build configuration, and implementation review

Out-of-scope:

- choosing whether new persisted code should use Go; see `language-decision-tree`
- ad hoc agent command and tool selection; see `tool-decision-tree`
- generic resilience or logging policy beyond Go-specific application; see `error-patterns` and `logging-standards`

## Progressive Disclosure

- CLI tools and operator commands: `references/cli-tool-patterns.md`
- API and network services: `references/api-service-patterns.md`
- Implementation review workflow: `references/review-checklist.md`

Load both purpose profiles only when one approved project genuinely owns both a CLI control surface and an API server. Do not apply service layering to a small CLI or Cobra command structure to an API-only service.

## Shared Baseline

1. Use Go modules as the source of truth.
   - Commit consistent `go.mod` and `go.sum` files.
   - Declare the minimum supported Go version in `go.mod`.
   - Run `go mod tidy` when imports or tool dependencies change, then review the module diff.
2. Use the standard toolchain first.
   - Format changed Go files with `gofmt`.
   - Run `go test ./...` to compile packages and execute tests.
   - Run `go vet ./...` for suspicious constructs not rejected by compilation.
   - Run project-owned analyzers such as Staticcheck or golangci-lint when configured; do not introduce an aggregator only to satisfy this skill.
3. Keep developer tools project-owned when reproducibility matters.
   - On Go 1.24 or newer, prefer a `go.mod` tool directive for versioned Go developer tools.
   - Use the repository's existing pre-1.24 mechanism when the module version requires it.
4. Handle errors explicitly.
   - Do not ignore returned errors unless the API documents that the result is irrelevant and the reason is recorded.
   - Add operation context with `fmt.Errorf("operation: %w", err)` when propagating an underlying error.
   - Define sentinel or custom error types only when callers need stable programmatic classification through `errors.Is` or `errors.As`.
   - Log an error at the boundary that owns presentation or recovery; avoid logging and returning the same error at every layer.
5. Propagate cancellation and deadlines.
   - Accept `context.Context` as the first parameter for request-scoped, blocking, network, subprocess, or other IO-heavy work.
   - Do not store request contexts in long-lived structs.
6. Keep abstractions demand-driven.
   - Define small interfaces at the consuming boundary only when multiple implementations, fakes, or isolation requirements justify them.
   - Do not introduce interfaces, repositories, or layers solely because the code is written in Go.
7. Test behavior at the narrowest useful boundary.
   - Use the standard `testing` package by default.
   - Prefer table-driven tests when they improve coverage and readability.
   - Use `httptest`, fakes, temporary directories, and injected IO instead of global process state when practical.

## Optional Checks

Use these when the project or risk profile calls for them:

- `go test -race ./...` for concurrent or shared-state code
- Staticcheck for low-noise semantic analysis
- `govulncheck ./...` for applications with third-party dependencies or release artifacts
- golangci-lint when configured as the repository's analyzer aggregator

Pin reproducible Go tools through the owning module rather than assuming a workstation-global version.

## Checklist

- `go.mod` declares the supported Go baseline and `go.sum` is consistent
- changed Go files are `gofmt` clean
- `go test ./...` and `go vet ./...` pass
- project-configured analyzers pass when configured
- returned errors, cancellation, and resource cleanup are explicit
- tests cover the changed core behavior
- the matching CLI or API purpose profile has been applied
