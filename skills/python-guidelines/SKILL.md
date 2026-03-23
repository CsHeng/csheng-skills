---
name: python-guidelines
description: "Use when editing/creating Python code, scripts, services, or reviewing Python syntax. Covers uv, ruff, ty, pytest, service patterns, and code review. 中文触发：Python 代码/脚本/服务/审查。"
---

# Python Guidelines

## Purpose

Define Python coding and tooling standards: dependency management, formatting/linting, type safety, error handling, testing, script/service patterns, and code review.

## Scope

In-scope:
- Editing or creating Python code (`.py`)
- Python scripts, CLIs, and service codebases
- Code review and syntax audit for Python files

Out-of-scope:
- Language selection (see `language-decision-tree` skill)
- Tool selection and search/refactor workflow (see `tool-decision-tree` skill)

## Progressive Disclosure

- Script and CLI patterns: `references/script-patterns.md`
- Service structure and layering: `references/service-patterns.md`
- Code review DEPTH workflow and checklist: `references/review-checklist.md`

## Toolchain (Required)

- Package/dependency management: `uv`
- Configuration SSOT: `pyproject.toml`
- Formatting + linting: `ruff`
- Testing: `pytest`
- Type checking: `ty` (preferred; use `mypy`/`pyright` only when a project requires it)
- Virtual env: single `.venv` at repo root when a venv is needed

## Cache Isolation

REQUIRED: Keep Python tool caches (`.ruff_cache`, `.pytest_cache`, `__pycache__`) out of project root.

### Environment Variables

| Variable | Value | Effect |
|---|---|---|
| `PYTHONDONTWRITEBYTECODE` | `1` | Suppress `.pyc` generation |
| `PYTHONPYCACHEPREFIX` | `~/.cache/python` | Redirect `__pycache__` |
| `RUFF_CACHE_DIR` | `~/.cache/ruff` | Redirect `.ruff_cache` |

When generating ruff commands without a known environment, pass explicitly:

```bash
RUFF_CACHE_DIR="$HOME/.cache/ruff" uv tool run ruff check .
```

### pytest Cache

No dedicated environment variable. Use per-project `pyproject.toml`:

```toml
[tool.pytest.ini_options]
cache_dir = "~/.cache/pytest"
```

Or pass via `PYTEST_ADDOPTS`:

```bash
export PYTEST_ADDOPTS="-o cache_dir=$HOME/.cache/pytest"
```

Trade-off: `PYTEST_ADDOPTS` overrides project-level `cache_dir` and shares one cache across projects, which may cause `--lf` cross-contamination.

### Rules

REQUIRED: When generating Python tooling commands or `pyproject.toml` configs, use cache-redirecting env vars or config keys to avoid polluting the project root.
PROHIBITED: Assume cache env vars are pre-set in the user's shell; pass them explicitly when the environment is unknown.

## Deterministic Steps

1. Use the canonical Python toolchain
   - Use `uv` for dependency management and tool execution.
   - Treat `pyproject.toml` as the source of truth for dependencies and tool config.
   - Prefer a single project `.venv` at repository root when a venv is needed.
2. Enforce type safety
   - Add type hints for all function parameters and return values.
   - Prefer modern `X | None` unions when the runtime supports it.
   - Avoid `typing.Any` unless there is a hard constraint and document the reason.
   - Prefer `ty check` for static type checking in local and CI workflows.
3. Enforce formatting and linting
   - Use Ruff for formatting and linting.
   - Keep Ruff configuration in `pyproject.toml`.
   - Prefer running via `uv tool run` to avoid ad-hoc environments.
4. Implement predictable error handling
   - Catch specific exceptions; avoid `except Exception:` unless it is a boundary with structured logging and re-raise/wrap.
   - Avoid bare `except:` in production code.
   - Validate inputs early and fail fast with actionable error messages.
5. Testing defaults
   - Use `pytest` as the default test runner.
   - Prefer behavior tests for core logic (test functions/classes directly; keep CLI plumbing thin).
   - Cover happy path + failure path for critical logic.
6. Security hygiene
   - Never hardcode secrets or credentials in source code.
   - Redact sensitive values in logs (tokens, passwords, keys).

## Operational Commands (Examples)

```bash
uv tool run ruff format .
uv tool run ruff check .
uv tool run ty check .
uv tool run pytest -q
```

## Rules (Hard Constraints)

### Type Safety
REQUIRED: Add type hints for all function parameters and return values.
PREFERRED: Use `X | None` syntax when the runtime supports it.
PREFERRED: Run `ty check` as the default type checker.
PROHIBITED: Use `typing.Any` unless absolutely necessary.

### Constants
REQUIRED: Replace magic numbers with named constants.
REQUIRED: Use `UPPER_SNAKE_CASE` for constants and include units in names when relevant (for example: `TIMEOUT_SECONDS`).
PROHIBITED: Use mutable default arguments in function definitions.

### Error Handling
REQUIRED: Catch specific exceptions and emit actionable errors.
PROHIBITED: Use bare `except:` clauses in production code.
PROHIBITED: Catch generic exceptions without specific handling at boundaries.

For generic error handling patterns (resilience, resource management, monitoring), see the `error-patterns` skill.

#### Custom Exception Classes
REQUIRED: Define domain-specific exceptions inheriting from appropriate base classes.
REQUIRED: Include context in exception messages.

Example:
```python
from typing import Any

class ValidationError(Exception):
    """Raised when input validation fails"""

class DatabaseError(Exception):
    """Raised when database operation fails"""

def process_user_data(user_data: dict[str, Any]) -> dict[str, Any]:
    try:
        if not user_data.get('email'):
            raise ValidationError("Email is required")

        result = save_to_database(user_data)
        return result

    except ValidationError as e:
        logger.error(f"Validation failed: {e}")
        raise
    except DatabaseError as e:
        logger.error(f"Database error: {e}")
        raise
    except Exception as e:
        # Boundary pattern: catch-all with logging and context wrapping
        logger.error(f"Unexpected error: {e}")
        raise RuntimeError("Processing failed") from e
```

### Security
PROHIBITED: Hardcode secrets or configuration values in source code.
REQUIRED: Redact sensitive values in logs (tokens, passwords, keys).

### Code Quality
REQUIRED: Use Ruff as the formatter and linter.
REQUIRED: Keep tool configuration in `pyproject.toml`.

### Documentation
REQUIRED: Use docstrings for public modules/classes/functions.
PREFERRED: Use Google-style docstrings for public APIs and include usage expectations where it helps maintainability.

## Checklist

- Type hints on public functions
- Ruff format + lint configured and runnable via uv
- ty check configured and runnable via uv
- `pyproject.toml` is the config SSOT
- No secrets committed
- Tests exist for core logic paths
