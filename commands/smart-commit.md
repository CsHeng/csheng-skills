---
description: Manually invoke smart-commit to analyze changes and automatically create focused local commits
argument-hint: "[--filter=<path>] [--repo-root=<path>]"
allowed-tools: ["Bash(pwd:*)", "Bash(git -C:*)", "Read", "Glob", "Grep"]
---

Invoke the `coding:smart-commit` skill to analyze current repository changes and automatically produce focused local commits grouped by business purpose. Do not invoke this command implicitly; it is a user-requested commit operation.

Before invoking the skill, resolve the target repository from the invocation working directory:

```bash
INVOCATION_CWD="$(pwd -P)"
TARGET_REPO="$(git -C "$INVOCATION_CWD" rev-parse --show-toplevel)"
```

If `$ARGUMENTS` contains `--repo-root=<path>`, resolve `TARGET_REPO` from that path instead. If the resolved repository conflicts with a user-stated path, stop before running Git history, diff, staging, or commit commands.

All Git commands in this workflow must use `git -C "$TARGET_REPO" ...`. Do not use the plugin repository as the implicit target just because this command file or the `coding:smart-commit` skill was loaded from there.

If `$ARGUMENTS` contains `--filter=<path>`, restrict analysis to files within that directory and its subdirectories.
