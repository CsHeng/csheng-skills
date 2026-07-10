# Docs Agent Notes

## Truth Boundary

- Treat `docs/` as the home of long-lived project truth unless a more specific local rule says otherwise.
- Treat `docs/architecture/workflow-orchestration.md` as the canonical prose view of workflow routing, DAG ownership, and repair convergence.
- Treat `docs/architecture/diagrams/*.puml` as generated review surfaces. Change the controller-local workflow contract and regenerate them instead of editing them directly.
- Treat `docs/plans/` as stage artifacts and history, not default current-state truth.
- Default docs searches should target stable truth docs first and avoid stage artifacts.

## Search Policy

- Default docs search: `rg -n "pattern" docs`
- Historical docs search in this repository: `rg --no-ignore -n "pattern" docs/plans`
- If `grep` is required, use `grep -R --exclude-dir=plans "pattern" docs`

## Git Note

- `docs/.ignore` affects search tools such as `rg`; it does not control Git tracking.
- Keep stage artifacts under `docs/` in Git when they matter for project history, decision traceability, or later dispute resolution.
- Search suppression for `docs/plans/` belongs in `docs/.ignore`, not in the repository root `.gitignore`.
