# Full Project Truth Audit

Use this reference only when the user explicitly requests comprehensive project orientation or a full truth audit.

## Semantic Sections

Cover these concerns once, in this order, combining adjacent sections when that improves density:

1. `Project Summary`: purpose, current conclusion, and the few facts that define the project.
2. `Truth Map`: project scope, stable truth roots, stage artifact roots, root reference files, search policy, document health, verification basis, and stage-artifact pressure.
3. `Terminology Inventory`: important repository-local terms whose meaning affects architecture, operation, lifecycle, compatibility, or status.
4. `Search Boundaries`: default includes and excludes, controlling ignore files, and any explicit historical or generated search path used.
5. `Architecture Boundaries`: ownership, dependency direction, control/data path, or system boundaries relevant to the audit.
6. `How To Operate`: validated entrypoints, commands, gates, or operational sequence.
7. `Current Status`: implemented, in progress, planned, unverified, and out-of-scope items that materially define current state.
8. `Open Gaps / Drift Signals`: only actual gaps or drift, with the complete drift semantics from `output-contract.md`.

## Rendering Rules

- Lead with the compact conclusion before the first section.
- Use each necessary heading once; omit a heading only when the user narrowed the requested audit scope.
- Keep each top-level finding readable on its own and attach only the evidence needed to verify it.
- Use `fact`, `inferred`, `judgment`, and `uncertain` for epistemic status; use evidence provenance separately when useful.
- Do not repeat the conclusion after the audit.
- Prefer compact bullets and tables over deeply nested one-field-per-line blocks.

## Truth Map Minimum

State:

- analyzed project scope
- stable truth roots and root reference files with exact `path:line` references
- stage artifact roots
- search policy used
- document health: `healthy`, `degraded`, or `untrusted`
- basis: `documentation-led`, `mixed verification`, or `code reconstruction`
- whether stage artifacts exerted pressure on the answer

## Drift Minimum

For every emitted drift signal, preserve its stable label, type, severity, summary, stable-source evidence, verification evidence, and allowed recommended action. Do not emit placeholder or empty drift signals.
