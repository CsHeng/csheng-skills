# Output Contract

Lead with a compact conclusion, then provide the required structured report.

## Formatting Rules

- Use Markdown section headings exactly for the required sections.
- Emit the compact conclusion once only, before the first required section.
- Emit each required section heading exactly once; do not restart or duplicate the report mid-output.
- Use one top-level bullet per conclusion, status item, or drift signal.
- Do not pack multiple fields into one semicolon-delimited line.
- Prefer nested bullets over dense prose when listing fields, refs, or evidence.
- Keep each top-level bullet to a readable one-line summary; move supporting detail to nested bullets.
- Keep `stable_source_refs` and `verification_refs` as one reference per line.
- Leave a blank line between drift signals in `Open Gaps / Drift Signals`.

## Reference Formatting

- `stable_source_refs` and `verification_refs` must use file references, not bare directory names.
- Each reference must include an exact start line in `path:line` form.
- Use paths relative to the selected project root.
- Do not emit absolute filesystem paths unless the user explicitly asks for them.
- Prefer context-appropriate relative paths, such as `docs/guides/host-lifecycle.md:12`.
- Render reference fields as nested lists, not as flush-left plain text.
- Do not append inline `参考 ...` or comma-joined path lists at the end of summary bullets.

## Section Block Shape

For `Project Summary`, `Architecture Boundaries`, `How To Operate`, and `Current Status`, render each finding as a short summary bullet followed by nested evidence:

```md
- `documented`: panel is the commercial control plane, while NetBird is the host-to-host overlay control plane.
  - `refs`:
    - `README.md:7`
    - `docs/architecture/plane-boundaries.md:11`

- `verified`: the public operator entrypoints are exposed through five `make` command families.
  - `refs`:
    - `Makefile:23`
    - `scripts/host/run-playbook.sh:47`
```

Rules:
- Leave a blank line between top-level bullets when a section has more than one bullet.
- Keep the summary line readable on its own; avoid attaching long evidence text to it.
- Put file references under a nested `refs` list unless the section requires a more specific field name.
- Use the same multiline shape in Chinese and English outputs.

## Drift Signal Presentation

Render each drift signal as a multi-line bullet block:

```md
- `verified`: `doc_code_mismatch`
  - `severity`: `medium`
  - `summary`: `docs/development/roadmap.md` still describes legacy names, while code and tests already use the current host and transport vocabulary.
  - `stable_source_refs`:
    - `docs/development/roadmap.md:18`
    - `docs/architecture/naming.md:7`
    - `docs/architecture/plane-boundaries.md:11`
  - `verification_refs`:
    - `Makefile:42`
    - `scripts/host/run-playbook.sh:9`
    - `tests/test_operator_wrapper.py:21`
    - `tests/test_object_model.py:34`
  - `recommended_action`: `run-organize-docs`
```

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
- root reference files with exact `path:line` references
- search policy used for this run
- whether stage artifacts are exerting pressure on the answer

Render `Truth Map` as nested bullets, for example:

```md
- `documented`: this run analyzes the repository root project.
  - `project scope`: `fly-plane`
  - `stable truth roots`:
    - `README.md:1`
    - `AGENTS.md:1`
  - `stage artifact roots`:
    - `docs/plans/`
    - `docs/superpowers/`
  - `root reference files`:
    - `docs/guides/project-orientation.md:15`
    - `docs/architecture/naming.md:5`
  - `search policy used for this run`: default stable-doc search only
  - `stage artifacts are exerting pressure on the answer`: no
```

## Current Status Categories

- `implemented`
- `in progress`
- `planned`
- `unverified`
- `not in scope`

Render each status item as:

```md
- `implemented`: panel projection sync is already wired into the operator workflow.
  - `refs`:
    - `README.md:117`
    - `scripts/delivery/sync_projection.py:73`
```

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
