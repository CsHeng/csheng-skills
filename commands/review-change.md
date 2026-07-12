---
description: Run bounded agent-native review with preferred subagent delegation and main-agent finding adjudication
argument-hint: "[--design <path> | --plan <path>] [--file <path> ...]"
allowed-tools: ["Agent", "Read", "Glob", "Grep", "Bash"]
---

Use `coding:review-change` as the top-level review gate.

Parse one review target from `$ARGUMENTS`:

- `--design <path>` for design review
- `--plan <path>` for plan review or an implementation baseline
- repeatable `--file <path>` for implementation review
- when no explicit file is supplied for implementation review, use the current changed-file diff

Validate design and plan artifacts with their deterministic harness validators before semantic review. Stop when the target is missing or invalid.

Construct a bounded review brief containing:

- `actor_role: main`
- current artifact class and task-slice objective
- approved goals, non-goals, and acceptance criteria
- exact artifact diff or changed files
- executable oracles and verification evidence
- approved touch set
- explicitly allowed supporting files with one reason each

For a non-trivial review, prefer one reviewer subagent through the Agent tool and give it only the bounded brief. For a small mechanical review or when delegation is unavailable, review directly. A delegated reviewer uses `actor_role: delegated`, must not delegate recursively, and returns candidate findings only.

Route design, plan, or implementation semantics through the matching review skill. Then have the main agent adjudicate every material candidate with one of:

- `accepted`
- `rejected_no_causal_link`
- `rejected_pre_existing`
- `rejected_out_of_scope`
- `rejected_insufficient_evidence`
- `deferred_followup`
- `needs_plan_change`

Only `accepted` findings may produce `needs-fixes`. Return one machine-checkable gate verdict: `pass`, `needs-fixes`, `manual-decision-required`, `split-scope`, `needs-design-decision`, or `needs-plan-change`. Do not ask whether to continue when the verdict determines the next state.
