---
name: analyze-project
description: "Use for repository-level read-only truth mapping: explain project purpose, current state, documented architecture or search boundaries, terminology, operations, gaps, unfinished work, or doc drift. Own the response for broad project orientation or explicit truth audits; for runtime incidents or domain diagnosis, supply project-truth evidence to the matching primary skill instead. Do not use for implementation or code review."
---

# Analyze Project

Read stable project truth before answering recurring project-state questions.

## Use This Skill When

- the user asks what the project does
- the user asks what is implemented, in progress, or still missing
- the user asks where architecture or concept boundaries live
- the user asks how terminology, ignored files, hidden files, or search boundaries are organized
- the user asks how to operate, use, or validate the project
- the user needs a current-state explanation before deciding whether docs should be updated by `organize-docs`

## Do Not Use This Skill When

- the user wants to reorganize or update docs directly
- the user is asking for a design, plan, or code review workflow
- the user only wants local git or worktree status
- the main task is a runtime incident or domain diagnosis; use the matching domain skill as response owner and this skill only as a truth-evidence overlay

## Workflow

1. Determine the `project` scope before reading deeply.
2. Load repository policy for the selected `project` scope by reading the most specific project-scoped `docs/AGENTS.md`, `AGENTS.md`, `docs/README.md`, and `README.md` first, then fall back outward as needed, along with local ignore files.
3. Separate stable truth roots from stage artifact roots before searching.
4. Inventory project-local terminology and default search boundaries before drawing conclusions.
5. Judge document health as `healthy`, `degraded`, or `untrusted`.
6. Pick one basis for the run: `documentation-led`, `mixed verification`, or `code reconstruction`.
7. Read stable truth first, then do targeted read-only verification from code, commands, tests, or repository structure.
8. Select the rendering depth from `references/output-contract.md`: use selective terse output by default and full-audit output only for an explicit comprehensive truth-mapping request.
9. Emit drift signals and `recommended_action` values from `references/doc-health-and-drift.md` only when stable truth is weak, conflicting, incomplete, or stale.
10. Stop after reporting. Use only the current `recommended_action` values `run-organize-docs`, `ask-human`, or `search-stage-artifacts-explicitly` instead of mutating docs directly.

## Operating Rules

- Use `project`, not `workspace`, as the analysis unit.
- Keep stable truth separate from stage artifacts during default search.
- Treat terminology as repository-local unless a scoped stable doc defines a wider convention.
- Report default search boundaries from local ignore files before deciding that ignored or hidden material is absent.
- Use stage artifacts only when the user explicitly asks for history or when stable truth is insufficient.
- Render file references relative to the selected project root; do not emit absolute filesystem paths in the report unless the user explicitly asks for them.
- Prefer context-appropriate relative file paths and command examples over absolute paths in reports and guidance.
- For Git projects, when a repo root needs to be made explicit, prefer `cd "$(git rev-parse --show-toplevel)"` before relative commands.
- Follow `output-styles` for conversational density, evidence labels, numbering, and response mode.
- Treat project scope, truth roots, terminology, search boundaries, document health, and verification basis as analysis axes, not mandatory response sections.
- When another primary skill owns the response, contribute only the project-truth facts, confidence, and drift signals it needs; do not emit an independent project report.
- Emit the conclusion once. Render only relevant findings and omit empty or low-value sections.
- Use `fact`, `inferred`, `judgment`, and `uncertain` as the conversational evidence labels. Record `documented`, `code`, `runtime`, or `external` as evidence provenance only when it matters.
- Report document health and verification basis when they affect confidence, or when full-audit output was explicitly requested.
- Keep one or two short file references with the supporting evidence; use nested reference lists only for larger or ambiguous evidence sets.
- Preserve every drift signal's type, severity, summary, source evidence, verification evidence, and recommended action, but render those fields compactly.
- Keep the result read-only; do not rewrite stable docs from this skill.

## References

- `references/output-contract.md`
- `references/doc-health-and-drift.md`
- Read `references/full-audit-output.md` only for an explicit comprehensive project truth audit.
