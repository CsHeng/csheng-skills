---
name: smart-squash
description: "This skill should be used when the user asks to \"squash commits\", \"cleanup history\", \"organize unpushed commits\", \"merge commits by business logic\", or wants to reorganize local commit history before pushing. 中文触发：压缩提交、清理历史、整理未推送提交、按业务逻辑合并提交。"
---

# Smart Squash

Analyze unpushed commits, group by business logic, and reorganize commit history through interactive rebase.

## Scope

This skill handles batch cleanup of unpushed commits. It does NOT push to any remote or handle already-pushed commits.

## Workflow

### Phase 1: Safety Checks

Validate repository state before any operations:

```bash
git rev-parse --git-dir          # validate repository
git status --short               # must be clean

# Check not in rebase/merge
GIT_DIR=$(git rev-parse --git-dir)
if [ -d "$GIT_DIR/rebase-merge" ] || [ -f "$GIT_DIR/MERGE_HEAD" ]; then
  echo "ERROR: Repository is in rebase or merge state"
  exit 1
fi
```

Determine commit range:
```bash
# If upstream exists: use @{u}..HEAD
if git rev-parse @{u} >/dev/null 2>&1; then
  RANGE="@{u}..HEAD"
  BASE_COMMIT=$(git merge-base @{u} HEAD)
else
  # No upstream: prompt user for range
  echo "No upstream branch detected. Select commit range:"
  echo "  1. Recent N commits (default: 10)"
  echo "  2. From specific commit/tag"
  echo "  3. All commits in current branch"
  read -r choice
  case $choice in
    1) read -p "Number of commits: " N; RANGE="HEAD~${N:-10}..HEAD"; BASE_COMMIT="HEAD~${N:-10}" ;;
    2) read -p "From commit/tag: " FROM; RANGE="$FROM..HEAD"; BASE_COMMIT="$FROM" ;;
    3) RANGE="--root"; BASE_COMMIT=$(git rev-list --max-parents=0 HEAD) ;;
  esac
fi
```

Check for branch conflicts:
```bash
git for-each-ref --format='%(refname:short)' refs/heads/ | while read branch; do
  if [ "$branch" != "$(git branch --show-current)" ]; then
    git log --oneline HEAD ^$branch 2>/dev/null
  fi
done
```

#### Risk Warnings

Present comprehensive safety information:

```
⚠️  安全检查结果：

✓ 工作区干净
✓ 不在 rebase/merge 过程中
✗ 发现其他分支引用了部分未推送提交：
    - feature/new-api: 引用了 3 个提交

⚠️  执行 squash 会改写历史，可能影响这些分支。

风险：
  - 其他本地分支需要 rebase
  - 如果有协作者拉取过这些提交，会造成历史分歧

是否继续？(y/N)
```

### Phase 2: Extract and Analyze Commits

```bash
# Get all commits in range
git log $RANGE --format="%H|%s|%b" --reverse > /tmp/commits.txt

# Capture original count for later reporting
ORIGINAL_COUNT=$(git log $RANGE --oneline | wc -l)

# For each commit, extract metadata and changes
git log $RANGE --format="%H" --reverse | while read commit; do
  echo "=== Commit: $commit ==="
  git show --name-status --format="%s%n%b" $commit
done > /tmp/commit-details.txt
```

#### Business Logic Grouping

**Implementation approach**: Use heuristic-based grouping (initial version) with optional Python enhancement (future).

**Grouping heuristics** (in priority order):
1. **Same scope**: Consecutive commits with same conventional commit scope (e.g., `feat(makefile):`)
2. **Same files**: Commits touching identical file sets
3. **Same prefix**: Same conventional commit type (feat/fix/refactor/docs) + overlapping files
4. **Manual review**: Present ambiguous cases to user for grouping decision

**Grouping algorithm** (shell implementation):
```bash
# Extract scope from each commit
git log $RANGE --format="%H|%s" --reverse | while IFS='|' read hash subject; do
  scope=$(echo "$subject" | sed -n 's/^[a-zA-Z]*(\([^)]*\)):.*/\1/p')
  prefix=$(echo "$subject" | sed -n 's/^\([a-zA-Z]*\).*/\1/p')
  files=$(git show --name-only --format="" $hash | tr '\n' ',' | sed 's/,$//')
  echo "$hash|$scope|$prefix|$files"
done > /tmp/commit-metadata.txt

# Phase 1: Group consecutive commits with same scope (original logic)
awk -F'|' 'BEGIN { group_id=0 }
{
  if ($2 != "" && $2 == prev_scope) {
    groups[group_id] = groups[group_id] "," $1
  } else {
    if (NR > 1) group_id++
    groups[group_id] = $1
    prev_scope = $2
  }
}
END {
  for (i=0; i<=group_id; i++) {
    if (groups[i] != "") print groups[i]
  }
}' /tmp/commit-metadata.txt > /tmp/groups-scope.txt

# Phase 2: File-based grouping for consecutive commits with identical file sets
# This catches commits that touch the same files but have different scopes
awk -F'|' 'BEGIN { group_id=0; in_group=0 }
{
  hash=$1; files=$4

  # Group by identical files (consecutive only, non-empty files)
  if (NR > 1 && files != "" && files == prev_files) {
    if (!in_group) {
      groups[group_id] = prev_hash "," hash
      in_group = 1
    } else {
      groups[group_id] = groups[group_id] "," hash
    }
  } else {
    if (in_group) {
      group_id++
      in_group = 0
    }
  }
  prev_files = files
  prev_hash = hash
}
END {
  for (i=0; i<=group_id; i++) {
    if (groups[i] != "") print groups[i]
  }
}' /tmp/commit-metadata.txt > /tmp/groups-files.txt

# Merge both grouping strategies: combine scope-based and file-based groups
# Mark all commits that are already in scope-based groups
cat /tmp/groups-scope.txt | tr ',' '\n' > /tmp/grouped-commits.txt

# Add file-based groups for commits not already grouped
while IFS= read -r group; do
  first_commit=$(echo "$group" | cut -d',' -f1)
  if ! grep -q "^$first_commit\$" /tmp/grouped-commits.txt 2>/dev/null; then
    echo "$group"
    echo "$group" | tr ',' '\n' >> /tmp/grouped-commits.txt
  fi
done < /tmp/groups-files.txt > /tmp/groups-files-new.txt

# Combine all groups
cat /tmp/groups-scope.txt /tmp/groups-files-new.txt > /tmp/groups.txt

# If no groups were created, fall back to individual commits
if [ ! -s /tmp/groups.txt ]; then
  awk -F'|' '{print $1}' /tmp/commit-metadata.txt > /tmp/groups.txt
fi
```

**Future enhancement**: Python script for semantic analysis using commit diffs and AST parsing.

Grouping strategy:
- Consecutive related commits merge first
- Non-consecutive related commits can merge (may need reordering)
- Preserve dependencies (schema before code)
- Keep independent commits separate

### Phase 3: Generate Rebase Plan

For each group, generate rebase instructions:

**Message generation strategy**:
1. **Single commit in group**: Keep original message
2. **Multiple commits in group**:
   - Use first commit's message as base
   - If all have same scope, keep scope: `feat(makefile): <combined description>`
   - Combine key actions from all messages (manual or semi-automated)
   - Example: `feat(makefile): implement mode auto-detection with IP extraction`

**Rebase instruction format**:
```bash
# For each group
while IFS=',' read -r commits; do
  first=true
  for commit in $(echo $commits | tr ',' ' '); do
    if $first; then
      # First commit: pick with unified message
      msg=$(git log --format=%s -n1 $commit)
      echo "pick $commit $msg"
      first=false
    else
      # Subsequent commits: fixup (discard messages)
      echo "fixup $commit"
    fi
  done
done < /tmp/groups.txt > /tmp/rebase-plan.txt
```

Example output:
```
# Group 1: Makefile mode detection feature
pick 5b89b8a feat(makefile): implement mode auto-detection with IP extraction
fixup ce1a0ca
fixup 320dd25

# Independent commits
pick 6ec2b3b chore(claude): auto-approve smart-commit skill
```

**Note**: Initial implementation uses first commit's message. Future enhancement: LLM-generated unified messages.

### Phase 4: Present Plan and Confirm

Display full plan with grouping details:

```
━━━ Smart Squash 计划 ━━━

分析范围: 78 个未推送提交
建议操作: 合并为 23 个提交

详细分组:

[Group 1] Makefile mode detection feature
  合并 3 个提交 → 1 个
  ├─ 5b89b8a feat(makefile): add extract_host function
  ├─ ce1a0ca feat(makefile): add get_current_ips function
  └─ 320dd25 feat(makefile): add mode-detector.sh skeleton

  新消息: feat(makefile): implement mode auto-detection with IP extraction

... (more groups)

保持独立 (15 个提交):
  - 6ec2b3b chore(claude): auto-approve smart-commit skill
  ... (14 more)

⚠️  注意事项:
  - 此操作会改写提交历史
  - 提交 SHA 会全部改变
  - 如果其他分支引用这些提交，需要 rebase

━━━━━━━━━━━━━━━━━━━━━━

操作选项:
  1. 执行计划
  2. 调整分组（进入交互模式）
  3. 查看详细 diff
  4. 取消

选择:
```

**Do not execute any git rebase command until the user explicitly confirms the plan.**

### Phase 5: Execute Squash

After confirmation, execute rebase:

```bash
# Execute rebase using the base commit determined in Phase 1
if [ "$RANGE" = "--root" ]; then
  GIT_SEQUENCE_EDITOR='sh -c "cp /tmp/rebase-plan.txt \"$1\"" --' git rebase -i --root
else
  GIT_SEQUENCE_EDITOR='sh -c "cp /tmp/rebase-plan.txt \"$1\"" --' git rebase -i $BASE_COMMIT
fi

# Handle conflicts
if [ $? -ne 0 ]; then
  echo "ERROR: Rebase 遇到冲突，请手动解决后执行："
  echo "  git rebase --continue  # 解决冲突后继续"
  echo "  git rebase --abort     # 放弃整个操作"
  exit 1
fi
```

After completion, show results:

```bash
# Show recent history with graph
FINAL_COUNT=$(git log @{u}..HEAD --oneline 2>/dev/null | wc -l || git log $BASE_COMMIT..HEAD --oneline | wc -l)
git log --oneline --graph -n $((FINAL_COUNT + 5))

echo "原始提交数: $ORIGINAL_COUNT"
echo "整理后提交数: $FINAL_COUNT"
```

## Constraints

- **Never push** — this skill only performs local rebase operations
- **Never force** — no `--force`, `--no-verify`, or other safety bypasses
- **User confirmation required** — always present the full plan before executing
- **Clean working tree required** — no uncommitted changes allowed
- **Support abort** — user can abort at any step

## Edge Cases

- **No upstream branch**: Prompt user for commit range (recent N, from commit/tag, or all)
- **No commits to squash**: Inform user that all commits are independent
- **Rebase conflicts**: Stop and provide clear recovery instructions
- **Other branches reference commits**: Warn user about potential impact
