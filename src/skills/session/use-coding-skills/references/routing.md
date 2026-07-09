# Routing Reference

Use skills as the durable, agent-agnostic behavior surface. Keep AGENTS files as bootstrap indexes and local constraints, not long-form prompt packs.

## Primary Routes

- `analyze-project`: read-only project state, terminology, truth map, search boundaries, and drift signals.
- `design-change`: classify change scope, truth impact, boundary impact, and design depth before planning.
- `plan-change`: produce ordered implementation tasks with dependencies, verification, and rollback triggers.
- `execute-change`: execute an approved plan as one unit with verification and review gates.
- `review-change`: normalize design, plan, or code review into one verdict.
- `sync-truth`: update stable truth after verified behavior changes.
- `close-change`: decide merge, release, cleanup, rollback, or close status.

## Support Routes

- `output-styles`: response shape, terse mode, explanatory mode, review format, and closeout format.
- `tool-decision-tree`: tool choice, target preflight, search COUNT/PREVIEW/EXECUTE, structured history search, and output control.
- `infrastructure-triage`: network, proxy, tunnel, container, GitOps, IaC, Secrets, Auth, and runtime boundary diagnosis.
- `organize-docs`: README/AGENTS/CLAUDE split, stable truth roots, stage artifacts, and docs search boundaries.
- `skill-miner`: history and memory mining for reusable skill improvements and memory cleanup candidates.

## External Skill Libraries

Keep third-party workflow libraries below the local harness plane by default. Before exposing them in the default discovery surface, measure actual usage with `skill-miner`, absorb durable behavior into repo-owned skills or references, and expose only curated user-invoked entries when they do not compete with local routing, approval gates, artifact ownership, or closeout rules. For description and invocation-surface tuning, read `skills/development-standards/references/skill-authoring.md` from the repository root.

Prefer a more specific skill when one applies. Use this wrapper only to bootstrap or route.
