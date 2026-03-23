# Evidence Contract

## Required Fields for Critical/Important Findings

Every Critical or Important finding must include:
- `severity`: `Critical` or `Important`
- `location`: concrete section, heading, or paragraph reference in the design
- `evidence`: brief quote or paraphrase tied to the design text
- `impact`: why this could fail in implementation or rollout
- `fix`: the smallest viable change to correct it
- `confidence`: `high`, `medium`, or `low`

Minor findings should use the same field shape as other findings, including `confidence`, so reviewer output stays schema-compatible.

## PASS Verdict Requirements

A PASS verdict is invalid unless:
- the reviewer output for the active review mode was collected successfully
- no Critical or Important issues remain
- the reviewer provides a short pass rationale grounded in the design
