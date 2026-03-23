# Evidence Contract

## Required Fields for Critical/Important Findings

Every Critical or Important finding must include:
- `severity`: `Critical` or `Important`
- `location`: concrete `file:line` or closest available file reference
- `evidence`: brief code-based explanation grounded in the diff or file contents
- `impact`: user-visible, operational, or security consequence
- `fix`: the smallest viable correction
- `confidence`: `high`, `medium`, or `low`

Minor findings should use the same field shape as other findings, including `confidence`, so reviewer output stays schema-compatible.

## PASS Verdict Requirements

A PASS verdict is invalid unless:
- the reviewer output for the active review mode was collected successfully
- no Critical or Important issues remain
- the reviewer provides a short pass rationale grounded in the actual changes
