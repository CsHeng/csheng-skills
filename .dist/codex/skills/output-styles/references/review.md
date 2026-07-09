# Review Mode

Use review mode for code, design, plan, docs, and workflow reviews.

## Shape

1. Findings first, ordered by severity.
2. File and line references for local artifacts whenever possible.
3. Open questions or assumptions.
4. Brief change summary only after findings.
5. Test gaps or residual risk.

When multiple scoped lists appear in one review response, do not restart item numbering. Use stable prefixes:

- findings: `F1`, `F2`
- open questions: `Q1`, `Q2`
- residual risks or test gaps: `R1`, `R2`

## Rules

- Prioritize bugs, behavioral regressions, security risks, missing verification, and drift.
- Do not lead with praise or broad summary.
- If no issues are found, say so directly and name remaining risk or unverified areas.
- Do not invent evidence. State when a claim is inferred or unverified.
