# Toolchain Baseline

Use this as a local development baseline when a target repository does not define stricter versions.

## Versions

- Python: 3.13+ with `X | None` union syntax.
- Go: 1.23+.
- Lua: 5.4+ with `luac -p` validation when applicable.
- PlantUML: 1.2025.9+ with `plantuml --check-syntax` validation.

## Environment

- Use `mise` for tool version management unless the target repository defines another owner.
- Use `uv` for Python package and environment workflows when the repository has no conflicting standard.
- Assume plain `python3` has only the standard library for ad hoc fallback commands.
- Use `uv run --with <package>` for one-off Python commands that require third-party packages.
- Do not add a Docker Compose `version` field.

## Shell Entry Points

- Prefer `#!/usr/bin/env bash` for CI or portable repository scripts.
- Prefer `#!/bin/zsh` only for local interactive macOS shell helpers.
- Keep third-party CLI flags in their native style.
- For custom scripts, prefer named long options and avoid positional write/delete behavior.
