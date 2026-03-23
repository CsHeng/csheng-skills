---
name: go-guidelines
description: "Use when editing/creating Go code, Go services, or reviewing Go syntax. Covers go.mod, gofmt, golangci-lint, service patterns, and code review. 中文触发：Go 代码/服务/审查。"
---

# Go Guidelines

## Purpose

Define Go coding and tooling standards: module hygiene, formatting, linting, testing, service patterns, and code review.

## Scope

In-scope:
- Editing or creating Go code (`.go`)
- Go modules, services, and CLI code
- Code review and syntax audit for Go files

Out-of-scope:
- Language selection (see `language-decision-tree` skill)
- Tool selection and search/refactor workflow (see `tool-decision-tree` skill)

## Progressive Disclosure

- Service structure and layering: `references/service-patterns.md`
- Code review DEPTH workflow and checklist: `references/review-checklist.md`

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

For generic error handling patterns (resilience, resource management, monitoring), see the `error-patterns` skill.

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

