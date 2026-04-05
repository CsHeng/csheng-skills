# Document Health And Drift

## Document Health

- `healthy`: stable docs are largely consistent, cover key project questions, and provide usable operating guidance
- `degraded`: stable docs still guide the reader, but they have gaps, stale areas, or local conflicts
- `untrusted`: stable docs are too incomplete, conflicting, or stale to anchor explanation reliably

## Basis Used For The Run

Pick one basis and report it directly:

- `documentation-led`
- `mixed verification`
- `code reconstruction`

## Required Drift Types

- `doc_code_mismatch`
- `doc_doc_conflict`
- `truth_gap`
- `stage_artifact_pressure` — use this drift label when stage artifacts are exerting pressure on the answer
- `stale_operation`

## Allowed Recommended Actions

- `run-documentation-structure`
- `ask-human`
- `search-stage-artifacts-explicitly`

## Allowed Severity Values

- `high` — stable truth is likely misleading, blocked, or unsafe to trust without intervention
- `medium` — stable truth is still useful, but the answer needs review or explicit qualification
- `low` — the issue is limited, localized, or advisory and does not dominate the answer

## Basis Selection Guidance

- use `documentation-led` when stable truth is healthy and verification mainly confirms it
- use `mixed verification` when stable truth is degraded but still useful with targeted code or test checks
- use `code reconstruction` when stable truth is untrusted and the answer must be rebuilt from implementation evidence
