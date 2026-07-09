---
name: smart-commit
description: "Use only when explicitly invoked to analyze working tree changes and automatically create focused local commits grouped by business purpose, including staged and unstaged splits."
---

# Smart Commit

Analyze git repository changes, exclude files that should not be committed, group remaining changes by business purpose, and execute focused local commits automatically after the skill is explicitly invoked.

## Scope

This skill handles the full workflow from change analysis to commit execution. It does NOT push to any remote.

This skill is manually invoked. Once invoked, default to committing eligible changes without a confirmation gate. Stop for human confirmation only when Git is already tracking or staging a file that appears unsafe or inappropriate to commit.

## Target Repository Binding

Bind the target repository before any Git inspection or write. The target repository is the Git root for the user's invocation working directory or an explicit user-supplied repository path, not the repository that stores this skill.

```bash
INVOCATION_CWD="$(pwd -P)"
TARGET_REPO="$(git -C "$INVOCATION_CWD" rev-parse --show-toplevel)"
printf 'Target repository: %s\n' "$TARGET_REPO"
```

Rules:
- Run every Git command as `git -C "$TARGET_REPO" ...`.
- Never use the plugin repository as the implicit target repository just because this skill file is loaded from there.
- The plugin repository is a valid target only when the invocation working directory resolves to it or the user explicitly selects it.
- If the resolved `TARGET_REPO` conflicts with the user's stated path, stop before running `git log`, `git diff`, `git add`, or `git commit`.

## Workflow

### Phase 0: Recent Commit Detection (Optional)

Before analyzing working tree changes, optionally check for related recent commits:

```bash
# Check recent unpushed commits
if git -C "$TARGET_REPO" rev-parse @{u} >/dev/null 2>&1; then
  git -C "$TARGET_REPO" log @{u}..HEAD --oneline -5
else
  # No upstream: show recent 5 commits from HEAD
  git -C "$TARGET_REPO" log --oneline -5
fi

# Count total unpushed commits
if git -C "$TARGET_REPO" rev-parse @{u} >/dev/null 2>&1; then
  UNPUSHED_COUNT=$(git -C "$TARGET_REPO" log @{u}..HEAD --oneline | wc -l)
else
  # No upstream: cannot determine "unpushed" count, skip this check
  UNPUSHED_COUNT=0
fi
```

#### Detection Logic

Implementation approach: Heuristic-based file overlap detection (shell + git).

```bash
# Get files changed in working tree
WORKING_FILES=$(git -C "$TARGET_REPO" diff --name-only HEAD 2>/dev/null | sort || git -C "$TARGET_REPO" diff --name-only --cached | sort)

# Get files from recent 3 unpushed commits
if git -C "$TARGET_REPO" rev-parse @{u} >/dev/null 2>&1; then
  RECENT_COMMITS=$(git -C "$TARGET_REPO" log @{u}..HEAD --oneline -3 --format="%H")
else
  RECENT_COMMITS=$(git -C "$TARGET_REPO" log --oneline -3 --format="%H")
fi

# Skip detection if working tree is empty
if [ -n "$WORKING_FILES" ]; then
  # Check file overlap
  for commit in $RECENT_COMMITS; do
    commit_files=$(git -C "$TARGET_REPO" show --name-only --format="" "$commit" | sort)
    overlap=$(comm -12 <(echo "$WORKING_FILES") <(echo "$commit_files") | wc -l)
    total_working=$(echo "$WORKING_FILES" | wc -l)

    # If >50% overlap, consider related
    if [ $overlap -gt 0 ] && [ $((overlap * 2)) -ge $total_working ]; then
      echo "Related commit detected: $commit"
    fi
  done
fi
```

- Analyze working tree changes (files, business logic)
- Check if recent 3-5 unpushed commits touch same files/logic
- If high correlation is detected (>50% file overlap), report it as context but continue with a new focused commit unless the user explicitly asked to amend or squash.

#### Related Commit Output

If related commits are detected, report them without blocking automatic commit execution:

```
检测到最近的提交与当前变更相关：
  ce1a0ca feat(makefile): add get_current_ips function
  320dd25 feat(makefile): add mode-detector.sh skeleton

当前变更也涉及 Makefile 相关功能；默认创建新的独立提交。
```

If the user explicitly asked to amend:
```bash
git -C "$TARGET_REPO" add -- <files>
git -C "$TARGET_REPO" commit --amend --no-edit
```

If the user explicitly asked to squash or reorganize history, invoke smart-squash instead of continuing.

#### Large History Warning

If >10 unpushed commits are detected, warn but do not block automatic commit execution:

```
检测到 78 个未推送提交。

建议后续使用 smart-squash 整理历史；本次默认继续创建当前提交。
```

#### Implementation Constraints

- This detection is optional and does not block core smart-commit flow
- Only checks recent 3-5 commits for performance
- Uses `git -C "$TARGET_REPO" commit --amend` only when the user explicitly requested amend, not rebase
- Detection can be skipped with `--no-detect` flag (future enhancement)

### Phase 1: Collect and Exclude

Gather the full picture of repository changes:

```bash
git -C "$TARGET_REPO" rev-parse --git-dir          # validate repository
git -C "$TARGET_REPO" status --short               # all changes overview
git -C "$TARGET_REPO" diff --cached --name-status  # staged changes
git -C "$TARGET_REPO" diff --name-status           # unstaged changes
git -C "$TARGET_REPO" ls-files --others --exclude-standard  # untracked files
```

If `git status --short`, staged diff, unstaged diff, and untracked-file checks are all empty, stop with a no-op result. Do not run grouping heuristics or invent a commit plan for a clean worktree.

Read file contents when needed to assess whether a file should be excluded.

#### Exclusion Criteria

Evaluate each changed/untracked file against these categories:

| Category | Examples | Action |
|----------|----------|--------|
| Secrets & credentials | API keys, tokens, passwords, .env files, private keys | Exclude, warn user; stop if tracked or staged |
| Generated artifacts | build/, dist/, *.pyc, __pycache__, node_modules/ | Exclude |
| Large binaries | Images >1MB, compiled binaries, archives | Exclude, note reason |
| Temporary files | *.tmp, *.swp, *.log, .DS_Store | Exclude |
| IDE/editor config | .idea/, .vscode/settings.json (user-specific) | Exclude |
| Lock files with no source change | package-lock.json alone without package.json change | Exclude unless dependency intent is clear |

Apply judgment beyond these rules — analyze file content semantically when the filename alone is ambiguous. For example, a `.json` file could be configuration (commit) or generated output (exclude).

When uncertain, include the file only if it is a normal source, config, test, docs, or lockfile change. If uncertainty is about whether a tracked or staged file should be versioned at all, stop and ask for human confirmation before committing.

#### Human Confirmation Gate

Do not ask for confirmation for ordinary eligible changes. Stop and ask the user before any commit only when Git is already tracking or staging content that appears unsafe or inappropriate to version:

- A tracked or staged file appears to contain secrets, credentials, local machine state, generated output, temporary logs, personal IDE settings, or other content that should not be in Git.
- The safe path would require removing a tracked file from Git or changing `.gitignore` before committing.

Untracked excluded files do not require confirmation; leave them untracked and continue with eligible tracked/staged/untracked source files.

#### Exclusion Output

Present excluded files as a clear list:

```
Excluded files:
  ✗ .env.local          — contains credentials
  ✗ dist/bundle.js      — generated artifact
  ✗ debug.log           — temporary file
```

### Phase 2: Semantic Grouping

Analyze remaining files and group them by business purpose:

1. Read file diffs to understand what each change does
2. Identify logical units — changes that serve the same business goal belong together
3. Respect dependencies — if schema changes enable code changes, schema comes first
4. Keep commits atomic — each commit should be independently meaningful

Grouping signals to consider:
- Files modified together for the same feature or fix
- Shared module/package boundaries
- Configuration changes that accompany code changes
- Documentation updates paired with the code they describe
- Pure refactoring separated from behavioral changes
- Test additions grouped with the code they test

Generate a commit message for each group following conventional commits:
- Imperative mood subject line, max 50 characters
- Blank line after subject
- Optional body describing what and why
- Body lines wrapped at ~72 characters

### Phase 3: Present Plan and Execute Automatically

#### Present the Commit Plan

Display the full plan in a structured format:

```
━━━ Smart Commit Plan ━━━

Excluded (N files):
  ✗ file — reason
  ...

Commit 1/M: feat: add user authentication
  + src/auth/login.ts
  + src/auth/middleware.ts
  + tests/auth/login.test.ts

Commit 2/M: chore: update dependency configuration
  + package.json
  + package-lock.json

━━━━━━━━━━━━━━━━━━━━━━━━
```

#### Execute Commits

Execute each eligible commit group sequentially without waiting for a confirmation prompt:

```bash
# For each group:
git -C "$TARGET_REPO" add -- <file1> <file2> ...
git -C "$TARGET_REPO" commit -m "<message>"
```

Between commits, verify the previous commit succeeded before proceeding. If a commit fails, stop and report the error — do not continue with remaining commits.

If the user explicitly requested only some groups, stage and commit only the requested groups. Leave rejected or deferred groups uncommitted and visible in the working tree; do not silently absorb them into approved commits.

After all commits complete, run `git -C "$TARGET_REPO" log --oneline -<N>` to show the results.

## Constraints

- Never push — this skill only performs local add and commit operations
- Never force — no `--force`, `--no-verify`, or other safety bypasses
- Automatic execution after explicit invocation — present the plan, then commit eligible groups without a separate confirmation prompt
- Human confirmation required only for tracked or staged content that appears unsafe or inappropriate to commit
- Preserve working state — only commit files included in the plan; leave other changes untouched
- Partial user scope stays partial — rejected groups remain unstaged or restored to their previous staged state
- Respect .gitignore — never attempt to add files matched by .gitignore
- Recent commit detection — optional context that may suggest amending or squashing, but default execution still creates new commits
- Large history warning — suggests smart-squash when >10 unpushed commits exist, but does not block default execution

## Edge Cases

- No changes detected: Inform the user and suggest checking the target path
- All files excluded: Present exclusion list, explain why nothing remains to commit
- Single logical group: Create one commit — no need to force multiple groups
- Merge conflicts present: Stop and inform the user to resolve conflicts first
- Partial staging: If some files are already staged, incorporate them into the plan and note the pre-existing staging
