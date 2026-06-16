---
name: organize-docs
description: "Use for docs organization: README/AGENTS/CLAUDE split, stable truth roots, docs layout, docs/.ignore, stage artifacts, canonical terminology, search boundaries, and Markdown prose wrapping."
---

# Organize Docs

Write or update long-lived project truth after explicit user request or explicit drift follow-up from `analyze-project`.

## Use This Skill When

- the user wants to reorganize or update `README.md`, `AGENTS.md`, `CLAUDE.md`, or stable docs
- the repository needs explicit stable truth roots and stage artifact roots
- default docs search needs a local search-boundary policy such as `docs/.ignore`
- scattered plan, draft, or execution-note roots should be consolidated into one stage-artifact tree
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
- Plan artifact consolidation is optional. Do it only when the user explicitly asks, or when repository-local search-boundary drift makes scattered plan roots part of the requested docs cleanup.
- When consolidating plan artifacts, organize final paths by durable domain rather than source harness, and use date-first names such as `YYYY-MM-DD-topic-kind.md`.
- After moving plan artifacts, update stable-doc references and in-file path references to the new paths. Preserve historical content unless a path reference is objectively stale because of the move.
- Canonical terminology must be defined in stable docs when a repository has competing names for the same concept.
- Use `archived` for intentionally retained historical or reference material.
- Use `compat` for compatibility surfaces that target an older, alternate, or constrained version.
- When terminology changes, update docs, paths, tests, and code references together instead of appending corrective notes that leave old terms active.
- Prefer context-appropriate relative file paths and command examples over absolute paths in stable docs.
- For Git projects, when a repo root needs to be made explicit, prefer `cd "$(git rev-parse --show-toplevel)"` before relative commands.
- Do not hard-wrap Markdown prose to a fixed column. Keep each natural paragraph or list item on one physical line unless Markdown syntax, tables, code blocks, frontmatter, or intentional hard breaks require separate lines.

## Workflow

1. Assess the current doc layout: `README.md`, `AGENTS.md`, `CLAUDE.md`, `docs/`, and local docs policy files.
2. Classify stable truth roots versus stage artifact roots using repository-local policy first.
3. Preserve or establish docs-local search-boundary files such as `docs/.ignore` when default search should exclude history.
4. Keep human-facing guidance in `README.md` and AI-operational rules in `AGENTS.md`.
5. Align canonical terminology across stable docs, path names, test names, and code references when the task is terminology cleanup.
6. Move or summarize content into stable docs domains without treating plans, drafts, or other stage artifacts as default truth.
7. When explicitly consolidating plan artifacts, inventory all source plan roots, choose domain-based target directories under the canonical stage root, move files with date-first names, and update references after the move.
8. Normalize Markdown prose wrapping when touching docs: unwrap fixed-width paragraphs and list-item continuations across stable, stage, and archived docs that are in the requested scope.
9. Update stable docs only after explicit user approval or explicit drift follow-up from `analyze-project`.

## Validation

- When docs truth boundaries are part of the change, resolve the checker from this skill directory before switching to the target repository:

```bash
ORGANIZE_DOCS_SKILL_ROOT="/absolute/path/to/organize-docs"
CHECK_DOC_BOUNDARIES="$(realpath "$ORGANIZE_DOCS_SKILL_ROOT/scripts/check-doc-boundaries.sh")"
cd "$(git rev-parse --show-toplevel)"
bash "$CHECK_DOC_BOUNDARIES"
```

`ORGANIZE_DOCS_SKILL_ROOT` is the directory that contains this `SKILL.md`. Do not use a target-repository relative path for bundled skill scripts; target repositories do not own them.

The checker also rejects fixed-width hard-wrapped Markdown prose in Git-tracked `.md` files. It intentionally skips symlink files, fenced code blocks, frontmatter, Markdown tables, headings, reference definitions, HTML-only lines, thematic breaks, and indented code blocks.
