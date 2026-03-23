# Development Skills

Claude Code plugin skills for language-level guidelines, architecture/quality/security/testing standards, and containerization.

## Included Skills

### Language Guidelines
- `python-guidelines`: Python language/tooling standards (uv, ruff, typing, pytest, service/script patterns).
- `go-guidelines`: Go language/tooling standards (modules, gofmt, golangci-lint, service patterns).
- `shell-guidelines`: Shell scripting standards (strict mode, quoting, portability, ShellCheck, script patterns).
- `lua-guidelines`: Lua language standards for scripts/config + validation (luac, selene).
- `powershell-guidelines`: PowerShell 7 scripting standards (strict mode, PSScriptAnalyzer, cross-platform).

### Decision Trees
- `language-decision-tree`: Canonical language selection for new code (Python/Shell/Go/Lua).
- `tool-decision-tree`: Tool selection and progressive search workflow (COUNT→PREVIEW→EXECUTE).

### Architecture & Quality
- `architecture-patterns`: Architecture pattern guidance and layering principles.
- `clean-architecture`: Layering boundaries and dependency direction rules.
- `development-standards`: Cross-language development standards (naming, structure, reviews).
- `quality-standards`: Quality metrics and continuous improvement guidance.
- `testing-strategy`: Testing strategy and coverage standards (80%+ coverage, AAA pattern).

### Security & Logging
- `security-guardrails`: Security implementation guardrails (credentials, TLS/CORS, input validation).
- `security-logging`: Security-focused logging and validation conventions (audit trails, tamper-evident).
- `logging-standards`: Structured logging standards and observability (format, levels, correlation).
- `error-patterns`: Error handling patterns and reliability conventions (circuit breaker, retry, cleanup).

### Infrastructure & Tools
- `docker-multiarch-build`: Multi-arch Docker build patterns (buildx, multi-stage, amd64/arm64).
- `context7-registry`: Context7 skills registry CLI for discovering and installing external library docs.
- `web-fetch`: Web content fetching and processing (Jina Reader, Firecrawl fallback).
### Git & Commit Workflow
- `smart-commit`: Analyze git changes, split into focused commits grouped by business purpose.
- `smart-squash`: Cleanup unpushed commit history by analyzing and grouping commits by business logic.

### Documentation
- `documentation-structure`: AGENTS.md/CLAUDE.md/README.md relationships, content organization by audience.
- `review-design`: Cross-model review for design documents with opt-in repair-review loop.
- `review-plan`: Cross-model review for implementation plans with opt-in repair-review loop.
- `review-code-impl`: Cross-model review for code implementation against an implementation plan baseline, with opt-in repair-review loop.

## Review Workflows

- `review-design`: review `design.md`-style documents.
- `review-plan`: review implementation-plan documents such as `implementation.md`.
- `review-code-impl`: review code implementation, optionally against an implementation-plan baseline passed by `--plan`.

Default reviewer models:
- `codex`: `gpt-5.4`
- `claude`: `claude-opus-4-6`
- `gemini`: `gemini-3.1-pro-preview`

Reviewer execution modes:
- `codex`: read-only sandbox
- `claude`: plan/read-only permission mode
- `gemini`: `--approval-mode yolo`, constrained by isolated workspace and review-only prompt

Default review timeout:
- `1800` seconds per reviewer invocation

Repair behavior:
- `review-only` is the default
- `repair-review` is explicit opt-in
- runner output reports `review_mode` as `cross-driver` or `same-driver`
- runner output reports the exact `reviewer_model`

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
