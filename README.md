# Development Skills

Dual-target Claude Code and Codex plugin skills organized around a sovereign harness kernel, with supporting truth, evaluation, policy, and tooling planes underneath it.

For AI-facing repository rules and the docs truth boundary, see `AGENTS.md`.

Human-facing workflow shorthand in this repository is:
- design
- plan
- execute

The underlying sovereign kernel still uses:
- `design-change`
- `plan-change`
- `execute-change`

## Sovereign Harness Kernel

The top-level harness authority for this repository is:

- `analyze-project`: Read-only project-state and truth query entry.
- `design-change`: Top-level change-design entry for scope, truth impact, and boundary impact.
- `plan-change`: Top-level planning entry for ordered tasks, dependencies, verification, and rollback triggers.
- `execute-change`: Top-level execution entry with approved-plan validation, one-plan execution-unit semantics, serial-first implementation, one-time worktree preflight, and deterministic review/verify/rollback outcomes.
- `review-change`: Top-level review gate that validates targets, routes into the lower-plane review family, and normalizes one harness verdict.
- `sync-truth`: Top-level truth-sync gate for stable truth updates with verified evidence.
- `close-change`: Top-level close gate for merge, release, or cleanup judgment.

Kernel defaults:
- serial-first execution
- human-sovereign approvals at design, plan, truth-sync, and close
- no unattended execution by default
- `design-change` and `plan-change` require artifact validation plus mandatory review before the human gate
- artifact handoff is gated by explicit `approval_status`, not by prose reminders alone
- when a gate already determines the next state, the harness reports that state instead of asking whether to continue

Harness runner coverage:
- `design-runner.sh`: design artifact pathing, validation, classification, and approval status
- `plan-runner.sh`: plan artifact pathing, upstream design linkage, validation, and approval status
- `review-runner.sh`: review target validation and lower-plane output normalization
- `execute-runner.sh`: approved-plan validation, touch set, verification scope, truth-sync requirement, and rollback target
  - task-ledger helpers, workspace-mode detection, and deterministic execution-result reporting

Lower-plane skills stay available as components the kernel can call, not as competing top-level authorities.

## Top-Level Commands

Claude Code plugin command surface mirrors the same seven entries:

- `/analyze-project`
- `/design-change`
- `/plan-change`
- `/execute-change`
- `/review-change`
- `/sync-truth`
- `/close-change`

These commands are Claude plugin-local entry points. Codex consumes the same `skills/` inventory through `.codex-plugin/plugin.json`.

## Lower-Plane Skills

### Truth Plane
- `analyze-project`: Read-only project explanation and drift detection across stable docs, code verification, and explicit historical search when needed.
- `organize-docs`: Stable-doc maintenance, docs truth boundary policy, and audience separation between `README.md` and `AGENTS.md`.

### Evaluation Plane
- `review-design`: Cross-model review for design documents with opt-in repair-review loop.
- `review-plan`: Cross-model review for implementation plans with opt-in repair-review loop.
- `review-code-impl`: Cross-model review for code implementation against an implementation plan baseline, with opt-in repair-review loop.
  - `repair-review` is a bounded helper, not the main lifecycle owner of execution.

### Policy Plane
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

## Docs

- Human-facing docs stay here in `README.md`.
- AI-facing rules and the repository docs truth boundary live in `AGENTS.md`.
- Docs directory search guidance and history notes live in `docs/README.md`.

## Review Defaults

The cross-model review skills in the inventory above share these defaults.

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
- Prefer wide-enough readonly review context with narrow-enough repair fences for plan-bound execution work.

## Install

Claude Code marketplace registration:

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

Codex local marketplace registration and plugin install:

```bash
./install-codex.sh
```

Manual Codex flow:

```bash
codex plugin marketplace add "$(pwd)/.codex-marketplace"
codex plugin add coding@csheng
```

Codex manifest validation:

```bash
python3 /Users/csheng/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py .
```
