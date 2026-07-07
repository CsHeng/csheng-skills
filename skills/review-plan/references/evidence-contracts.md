# Evidence Contract

## Required Fields for Critical/Important Findings

Every Critical or Important finding must include:
- `severity`: `Critical` or `Important`
- `location`: concrete section, heading, or paragraph reference in the plan
- `evidence`: brief quote or paraphrase tied to the plan text
- `impact`: why this could fail in implementation or rollout
- `fix`: the smallest viable change to correct it
- `confidence`: `high`, `medium`, or `low`
- `scope_class`: `baseline_mismatch`, `in_scope_blocking`, `adjacent_debt`, `out_of_dag_issue`, or `external_verification_failure`

Scope class meaning:
- `in_scope_blocking`: must fix within the current milestone and review budget
- `baseline_mismatch`: requires upstream design or approved baseline decision
- `adjacent_debt`: real issue, but future-phase or non-blocking for this milestone
- `out_of_dag_issue`: the plan escaped the approved design/plan boundary
- `external_verification_failure`: runtime, manual, or external evidence must be gathered before closure

Minor findings should use the same field shape as other findings, including `confidence` and `scope_class`, so reviewer output stays schema-compatible.

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
      "confidence": "high",
      "scope_class": "in_scope_blocking"
    }
  ],
  "pass_rationale": "Only required when verdict is PASS"
}
```
