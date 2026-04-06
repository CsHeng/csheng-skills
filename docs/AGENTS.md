# Docs Agent Notes

## Truth Boundary

- Treat `docs/` as the home of long-lived project truth unless a more specific local rule says otherwise.
- Treat `docs/plans/` and `docs/superpowers/` as stage artifacts and history, not default current-state truth.
- Default docs searches should target stable truth docs first and avoid stage artifacts.

## Search Policy

- Default docs search: `rg -n "pattern" docs`
- Historical docs search in this repository: `rg --no-ignore -n "pattern" docs/plans docs/superpowers`
- If `grep` is required, use `grep -R --exclude-dir=plans --exclude-dir=superpowers "pattern" docs`

## Git Note

- `docs/.ignore` affects search tools such as `rg`; it does not control Git tracking.
- Keep stage artifacts under `docs/` in Git when they matter for project history, decision traceability, or later dispute resolution.
- Search suppression for `docs/plans/` and `docs/superpowers/` belongs in `docs/.ignore`, not in the repository root `.gitignore`.
