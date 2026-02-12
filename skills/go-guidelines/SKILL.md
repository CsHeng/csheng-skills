---
name: go-guidelines
description: "Go language guidelines and toolchain (go.mod, gofmt, golangci-lint, tests). Activates for: Go conventions, go.mod/go.sum, gofmt, golangci-lint, Go service/CLI code. 中文触发：Go 规范/风格、go.mod/go.sum、gofmt、golangci-lint、Go 服务/CLI。"
---

# Go Guidelines

## Purpose

Define Go coding and tooling standards: module hygiene, formatting, linting, testing, and reliability conventions.

## Scope

In-scope:
- Editing or creating Go code (`.go`)
- Go modules and services (language-level guidance only)

Out-of-scope:
- Language selection (see `rules/15-language-decision-tree.md`)
- Tool selection and search/refactor workflow (see `rules/20-tool-decision-tree.md`)

## Deterministic Steps

1. Use Go modules as the SSOT
   - Keep `go.mod` and `go.sum` committed and consistent.
   - Ensure the Go version is specified in `go.mod`.
2. Enforce formatting
   - Run `gofmt` on all Go files.
   - Prefer minimal formatting diffs (format before review).
3. Enforce linting
   - Use `golangci-lint` for code quality checks.
   - Keep configuration in `.golangci.yml` when needed.
4. Reliability conventions
   - Prefer explicit error handling; do not ignore returned errors.
   - Use `context.Context` for request-scoped cancellation/timeouts in services and IO-heavy code.
5. Testing defaults
   - Use the standard `testing` package for unit tests.
   - Prefer table-driven tests where it improves coverage and clarity.

## Error Handling

For generic error handling patterns (resilience, resource management, monitoring), see `error-patterns` skill.

### Custom Error Types
REQUIRED: Define domain-specific error types implementing the `error` interface.
REQUIRED: Use error wrapping with `fmt.Errorf("context: %w", err)` for stack context.
PROHIBITED: Ignore returned errors.

Example:
```go
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation error for %s: %s", e.Field, e.Message)
}

func ProcessUserData(userData map[string]interface{}) error {
    if email, ok := userData["email"]; !ok || email == "" {
        return &ValidationError{Field: "email", Message: "email is required"}
    }

    if _, err := saveToDatabase(userData); err != nil {
        return fmt.Errorf("database error: %w", err)
    }

    return nil
}
```

## Checklist

- `go.mod` present and tidy
- `gofmt` clean
- `golangci-lint` passes (when configured)
- No ignored errors
- Tests cover core logic paths

