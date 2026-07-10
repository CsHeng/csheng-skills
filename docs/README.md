# Docs

This directory mixes long-lived reference notes with stage artifacts kept for history.

## Stable Truth

- `architecture/workflow-orchestration.md` is the canonical maintenance view of lifecycle routing, the installed invocation DAG, and implementation repair convergence.
- `architecture/diagrams/*.puml` are generated human views of the installed controller contract and must not be edited by hand.
- Other files under `architecture/` document focused mode, invocation, install-surface, and maintenance contracts.
- `changelog/design-decisions.md` records durable architecture decisions and their operational impact.

## Search Defaults

- Default docs searches should avoid `docs/plans/`.
- Search that directory only when you explicitly need history, evolution, or dispute resolution.
- In this repository today, use `rg --no-ignore -n "pattern" docs/plans` for historical search.
- Keep stage artifacts in Git for history; use search-ignore rules to keep them out of default project explanation flows.
