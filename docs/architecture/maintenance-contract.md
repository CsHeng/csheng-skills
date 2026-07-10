# Maintenance Contract

This repository keeps reusable coding-agent behavior in a structured source tree and generates flat compatibility surfaces for agent runtimes that expect one skill directory per skill.

## Source And Generated Surfaces

- `src/skills/**/SKILL.md` is the source of truth for model-facing skill behavior.
- `contracts/skills.toml` is the source of truth for skill exposure, category, lifecycle ownership, invocation policy, mutation permission, runtime-support exceptions, and pointers to install-required skill-local runtime contracts.
- `skills/` is tracked generated root-flat compatibility output. Do not edit it directly.
- `.dist/claude/` and `.dist/codex/` are ignored, reproducible target-specific flat skill surfaces generated only when needed.
- `skills.index.json` is generated from `contracts/skills.toml`.
- `docs/architecture/diagrams/*.puml` are generated human views of the installed implementation workflow contract.
- `skills/_harness-libs/` and `skills/_review-libs/` are generated root-flat runtime support for current command wrappers and plugin manifests; they are not user-routed workflow entries.

Regenerate generated surfaces with:

```bash
python3 scripts/generate-skills-index.py
python3 scripts/flatten-skills.py --target root-flat
python3 scripts/generate-workflow-diagrams.py
```

Validate with:

```bash
bash scripts/check.sh
```

## Skill Change Requirements

Any skill addition, deletion, rename, or category change must update:

- `contracts/skills.toml`
- regenerated `skills.index.json`
- regenerated tracked install surface under `skills/`
- README inventory or architecture docs when the visible capability changes
- at least one check or fixture when behavior changes
- `docs/changelog/design-decisions.md` when policy or architecture changes

Do not hand-edit generated PlantUML files. Update the controller-local workflow contract, regenerate the diagrams, and review the resulting architecture view. See `workflow-orchestration.md` for truth precedence and diagram scope.

`bash scripts/check.sh` generates Claude and Codex surfaces in a temporary directory and validates them there. Generate `.dist/` explicitly only for local packaging or external-consumer inspection; it must stay ignored and untracked.

## Lifecycle Authority

- Only `category = "workflow"` may set `lifecycle_owner = true`.
- Lower-plane skills may provide method, policy, checks, or tool support, but they must not approve, execute, or close lifecycle state.
- Mutation-capable skills must require an explicit user request or an approved upstream artifact.
- Manual tools such as `smart-commit`, `smart-squash`, and `git-worktrees` must never be implicitly invoked.
- `implement-change` treats an approved plan as one execution unit.
- `implement-change/references/workflow.toml` travels with the installed controller and owns its invocation subgraph; repo-global architecture docs are the maintenance view, not the only runtime copy.

## Review Invariants

- Review is same-driver by design.
- The skills layer does not spawn, select, or arbitrate between different LLM providers.
- External review reports may be attached as passive evidence.
- Review must operate on explicit artifacts, diffs, or fresh evidence.
- Reviewer success reports are claims until normalized by local runner output or command evidence.
- `review-implementation` is read-only and cannot invoke lifecycle workflows or mutate implementation.
- `implement-change` owns implementation repair with five expected rounds and a hard safety limit of ten; design/plan review budgets remain separately bounded.

## Safety And Evidence

- No unattended execution by default.
- Human approval gates remain authoritative.
- Fresh evidence is required for completion claims.
- Rollback surface must be explicit for regulated changes.
- Repo-owned docs, code, scripts, tests, and skills are durable truth.
- Memories, summaries, logs, sessions, and caches are not durable truth unless explicitly promoted.

## Environment-Specific Content

Generally installed skills may contain personal engineering style and opinionated local-first defaults, but must avoid host-specific paths, private project names, private token names, unguarded OS-specific commands, and required provider-specific model names.
