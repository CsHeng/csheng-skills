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
- `implement-change`

## Source And Install Surfaces

- `src/skills/` is the source-of-truth skill tree.
- `contracts/skills.toml` is the source-of-truth exposure and invocation contract.
- `skills/` is tracked generated root-flat compatibility output for current plugin manifests, command wrappers, and local symlink exposure.
- `.dist/claude/` and `.dist/codex/` are ignored, reproducible target-specific install surfaces generated only when needed.
- `skills.index.json` is generated from `contracts/skills.toml`.

Regenerate and validate with:

```bash
python3 scripts/generate-skills-index.py
python3 scripts/flatten-skills.py --target root-flat
python3 scripts/generate-workflow-diagrams.py
bash scripts/check.sh
```

`scripts/check.sh` generates Claude and Codex install surfaces in a temporary directory and validates them without requiring or modifying `.dist/`. Generate a local external surface explicitly with `python3 scripts/flatten-skills.py --target claude` or `--target codex`.

The deterministic harness requires GNU/Homebrew Bash 4 or newer. On macOS, ensure Homebrew `bash` and GNU coreutils (`realpath --relative-to`) precede system tools on `PATH`.

## Sovereign Harness Kernel

The top-level harness authority for this repository is:

- `analyze-project`: Read-only project-state and truth query entry.
- `design-change`: Top-level change-design entry for scope, truth impact, boundary impact, and conditional economics-aware selection for material persisted architecture boundaries.
- `plan-change`: Top-level planning entry for ordered tasks, dependencies, verification, rollback triggers, conditional persisted implementation-language decisions, and reversible staging of approved architecture decisions.
- `implement-change`: Top-level execution controller with approved-plan validation, one-plan execution-unit semantics, serial-first implementation, controller-owned repair convergence, one-time worktree preflight, and deterministic review/verify/rollback outcomes.
- `review-change`: Top-level agent-native review gate that builds a bounded brief, prefers subagent review when useful, adjudicates candidate findings, and returns one harness verdict.
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
- `execute-runner.sh`: approved-plan validation, touch set, verification scope, truth-sync requirement, and rollback target
  - task-ledger helpers, workspace-mode detection, and deterministic execution-result reporting

Lower-plane skills stay available as components the kernel can call, not as competing top-level authorities.

## Optional Session Routing And Style

- `use-coding-skills`: Optional router for ambiguous multi-stage coding work, session boundaries, and compact handoffs. Direct workflow and policy matches do not load it first.
- `output-styles`: Agent-agnostic response modes plus the composition rule that one primary skill owns domain order while other matched skills contribute semantic overlays instead of competing report templates.

## Top-Level Commands

Claude Code plugin command surface mirrors the same seven entries:

- `/analyze-project`
- `/design-change`
- `/plan-change`
- `/implement-change`
- `/review-change`
- `/sync-truth`
- `/close-change`

These commands are Claude plugin-local entry points. Codex can consume the generated root `skills/` inventory through `.codex-plugin/plugin.json` when installed. Local environments may also expose the same generated tree through agent-specific skill paths such as `~/.agents/skills/coding`.

## Lower-Plane Skills

### Truth Plane
- `analyze-project`: Read-only project explanation and drift detection with selective terse output by default and a comprehensive truth-audit shape only when explicitly requested.
- `organize-docs`: Stable-doc maintenance, docs truth boundary policy, and audience separation between `README.md` and `AGENTS.md`.
- `skill-miner`: Read-only mining of Codex/Claude sessions, memory files, and project context docs to recommend generic or repo-local skill improvements; its OpenAI agent policy disables implicit invocation.

### Evaluation Plane
- `review-design`: Bounded design review against approved goals, architecture boundaries, and implementation surface.
- `review-plan`: Bounded plan review against the approved design, executable DAG, oracle, rollback, and readiness.
- `review-implementation`: Read-only diff review with explicit change causality; returns candidate evidence without owning adjudication or repair.

### Policy Plane
- `python-guidelines`: Python language/tooling standards (uv, ruff, typing, pytest, service/script patterns).
- `go-guidelines`: Shared Go language/tooling standards with separate CLI-tool and API-service architecture, library, test, and delivery profiles.
- `shell-guidelines`: Bash-first Shell and ad hoc command standards (explicit POSIX/zsh exceptions, strict mode, quoting, ShellCheck).
- `lua-guidelines`: Lua language standards for scripts/config + validation (luac, selene).
- `powershell-guidelines`: PowerShell 7 scripting standards (strict mode, PSScriptAnalyzer, cross-platform).

### Decision Trees
- `language-decision-tree`: Design and planning selection for new or migrated persisted implementation boundaries; ordinary existing-language edits and ad hoc commands are excluded.
- `tool-decision-tree`: Agent ad hoc command and tool composition with direct-tool preference, reviewable scratch-script fallback, and COUNT→PREVIEW→EXECUTE safety.

### Architecture & Quality
- `architecture-patterns`: Demand-first architecture selection with smallest-sufficient defaults, explicit lifecycle economics, observable upgrade triggers, and on-demand pattern/theory references.
- `clean-architecture`: Layering boundaries and dependency direction rules.
- `development-standards`: Cross-language development standards (naming, structure, reviews).
- `quality-standards`: Quality metrics and continuous improvement guidance.
- `api-contract-strategy`: Structured API contract authoring, compatibility, generated projections, workflow runners, provider/consumer boundaries, and incremental legacy adoption.
- `executable-oracle-architecture-selector`: Selects executable oracle strategy for architecture, plan readiness, agent-assisted implementation, and runtime feedback loops.
- `testing-strategy`: Maps selected executable oracles to owned suites, fixtures, CI/release lanes, and diagnosis boundaries.

### Security & Logging
- `security-guardrails`: Security implementation guardrails (credentials, TLS/CORS, input validation).
- `security-logging`: Security-focused logging and validation conventions (audit trails, tamper-evident).
- `logging-standards`: Structured logging standards and observability (format, levels, correlation).
- `error-patterns`: Error handling patterns and reliability conventions (circuit breaker, retry, cleanup).

### Infrastructure & Tools
- `infrastructure-triage`: Infrastructure, network, proxy, tunnel, container, GitOps, IaC, Secrets, Auth, and automation triage.
- `codex-session-recovery`: Audit and merge session JSONL across Codex homes without touching SQLite or other home state.
- `docker-multiarch-build`: Multi-arch Docker build patterns (buildx, multi-stage, amd64/arm64).
- `context7-registry`: Context7 skills registry CLI for discovering and installing external library docs.
- `web-fetch`: Web content fetching and processing (Jina Reader, Firecrawl fallback).

### Git & Commit Workflow
- `smart-commit`: Intent-gated Git workflow that may be model-selected only when the user explicitly asks to group current diffs by business domain or purpose and create focused local commits; it then executes eligible local commits automatically after exclusion checks.
- `smart-squash`: Cleanup unpushed commit history by analyzing and grouping commits by business logic.

## Docs

- Human-facing docs stay here in `README.md`.
- AI-facing rules and the repository docs truth boundary live in `AGENTS.md`.
- Docs directory search guidance and history notes live in `docs/README.md`.
- Stage artifacts live under `docs/plans/` and are excluded from default docs search by `docs/.ignore`.
- Architecture and maintenance contracts live under `docs/architecture/`.
- The canonical workflow maintenance view is `docs/architecture/workflow-orchestration.md`; its implementation DAG and repair-loop PlantUML sources are generated under `docs/architecture/diagrams/`.

## Review Defaults

Review is agent-native. The main coding agent prefers one reviewer subagent for non-trivial bounded work and may review a small mechanical change directly. Skills describe roles and evidence contracts without choosing a reviewer tool. A delegated reviewer cannot delegate recursively.

Default review depth:
- `review-design`: `boundary`, focused on architecture boundaries and downstream implementation surface
- `review-plan`: `boundary`, focused on executable DAG, dependencies, oracle, ownership, rollback, and readiness
- `review-implementation`: bounded to the approved task diff, task tests, declared oracles, touch set, and justified direct dependencies

Repair behavior:
- reviewers return candidate findings only
- the main agent accepts, rejects, defers, or escalates each material candidate
- only accepted findings with qualifying change causality and an approved-contract violation enter controller-owned repair
- implementation repair normally uses one initial bounded review and one focused verification review, with at most one additional same-slice repair attempt

## Design Principles

- Keep skills thin and operational: purpose, scope, deterministic steps, and a short checklist.
- Avoid long tutorial content inside skills; keep examples minimal.
- Prefer cross-skill references over duplication (for example, services skills reference `clean-architecture`).
- Prefer bounded readonly review context and narrow repair fences for plan-bound execution work.
- Keep decision discovery, work-package readiness, and bounded review inside the sovereign harness instead of restoring third-party workflow control.

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

Optional Codex local marketplace registration and plugin install:

```bash
./install-codex.sh
```

Local symlink exposure is also supported. Workstations can expose the generated `skills/` directory through paths such as `~/.agents/skills/coding` and use the same skills without installing the Codex plugin.

For deterministic lifecycle entry, a host-level `AGENTS.md` may keep only thin intent mappings such as approved-plan implementation -> `coding:implement-change` and implementation review -> `coding:review-implementation`. The installed `implement-change/references/workflow.toml` remains the runtime DAG authority; do not copy that graph into the host bootstrap.

Manual Codex flow:

```bash
codex plugin marketplace add "$(pwd)/.codex-marketplace"
codex plugin add coding@csheng
```

Codex manifest validation:

```bash
uvx --with pyyaml python "$HOME/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py" .
```
