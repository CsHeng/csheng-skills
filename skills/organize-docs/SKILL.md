---
name: organize-docs
description: "Maintain project documentation structure, stable truth roots, stage artifact boundaries, and audience separation without taking over read-only project explanation. Activates for: organize docs, maintain docs, truth boundary, docs layout, README.md, AGENTS.md, CLAUDE.md, docs/.ignore, 文档整理, 文档结构, 文档边界。"
---

# Organize Docs

Write or update long-lived project truth after explicit user request or explicit drift follow-up from `analyze-project`.

## Use This Skill When

- the user wants to reorganize or update `README.md`, `AGENTS.md`, `CLAUDE.md`, or stable docs
- the repository needs explicit stable truth roots and stage artifact roots
- default docs search needs a local search-boundary policy such as `docs/.ignore`
- drift follow-up from `analyze-project` points to stable doc maintenance

## Do Not Use This Skill When

- the user primarily wants a read-only project-state explanation
- `analyze-project` should be the default query path
- the task is just local git, worktree, or execution status

## Core Rules

- `README.md` stays human-facing.
- `AGENTS.md` stays AI-facing.
- `CLAUDE.md` remains a symlink to `AGENTS.md`.
- Stable truth roots and stage artifact roots must be explicit.
- Default docs search should avoid stage artifacts when the repository needs that search-boundary.
- Stage artifacts can support history, but they do not become default truth automatically.
- Prefer context-appropriate relative file paths and command examples over absolute paths in stable docs.
- For Git projects, when a repo root needs to be made explicit, prefer `cd "$(git rev-parse --show-toplevel)"` before relative commands.

## Workflow

1. Assess the current doc layout: `README.md`, `AGENTS.md`, `CLAUDE.md`, `docs/`, and local docs policy files.
2. Classify stable truth roots versus stage artifact roots using repository-local policy first.
3. Preserve or establish docs-local search-boundary files such as `docs/.ignore` when default search should exclude history.
4. Keep human-facing guidance in `README.md` and AI-operational rules in `AGENTS.md`.
5. Move or summarize content into stable docs domains without treating plans, drafts, or other stage artifacts as default truth.
6. Update stable docs only after explicit user approval or explicit drift follow-up from `analyze-project`.

## Validation

- for Git projects, prefer `cd "$(git rev-parse --show-toplevel)"` before `bash skills/organize-docs/scripts/check-doc-boundaries.sh` when docs truth boundaries are part of the change
