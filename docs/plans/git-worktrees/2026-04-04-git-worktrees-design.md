# Git Worktrees Design

**Goal:** Add a first-party `git-worktrees` skill that gives this marketplace an agent-friendly, repository-local workflow for creating, comparing, merging, and cleaning up Git worktrees.

## Problem

Current worktree usage has two repeated failures:

1. Worktree placement is inconsistent, especially when a generic workflow asks whether to use project-local or global paths.
2. Design, spec, and implementation-plan files are sometimes missing from the new worktree because they were never committed or never re-opened explicitly.

Parent-directory worktrees are a reasonable Git default, but they are awkward for agent sandboxes that only grant repository-local access.

## Decisions

### Skill shape

- Create one skill: `skills/git-worktrees/SKILL.md`
- Cover the full lifecycle in one place:
  - create
  - list
  - compare
  - merge
  - cleanup and repair
- Keep the first version text-only; do not add scripts unless repeated manual steps prove brittle

### Trigger strategy

- Use a broad `Use when ...` frontmatter description
- Include both English and Chinese trigger phrases
- Target common agent prompts such as:
  - isolated implementation work
  - executing a spec, design, or implementation plan
  - comparing worktrees
  - merging from a worktree
  - cleaning up worktrees

### Default path policy

- Respect repository-local instructions first
- If the repository has no explicit preference, default to:

```text
./.agents/worktrees/<branch-slug>/
```

- Do not silently fall back to parent directories or home-directory storage
- If `.agents/worktrees` is not ignored correctly, stop and ask the user how to proceed

### Ignore policy

The skill must verify both:

- Git ignore coverage via `git check-ignore -q .agents/worktrees`
- Search-ignore coverage via `.ignore`, `.rgignore`, or `.fdignore` when present

If search-ignore coverage is missing or ambiguous, the skill stops and asks for confirmation instead of guessing.

### Context preservation

Before creating a worktree for spec, design, or implementation work, the skill must:

1. Find likely context files such as `AGENTS.md`, `README.md`, and matching design/spec/plan markdown files
2. Inspect their Git status
3. Stop if relevant context files are modified, staged, or untracked
4. Explicitly list the context files that should be re-opened inside the new worktree

This addresses the common failure mode where a new worktree is created successfully but the planning documents are not actually available there.

### Relative path handling

- Prefer per-command `git worktree add --relative-paths`
- Use `git worktree repair --relative-paths` for repair
- Do not silently set `git config worktree.useRelativePaths`

This keeps behavior explicit and avoids repository-wide config changes that could surprise users.

## Non-Goals

- No automatic fallback to `~/.local` or `~/.config`
- No global worktree registry
- No automatic dependency installation
- No automatic commit or push behavior
- No attempt to replace more general Git skills outside the worktree domain

## Files

- Create `skills/git-worktrees/SKILL.md`
- Create `skills/git-worktrees/agents/openai.yaml`
- Create this design document
- Create a matching implementation plan document

## Validation

- Generate `agents/openai.yaml` from the skill metadata
- Run the skill quick validator
- Review the final `SKILL.md` for:
  - clear trigger coverage
  - default repo-local path policy
  - explicit stop conditions
  - full lifecycle coverage
