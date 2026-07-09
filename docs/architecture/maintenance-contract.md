# Maintenance Contract

This repository keeps reusable coding-agent behavior in a structured source tree and generates flat compatibility surfaces for agent runtimes that expect one skill directory per skill.

## Source And Generated Surfaces

- `src/skills/**/SKILL.md` is the source of truth for model-facing skill behavior.
- `contracts/skills.toml` is the source of truth for skill exposure, category, lifecycle ownership, invocation policy, mutation permission, and runtime-support exceptions.
- `skills/` is generated root-flat compatibility output. Do not edit it directly.
- `.dist/claude/` and `.dist/codex/` are generated target-specific flat skill surfaces.
- `skills.index.json` is generated from `contracts/skills.toml`.
- `skills/_harness-libs/` and `skills/_review-libs/` are generated root-flat runtime support for current command wrappers and plugin manifests; they are not user-routed workflow entries.

Regenerate generated surfaces with:

```bash
python3 scripts/generate-skills-index.py
python3 scripts/flatten-skills.py --target all
```

Validate with:

```bash
bash scripts/check.sh
```

## Skill Change Requirements

Any skill addition, deletion, rename, or category change must update:

- `contracts/skills.toml`
- regenerated `skills.index.json`
- generated install surfaces under `skills/` and `.dist/`
- README inventory or architecture docs when the visible capability changes
- at least one check or fixture when behavior changes
- `docs/changelog/design-decisions.md` when policy or architecture changes

## Lifecycle Authority

- Only `category = "workflow"` may set `lifecycle_owner = true`.
- Lower-plane skills may provide method, policy, checks, or tool support, but they must not approve, execute, or close lifecycle state.
- Mutation-capable skills must require an explicit user request or an approved upstream artifact.
- Manual tools such as `smart-commit`, `smart-squash`, and `git-worktrees` must never be implicitly invoked.
- `execute-change` treats an approved plan as one execution unit.

## Review Invariants

- Review is same-driver by design.
- The skills layer does not spawn, select, or arbitrate between different LLM providers.
- External review reports may be attached as passive evidence.
- Review must operate on explicit artifacts, diffs, or fresh evidence.
- Reviewer success reports are claims until normalized by local runner output or command evidence.
- Review budgets stay bounded by the harness defaults unless a maintainer deliberately overrides them.

## Safety And Evidence

- No unattended execution by default.
- Human approval gates remain authoritative.
- Fresh evidence is required for completion claims.
- Rollback surface must be explicit for regulated changes.
- Repo-owned docs, code, scripts, tests, and skills are durable truth.
- Memories, summaries, logs, sessions, and caches are not durable truth unless explicitly promoted.

## Environment-Specific Content

Generally installed skills may contain personal engineering style and opinionated local-first defaults, but must avoid host-specific paths, private project names, private token names, unguarded OS-specific commands, and required provider-specific model names.
