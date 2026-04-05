# Output Contract

Lead with a compact conclusion, then provide the required structured report.

## Required Sections

- `Project Summary`
- `Truth Map`
- `Architecture Boundaries`
- `How To Operate`
- `Current Status`
- `Open Gaps / Drift Signals`

## Required Run Metadata

- `document health`
- `basis used for this run`

## Conclusion Labels

Use one of these labels for each major conclusion:

- `documented`
- `verified`
- `inferred`
- `uncertain`

## Truth Map Requirements

`Truth Map` must state:

- analyzed `project scope`
- stable truth roots
- stage artifact roots
- root reference files
- search policy used for this run
- whether stage artifacts are exerting pressure on the answer

## Current Status Categories

- `implemented`
- `in progress`
- `planned`
- `unverified`
- `not in scope`

## Drift Signal Fields

Each drift signal must include:

- `type`
- `severity`
- `summary`
- `stable_source_refs`
- `verification_refs`
- `recommended_action`

Allowed `recommended_action` values are defined in `references/doc-health-and-drift.md`.
Allowed `severity` values are defined in `references/doc-health-and-drift.md`.
