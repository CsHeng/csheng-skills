# Evidence Contract

## Required Fields for Critical/Important Findings

Every Critical or Important finding must include:
- `severity`: `Critical` or `Important`
- `location`: concrete section, heading, or paragraph reference in the plan
- `evidence`: brief quote or paraphrase tied to the plan text
- `impact`: why this could fail in implementation or rollout
- `fix`: the smallest viable change to correct it
- `confidence`: `high`, `medium`, or `low`

Minor findings should use the same field shape as other findings, including `confidence`, so reviewer output stays schema-compatible.

## PASS Verdict Requirements

A PASS verdict is invalid unless:
- the reviewer output for the active review mode was collected successfully
- no Critical or Important issues remain
- the reviewer provides a short pass rationale grounded in the plan

## Structured Reviewer Output

Each reviewer must return a structured result equivalent to:

```json
{
  "lens": "requirements-risk",
  "verdict": "PASS",
  "summary": "Short technical assessment.",
  "findings": [
    {
      "severity": "Important",
      "location": "Task 2 / Step 3",
      "evidence": "Plan updates schema but omits migration rollback.",
      "impact": "Rollback would require manual repair during deployment.",
      "fix": "Add a rollback step and ownership for reversal.",
      "confidence": "high"
    }
  ],
  "pass_rationale": "Only required when verdict is PASS"
}
```
