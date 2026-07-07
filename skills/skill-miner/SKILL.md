---
name: skill-miner
description: "Mine Codex/Claude sessions, memory files, and project context docs for repeated failures, workflow patterns, strategic blind spots, concrete skill improvement candidates, and memory cleanup after durable repo truth extraction."
---

# Skill Miner

Extract reusable skill improvements from agent history and project context without mutating the target repository by default.

Agent memory files are staging evidence, not long-term truth. Prefer extracting durable knowledge into repo code, repo docs, repo-local skills, or generic skills. After extraction, classify the corresponding memory entries as cleanup candidates instead of preserving them as the final source of truth.

## Scope

Default scope is the current Git repository. If no Git root exists, use the current working directory. Use all-history scope only when the user explicitly asks to search all `~/.codex` and `~/.claude`.
When the user names additional agent homes, include those homes explicitly instead of assuming only the current host home.

Read these sources when available:
- Codex sessions: `~/.codex/sessions/**/*.jsonl`
- Codex memory: `~/.codex/memories/MEMORY.md`
- Claude sessions: `~/.claude/projects/**/*.jsonl`
- Claude memory: `~/.claude/projects/**/memory/*.md` and other `~/.claude/**/memory/*.md`
- Project context docs: tracked `AGENTS.md`, `CLAUDE.md`, and `README.md` files under the target repo

Additional homes use the same directory shapes under their own Codex or Claude home roots.

Do not decide what future agents should write into memory. Mine existing memory only to identify missing repo truth, missing skills, stale memory, and cleanup candidates.

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
   - project docs that are large, duplicated, or workflow-heavy enough to mine
5. Classify each candidate as:
   - update an existing generic skill
   - add a new generic skill
   - add or update a repo-local skill
   - add or update scoped repo docs or code truth
   - mark extracted memory for cleanup
   - do not promote
6. For memory-derived findings, decide whether the target repo already owns the durable truth. If yes, recommend removing or shrinking the memory entry after the repo update is verified.
7. Recommend concrete target files and validation commands.

## Automatic Analysis Frames

Infer the right frame from the user's wording. Do not require the user to choose a mode when they directly invoke this skill.

When the user asks to scan all history or memory for hidden leverage, blind spots, repeated work, or high-value skill candidates:

1. Use all-history scope if explicitly requested; otherwise stay scoped to the current or named repo.
2. Lead with source counts and the strongest repeated patterns.
3. Identify one decision-level blind spot only when the evidence supports a structural pattern that would change future planning, verification, delegation, or stopping criteria.
4. Rank skill candidates by repeatability, leverage, blast-radius reduction, and fit with existing skill surfaces. Do not rank by raw keyword frequency alone.
5. For each candidate, state the durable owner:
   - existing generic skill update
   - new generic skill
   - repo-local skill
   - repo docs/code truth
   - memory cleanup only
   - do not promote
6. Prefer strengthening an existing skill when the candidate mostly sharpens an owned boundary. Create a new skill only when the workflow has a distinct trigger, owner, and verification path.

For blind-spot reports, separate:

- `Fact`: counts, repeated user corrections, repeated failures, and memory-recorded patterns.
- `Inference`: the likely operating pattern or missing contract.
- `Decision impact`: what the user should decide differently next time.
- `Skill action`: whether the fix is a generic skill, repo-local skill, repo docs/code truth, or no promotion.

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
  --codex-home ~/orbstack-docker/home/$USER/.codex \
  --claude-home ~/.claude \
  --claude-home ~/orbstack-docker/home/$USER/.claude
```

For machine-readable aggregation:

```bash
python3 /absolute/path/to/skills/skill-miner/scripts/extract-session-signals.py \
  --scope all \
  --format json \
  --limit 0
```

For measuring whether an external skill bundle actually influenced sessions before retiring it:

```bash
python3 /absolute/path/to/skills/skill-miner/scripts/extract-session-signals.py \
  --scope all \
  --skill-usage-only \
  --skill-usage-root /path/to/external-skill-bundle \
  --skill-usage-prefix external-skill-prefix \
  --skill-usage-before-date YYYY-MM-DD
```

The script is read-only and accepts only named parameters.
`--codex-home` and `--claude-home` are repeatable; comma-separated values are also accepted.
Skill usage reports count explicit user mentions, assistant references, and tool calls that name the requested prefix or read files under the requested skill root. They ignore injected long prompt, instruction, and skill inventory blocks so available-skill metadata does not masquerade as usage.
Use `--skill-usage-include-output` only when tool output itself is the evidence being mined; it is off by default because directory listings and inventory dumps can inflate usage counts.

## Output Rules

- Lead with counts and strongest repeated patterns.
- When the user asks for hidden leverage or "what I missed", give a decision-level blind spot before local optimizations.
- Include project context signals by default when a repo root is available.
- Quote short user corrections only when they prove a workflow mistake.
- Treat search no-match exit codes as weak evidence unless followed by user correction.
- Do not promote repo-local facts into generic skills.
- Do not leave durable recommendations as `keep in memory only` when repo docs, repo-local skills, repo code, or generic skills can own them.
- For memory-derived findings, name both the durable target file and the source memory cleanup action.
- Do not claim a write, install, deploy, or commit happened unless the corresponding step completed.
- When the user requested analysis only, end with recommendations and do not edit files.

## Promotion Rules

Promote to a generic skill only when the pattern recurs across repositories or across task types. Promote to a repo-local skill when the pattern depends on repository topology, runtime inventory, local hostnames, or domain-specific operational truth. Promote stable operational facts to scoped repo docs or code-owned truth. Do not promote one-time runtime snapshots; use them only as evidence, and do not preserve them as durable memory unless no repo or skill surface can own them.

## Memory Cleanup

When memory entries have been extracted into durable repo truth:

- list the extracted memory entries or task groups as cleanup candidates
- cite the target repo files that now own the truth
- preserve only short pointers when useful for historical lookup
- never edit agent memory files directly unless the user explicitly requests memory maintenance through the active memory workflow

The preferred end state is repo-owned truth plus lean agent memory, not agent-specific memory as a parallel documentation system.
