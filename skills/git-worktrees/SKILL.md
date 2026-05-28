---
name: git-worktrees
description: "Use for git worktree workflows: create, compare, merge back, clean up, repair worktrees, or isolate feature branches."
---

# Git Worktrees

Create and manage agent-friendly git worktrees without scattering directories or losing spec and plan context.

## Core Policy

- Follow repository-local instructions first. If the repo already defines a worktree location or workflow, use it.
- If the repo has no explicit preference, default to `./.agents/worktrees/<branch-slug>/`.
- Never silently fall back to a parent directory or a home-directory location.
- Before creating a repo-local worktree, verify the directory is ignored by both Git and search tooling.
- If ignore coverage is missing, ambiguous, or inconsistent, stop and ask the user to confirm how to proceed.

## Preflight

Run these checks before creating, comparing, merging, or cleaning up worktrees:

```bash
git rev-parse --show-toplevel
git worktree list --porcelain
git status --short
```

Translate the user request into one of these modes:

| Mode | Use When |
|------|----------|
| **Create/List** | Starting isolated implementation work or inspecting existing worktrees |
| **Compare** | Reviewing differences between current worktree, another worktree, or a branch |
| **Merge** | Pulling selected changes from a worktree or branch into the current branch |
| **Cleanup** | Removing finished worktrees, pruning stale metadata, or repairing links |

If the request is ambiguous, ask one precise question before proceeding.

## Context Preservation for Spec and Plan Work

Before creating a worktree for design, spec, or implementation work, explicitly gather the files that define the task context:

```bash
fd -a AGENTS.md .
fd -a README.md .
fd -a '.*(design|spec|plan).*\.md$' docs specs .agents . 2>/dev/null
```

Then inspect their status:

```bash
git status --short -- <relevant-context-files...>
```

Apply these rules:

- If relevant design, spec, or plan files are committed on the starting branch, creating the worktree is safe.
- If relevant files are modified, staged, or untracked, stop and explain that the new worktree will not automatically include those changes.
- When stopping for this reason, list the exact context files and tell the user they need to commit them first or explicitly choose another transfer method.
- When proceeding, explicitly mention the context files that must be reviewed again inside the worktree session.

Do not assume the new worktree inherits uncommitted planning files.

## Path Policy

When the repository does not define its own location, use this default path:

```text
./.agents/worktrees/<branch-slug>/
```

Before creating the worktree:

```bash
git check-ignore -q .agents/worktrees
```

Then verify search-ignore coverage:

```bash
if [ -f .ignore ]; then
  rg -n '^\./?\.agents/worktrees/?$|^\.agents/worktrees/?$' .ignore
elif [ -f .rgignore ]; then
  rg -n '^\./?\.agents/worktrees/?$|^\.agents/worktrees/?$' .rgignore
elif [ -f .fdignore ]; then
  rg -n '^\./?\.agents/worktrees/?$|^\.agents/worktrees/?$' .fdignore
else
  echo "No search ignore file found"
fi
```

Rules:

- `git check-ignore` must succeed for `.agents/worktrees`.
- If the repository uses `.ignore`, `.rgignore`, or `.fdignore`, the chosen file should also ignore `.agents/worktrees`.
- If there is no search-ignore file at all, ask the user whether to add one or accept search noise.
- Do not create nested worktrees elsewhere inside the repository unless the repository explicitly opted in.

## Create or List Worktrees

### List

Use:

```bash
git worktree list --porcelain
```

Present a concise summary with:

- worktree path
- checked-out branch or detached commit
- whether the path is under `./.agents/worktrees/`

### Create

1. Derive the target branch name from the user request.
2. Normalize the path slug from the branch name.
3. Resolve the branch source:
   - existing local branch
   - remote tracking branch
   - new branch from an explicit base
4. Refuse to create if the target path already exists and is not already a valid worktree.
5. Use plain `git worktree add` by default unless the repository explicitly requires another mode.

Common command patterns:

```bash
# Existing local branch
git worktree add ./.agents/worktrees/<slug> <branch>

# Existing remote branch
git worktree add --track -b <branch> ./.agents/worktrees/<slug> origin/<branch>

# New branch from explicit base
git worktree add -b <branch> ./.agents/worktrees/<slug> <base>
```

After creation:

```bash
git -C ./.agents/worktrees/<slug> status --short
```

If the user is about to execute work immediately, mention the exact `cd` path and the context files that should be opened first.

## Compare Worktrees or Branches

Pick the smallest useful comparison:

| Need | Preferred Command |
|------|-------------------|
| **Branch summary** | `git diff --stat <branch-a>..<branch-b> -- <paths...>` |
| **Single file across worktrees** | `diff -u <worktree-a>/<path> <worktree-b>/<path>` |
| **Directory overview** | `diff -rq <worktree-a>/<dir> <worktree-b>/<dir>` |
| **Current worktree vs branch** | `git diff <branch> -- <paths...>` |

Guidelines:

- If only one other worktree exists, compare against it by default and say so.
- If multiple worktrees exist and the source is unclear, ask which one to compare against.
- Prefer `--stat` or directory summary before showing a large diff.
- For binary files or generated output, summarize the difference instead of dumping noise.

## Merge from a Worktree

Start only from a clean or intentionally staged working tree:

```bash
git status --short
```

Choose the narrowest merge strategy that fits the request:

| Strategy | Use When | Command |
|----------|----------|---------|
| **Whole file restore** | Take the full file from another branch | `git restore --source=<branch> -- <path>` |
| **Interactive patch** | Take only selected hunks | `git restore -p --source=<branch> -- <path>` |
| **Selective cherry-pick** | Take one commit with review before commit | `git cherry-pick --no-commit <commit>` |
| **Controlled branch merge** | Merge the branch but keep commit control | `git merge --no-commit <branch>` |

Merge workflow:

1. Identify the source worktree or branch.
2. Recommend a comparison first if the requested change is not fully specified.
3. Execute the narrowest strategy.
4. Review the result with `git status --short` and, when useful, `git diff --cached`.
5. Commit only after the user is satisfied with the selected changes.

Do not default to a full branch merge when the user asked for selected files or partial changes.

## Cleanup and Repair

Preferred commands:

```bash
# Remove a clean worktree
git worktree remove ./.agents/worktrees/<slug>

# Remove even with uncommitted changes
git worktree remove --force ./.agents/worktrees/<slug>

# Clean stale metadata
git worktree prune

# Repair moved or broken worktree links
git worktree repair
```

Rules:

- Never delete a worktree with `rm -rf`.
- Use `prune` after accidental manual deletion or stale metadata warnings.
- Use `git worktree repair` after moving repository-local worktrees or when links become inconsistent.
- If the worktree still contains active work, confirm before removal.

## Failure Conditions

Stop and ask the user to confirm when any of these are true:

- the repository already declares a different worktree location
- `.agents/worktrees` is not ignored by Git
- search-ignore coverage is missing or ambiguous
- relevant design, spec, or plan files exist but are not committed
- the requested branch, base, or source worktree cannot be resolved uniquely
- the target path already exists but is not a valid worktree

## Examples

### Create an implementation worktree

```text
Use git-worktrees to create an isolated worktree for implementing docs/superpowers/plans/2026-04-04-git-worktrees.md on branch feat/git-worktrees.
```

Expected behavior:

- inspect worktree list and current status
- verify `.agents/worktrees` ignore coverage
- verify the plan file is committed or stop if it is not
- create `./.agents/worktrees/feat-git-worktrees/`
- report the exact path plus the context files to reopen there

### Compare a current branch with a worktree

```text
Use git-worktrees to compare the current branch with ./.agents/worktrees/feat-git-worktrees for skills/git-worktrees/SKILL.md.
```

### Merge one file from a worktree

```text
Use git-worktrees to merge only skills/git-worktrees/SKILL.md from ./.agents/worktrees/feat-git-worktrees back into the current branch.
```

### Clean up a finished worktree

```text
Use git-worktrees to remove ./.agents/worktrees/feat-git-worktrees and prune stale metadata.
```
