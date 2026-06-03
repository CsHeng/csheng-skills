---
name: skill-miner
description: "Mine Codex/Claude sessions and memory files for repeated failures, user corrections, workflow mistakes, and concrete skill improvement candidates."
---

# Skill Miner

Extract reusable skill improvements from agent history without mutating the target repository by default.

## Scope

Default scope is the current Git repository. If no Git root exists, use the current working directory. Use all-history scope only when the user explicitly asks to search all `~/.codex` and `~/.claude`.
When the user names additional agent homes, include those homes explicitly instead of assuming only the current host home.

Read these sources when available:
- Codex sessions: `~/.codex/sessions/**/*.jsonl`
- Codex memory: `~/.codex/memories/MEMORY.md`
- Claude sessions: `~/.claude/projects/**/*.jsonl`
- Claude memory: `~/.claude/projects/**/memory/*.md` and other `~/.claude/**/memory/*.md`
Additional homes use the same directory shapes under their own Codex or Claude home roots.

## Workflow

1. Confirm the requested scope: current repo, named repo, or all local Codex/Claude history.
2. Stay read-only unless the user explicitly approves skill edits.
3. Run the bundled parser for structured signals instead of raw-scanning large JSONL files.
4. Separate evidence into:
   - command failures and tool errors
   - interrupted, compacted, or rolled-back turns
   - user corrections and scope rejections
   - approval-gate mistakes
   - memory-recorded failure patterns
5. Classify each candidate as:
   - update an existing generic skill
   - add a new generic skill
   - add or update a repo-local skill
   - keep in memory only
   - do not promote
6. Recommend concrete target files and validation commands.

## Parser

Use:

```bash
python3 /absolute/path/to/skills/skill-miner/scripts/extract-session-signals.py --scope current --repo-root "$(git rev-parse --show-toplevel)"
```

For all local history:

```bash
python3 /absolute/path/to/skills/skill-miner/scripts/extract-session-signals.py --scope all
```

For multiple local homes, repeat the home options:

```bash
python3 /absolute/path/to/skills/skill-miner/scripts/extract-session-signals.py \
  --scope all \
  --codex-home ~/.codex \
  --codex-home ~/orbstack-docker/home/csheng/.codex \
  --claude-home ~/.claude \
  --claude-home ~/orbstack-docker/home/csheng/.claude
```

For machine-readable aggregation:

```bash
python3 /absolute/path/to/skills/skill-miner/scripts/extract-session-signals.py \
  --scope all \
  --format json \
  --limit 0
```

The script is read-only and accepts only named parameters.
`--codex-home` and `--claude-home` are repeatable; comma-separated values are also accepted.

## Output Rules

- Lead with counts and strongest repeated patterns.
- Quote short user corrections only when they prove a workflow mistake.
- Treat search no-match exit codes as weak evidence unless followed by user correction.
- Do not promote repo-local facts into generic skills.
- Do not claim a write, install, deploy, or commit happened unless the corresponding step completed.
- When the user requested analysis only, end with recommendations and do not edit files.

## Promotion Rules

Promote to a generic skill only when the pattern recurs across repositories or across task types. Promote to a repo-local skill when the pattern depends on repository topology, runtime inventory, local hostnames, or domain-specific operational truth. Keep as memory when the fact is useful but too specific or stale-prone for a skill.
