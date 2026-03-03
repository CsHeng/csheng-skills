# Development Skills

Claude Code plugin skills for language-level guidelines, architecture/quality/security/testing standards, and containerization.

## Included Skills

- `python-guidelines`: Python language/tooling standards (uv, ruff, typing, pytest).
- `go-guidelines`: Go language/tooling standards (modules, gofmt, golangci-lint, tests).
- `shell-guidelines`: Shell scripting standards (strict mode, quoting, portability, ShellCheck).
- `lua-guidelines`: Lua language standards for scripts/config + validation.
- `clean-architecture`: Layering boundaries and dependency direction rules.
- `architecture-patterns`: Architecture pattern guidance and layering principles.
- `development-standards`: Cross-language development standards (naming, structure, reviews).
- `quality-standards`: Quality metrics and continuous improvement guidance.
- `security-guardrails`: Security implementation guardrails.
- `security-logging`: Security-focused logging and validation conventions.
- `testing-strategy`: Testing strategy and coverage standards.
- `python-services-dev`: Python HTTP service structure (uv, logging, tests).
- `python-scripts-dev`: Python script/tool patterns (uv/uvx, CLI structure).
- `go-services-dev`: Go service structure (interfaces, context propagation, testing).
- `shell-scripts-dev`: Shell orchestration patterns (zsh/bash/sh portability and safety).
- `docker-multiarch-build`: Multi-arch Docker build patterns (buildx, multi-stage).
- `context7-registry`: Context7 skills registry CLI for discovering and installing external library docs.
- `error-patterns`: Error handling patterns and reliability conventions (circuit breaker, retry, cleanup).
- `logging-standards`: Structured logging standards and observability (format, levels, correlation).
- `powershell-guidelines`: PowerShell 7 scripting standards (strict mode, PSScriptAnalyzer, cross-platform).
- `smart-commit`: Analyze git changes, split into focused commits grouped by business purpose.

## Design Principles

- Keep skills thin and operational: purpose, scope, deterministic steps, and a short checklist.
- Avoid long tutorial content inside skills; keep examples minimal.
- Prefer cross-skill references over duplication (for example, services skills reference `clean-architecture`).

## Install

Configure the marketplace entry in settings:

```bash
./install.sh
```

Project scope (writes to `$CLAUDE_PROJECT_DIR/.claude/settings.json` when available):

```bash
./install.sh --scope project
```

Local scope (writes to `$CLAUDE_PROJECT_DIR/.claude/settings.local.json` when available):

```bash
./install.sh --scope local
```
