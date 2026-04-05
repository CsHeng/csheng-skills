# Docs Agent Notes

## Truth Boundary

- Treat `docs/` as the home of long-lived project truth unless a more specific local rule says otherwise.
- Treat `docs/plans/` and `docs/superpowers/` as stage artifacts and history, not default current-state truth.
- Default docs searches should target stable truth docs first and avoid stage artifacts.

## Search Policy

- Default docs search: `rg -n "pattern" docs`
- Historical docs search in this repository: `rg --no-ignore -n "pattern" docs/superpowers`
- If additional stage-artifact directories such as `docs/plans/` exist later, include them explicitly in the historical search command.
- If `grep` is required, use `grep -R --exclude-dir=plans --exclude-dir=superpowers "pattern" docs`

## Git Note

- `docs/.ignore` affects search tools such as `rg`; it does not control Git tracking.
- In this repository, the root `.gitignore` ignores stage artifacts such as `docs/plans/` and `docs/superpowers/`.
- `git add -f <path>` matters here only when you intentionally want to track a path that the root `.gitignore` would otherwise block.
