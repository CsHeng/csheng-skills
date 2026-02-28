---
name: smart-commit
description: "This skill should be used when the user asks to \"smart commit\", \"split commits\", \"intelligent commit\", \"auto commit\", \"organize commits\", \"group changes\", or wants to analyze git changes and create multiple focused commits by business purpose. 中文触发：智能提交、拆分提交、按业务提交、自动分组提交、整理提交。"
---

# Smart Commit

Analyze git repository changes, exclude files that should not be committed, group remaining changes by business purpose, and execute multiple focused git commits after user confirmation.

## Scope

This skill handles the full workflow from change analysis to commit execution. It does NOT push to any remote.

## Workflow

### Phase 1: Collect and Exclude

Gather the full picture of repository changes:

```bash
git rev-parse --git-dir          # validate repository
git status --short               # all changes overview
git diff --cached --name-status  # staged changes
git diff --name-status           # unstaged changes
git ls-files --others --exclude-standard  # untracked files
```

Read file contents when needed to assess whether a file should be excluded.

#### Exclusion Criteria

Evaluate each changed/untracked file against these categories:

| Category | Examples | Action |
|----------|----------|--------|
| Secrets & credentials | API keys, tokens, passwords, .env files, private keys | Exclude, warn user |
| Generated artifacts | build/, dist/, *.pyc, __pycache__, node_modules/ | Exclude |
| Large binaries | Images >1MB, compiled binaries, archives | Exclude, note reason |
| Temporary files | *.tmp, *.swp, *.log, .DS_Store | Exclude |
| IDE/editor config | .idea/, .vscode/settings.json (user-specific) | Exclude |
| Lock files with no source change | package-lock.json alone without package.json change | Flag for review |

Apply judgment beyond these rules — analyze file content semantically when the filename alone is ambiguous. For example, a `.json` file could be configuration (commit) or generated output (exclude).

When uncertain, include the file in the plan but flag it with a note for user review.

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

1. **Read file diffs** to understand what each change does
2. **Identify logical units** — changes that serve the same business goal belong together
3. **Respect dependencies** — if schema changes enable code changes, schema comes first
4. **Keep commits atomic** — each commit should be independently meaningful

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

### Phase 3: Present Plan and Execute

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

#### Wait for User Confirmation

**Do not execute any git command until the user explicitly confirms the plan.** Present the plan and ask:

> 以上是提交计划，确认执行吗？（可以要求调整分组或排除项）

#### Execute Commits

After confirmation, execute each commit group sequentially:

```bash
# For each group:
git add <file1> <file2> ...
git commit -m "<message>"
```

Between commits, verify the previous commit succeeded before proceeding. If a commit fails, stop and report the error — do not continue with remaining commits.

After all commits complete, run `git log --oneline -<N>` to show the results.

## Constraints

- **Never push** — this skill only performs local add and commit operations
- **Never force** — no `--force`, `--no-verify`, or other safety bypasses
- **User confirmation required** — always present the full plan before executing
- **Preserve working state** — only commit files included in the plan; leave other changes untouched
- **Respect .gitignore** — never attempt to add files matched by .gitignore

## Edge Cases

- **No changes detected**: Inform the user and suggest checking the target path
- **All files excluded**: Present exclusion list, explain why nothing remains to commit
- **Single logical group**: Create one commit — no need to force multiple groups
- **Merge conflicts present**: Stop and inform the user to resolve conflicts first
- **Partial staging**: If some files are already staged, incorporate them into the plan and note the pre-existing staging
