---
name: organize-docs
description: "Use for docs organization: README/AGENTS/CLAUDE split, stable truth roots, docs layout, docs/.ignore, stage artifacts, canonical terminology, and search boundaries."
---

# Organize Docs

Write or update long-lived project truth after explicit user request or explicit drift follow-up from `analyze-project`.

## Use This Skill When

- the user wants to reorganize or update `README.md`, `AGENTS.md`, `CLAUDE.md`, or stable docs
- the repository needs explicit stable truth roots and stage artifact roots
- default docs search needs a local search-boundary policy such as `docs/.ignore`
- stable docs, paths, tests, or code need canonical terminology alignment
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
- Canonical terminology must be defined in stable docs when a repository has competing names for the same concept.
- Use `archived` for intentionally retained historical or reference material.
- Use `compat` for compatibility surfaces that target an older, alternate, or constrained version.
- When terminology changes, update docs, paths, tests, and code references together instead of appending corrective notes that leave old terms active.
- Prefer context-appropriate relative file paths and command examples over absolute paths in stable docs.
- For Git projects, when a repo root needs to be made explicit, prefer `cd "$(git rev-parse --show-toplevel)"` before relative commands.

## Workflow

1. Assess the current doc layout: `README.md`, `AGENTS.md`, `CLAUDE.md`, `docs/`, and local docs policy files.
2. Classify stable truth roots versus stage artifact roots using repository-local policy first.
3. Preserve or establish docs-local search-boundary files such as `docs/.ignore` when default search should exclude history.
4. Keep human-facing guidance in `README.md` and AI-operational rules in `AGENTS.md`.
5. Align canonical terminology across stable docs, path names, test names, and code references when the task is terminology cleanup.
6. Move or summarize content into stable docs domains without treating plans, drafts, or other stage artifacts as default truth.
7. Update stable docs only after explicit user approval or explicit drift follow-up from `analyze-project`.

## Validation

- When docs truth boundaries are part of the change, resolve the checker from this skill directory before switching to the target repository:

```bash
ORGANIZE_DOCS_SKILL_ROOT="/absolute/path/to/organize-docs"
CHECK_DOC_BOUNDARIES="$(realpath "$ORGANIZE_DOCS_SKILL_ROOT/scripts/check-doc-boundaries.sh")"
cd "$(git rev-parse --show-toplevel)"
bash "$CHECK_DOC_BOUNDARIES"
```

`ORGANIZE_DOCS_SKILL_ROOT` is the directory that contains this `SKILL.md`. Do not use a target-repository relative path for bundled skill scripts; target repositories do not own them.
