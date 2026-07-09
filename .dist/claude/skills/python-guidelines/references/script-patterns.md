# Python Script and CLI Patterns

## Purpose

Build maintainable scripts and CLIs with clear IO, logging, and testability.

## Scope

- Script/CLI layout and invocation patterns
- Dependency management expectations (uv/uvx)
- Error handling and logging defaults

## Deterministic Steps

1. Decide interface:
   - module entrypoint: `python -m package.cli`
   - or executable script with `#!/usr/bin/env python3`
2. Define IO contract:
   - arguments, inputs, outputs, exit codes
3. Add logging early:
   - log at start/end, and on all failure branches
4. Fail fast with actionable errors:
   - validate inputs before doing work
5. Add tests for behavior of core functions (not CLI plumbing).

## Checklist

- Type hints for public functions
- `if __name__ == "__main__":` guard for executable scripts
- No inline python in shell (`python -c`) for anything non-trivial
- Clear exit codes (0 success, non-zero failure)
