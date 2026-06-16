# Git Worktrees Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a first-party `git-worktrees` skill that supports agent-friendly create, compare, merge, and cleanup workflows with repository-local path rules.

**Architecture:** Keep the implementation text-only in one skill directory. Put broad trigger logic in `SKILL.md`, keep UI metadata in `agents/openai.yaml`, and encode stop conditions directly in the workflow sections so agents do not silently choose unsafe defaults.

**Tech Stack:** Markdown skill definition, generated OpenAI skill metadata, shell command examples, local validator script.

---

### Task 1: Create the skill skeleton

**Files:**
- Modify: `skills/git-worktrees/SKILL.md`
- Create: `skills/git-worktrees/agents/openai.yaml`

- [ ] **Step 1: Replace the generated placeholder frontmatter**

Write a `Use when ...` description that explicitly covers:
- isolated implementation work
- spec/design/plan execution
- compare
- merge
- cleanup
- English and Chinese trigger phrases

- [ ] **Step 2: Add the skill overview and core policy**

Document the decisions that must stay stable:
- repo-local instructions win
- default path is `./.agents/worktrees/<branch-slug>/`
- no silent fallback outside the repository
- stop if ignore coverage is missing

- [ ] **Step 3: Add lifecycle sections**

Write separate sections for:
- preflight
- context preservation
- path policy
- create/list
- compare
- merge
- cleanup/repair
- failure conditions

- [ ] **Step 4: Add realistic examples**

Add examples showing:
- create for a plan-driven task
- compare a file across worktrees
- merge one file from a worktree
- remove and prune a finished worktree

### Task 2: Encode the context-file guardrail

**Files:**
- Modify: `skills/git-worktrees/SKILL.md`

- [ ] **Step 1: Describe how to discover planning context**

Include command examples that find:
- `AGENTS.md`
- `README.md`
- design/spec/plan markdown files under common directories

- [ ] **Step 2: Describe the Git-status check**

Add a `git status --short -- <files...>` example and explain that modified, staged, or untracked context files must block worktree creation until the user confirms a transfer plan.

- [ ] **Step 3: Require explicit carry-over references**

State that the agent must mention the exact context files to reopen after entering the worktree.

### Task 3: Generate UI metadata

**Files:**
- Create: `skills/git-worktrees/agents/openai.yaml`

- [ ] **Step 1: Generate metadata from the finished skill**

Run:

```bash
python3 skills/.system/skill-creator/scripts/generate_openai_yaml.py skills/git-worktrees \
  --interface display_name="Git Worktrees" \
  --interface short_description="Agent-friendly git worktree workflows" \
  --interface default_prompt="Use this skill to create, compare, merge, and clean up git worktrees with repo-local paths and explicit spec or plan carry-over checks."
```

- [ ] **Step 2: Verify the generated metadata matches the skill**

Read `skills/git-worktrees/agents/openai.yaml` and confirm the display name, short description, and prompt align with the actual trigger scope.

### Task 4: Validate the skill

**Files:**
- Modify: `skills/git-worktrees/SKILL.md`
- Create: `skills/git-worktrees/agents/openai.yaml`

- [ ] **Step 1: Run the validator**

Run:

```bash
python3 skills/.system/skill-creator/scripts/quick_validate.py skills/git-worktrees
```

Expected: validation passes with no missing frontmatter or naming errors.

- [ ] **Step 2: Perform a manual quality pass**

Check that the skill:
- prefers `./.agents/worktrees/`
- never falls back to `~/.local` or `../...` by itself
- stops when ignore rules are missing
- stops when relevant planning files are uncommitted
- covers create, compare, merge, and cleanup

- [ ] **Step 3: Summarize verification status**

Record whether:
- `generate_openai_yaml.py` passed
- `quick_validate.py` passed
- manual scope check passed
