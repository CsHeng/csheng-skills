# Artifact DAG And Review Fences

## Status

Proposed and approved in interactive brainstorming on 2026-03-31.

## Context

The current review system is stronger than a plain diff-based review workflow, but it still leaves too much room for drift during repair loops.

The main failure mode is context drift:

- a code-implementation repair loop sees a failing test or adjacent defect
- the host starts fixing problems outside the current implementation slice
- the working context expands beyond the intended plan
- after several rounds, the implementation no longer cleanly tracks the original design intent

This is especially common in TDD-style work, where test execution can surface older or unrelated defects that are real but not part of the current planned slice.

The system needs a harder constraint chain so review and repair stay anchored to the intended artifact lineage:

`design -> plan -> code implementation`

## Goals

- Make `design` the highest-level constraint for implementation review.
- Require every implementation `plan` to explicitly reference its upstream `design`.
- Make review and repair decisions depend on an explicit artifact DAG rather than inferred intent.
- Prevent repair loops from drifting into adjacent or historical issues outside the current plan slice.
- Keep the design lightweight: use document cross-references instead of a central registry.

## Non-Goals

- Do not introduce a separate artifact registry or metadata service.
- Do not support one plan inheriting multiple primary designs.
- Do not turn design or plan review into aggressive auto-rewrite workflows.
- Do not make unrelated legacy defects part of the current repair loop by default.

## Decision Summary

Use explicit document cross-references as the artifact DAG contract.

- `design` defines goals, boundaries, non-goals, acceptance criteria, and implementation surface.
- `plan` must explicitly reference one upstream `design` and define a narrower implementation slice.
- `code-impl review` must load `design + plan + scoped code` and evaluate them in that order.
- automatic repair stays opt-in and is allowed only for in-scope blocking findings inside the approved touch set

No central registry is introduced. The document graph is resolved at review time from the plan's upstream references.

## Artifact DAG

The required artifact lineage is:

`design -> plan -> code-impl review -> repair-review`

Interpretation:

- `design` is the top-level product and architecture constraint.
- `plan` is not independent. It is an execution slice derived from exactly one design.
- `code-impl review` validates implementation first against design boundaries, then against plan commitments, then against code quality concerns.
- `repair-review` is bounded follow-through within the same DAG and must not expand the slice implicitly.

Rules:

- one `design` may have multiple downstream plans
- one `plan` must have exactly one primary upstream design
- if work appears to span multiple designs, create a higher-level integration design first and derive plans from that

## Design Document Contract

Each design document must include an explicit implementation-surface section.

Recommended structure:

```md
## Implementation Surface
- impl_file_refs:
  - path/to/module_or_dir
- test_file_refs:
  - path/to/test_or_dir
- out_of_scope_file_refs:
  - path/to/legacy_or_unrelated_area
- notes:
  - allowed implementation surfaces
  - explicit non-target areas
```

Requirements:

- `impl_file_refs` may point to files or stable module/directory surfaces
- `test_file_refs` should identify the intended verification surface
- `out_of_scope_file_refs` should call out tempting but excluded areas when relevant
- design goals, non-goals, boundaries, and acceptance criteria remain the normative source of intent

The design must constrain where implementation is expected to land before plan or code review begins.

## Plan Document Contract

Each plan must explicitly bind itself to one upstream design.

Recommended structure:

```md
## Upstream Design
- design_ref: docs/plans/review-system/2026-03-31-<topic>-design.md
- design_version: <git commit sha or document version>

## Implementation Scope
- scope_slice: the subset this plan owns
- impl_file_refs:
  - path/to/file_or_dir
- test_file_refs:
  - path/to/test_or_dir
- verification_scope:
  - targeted tests or verification commands allowed for this slice
- out_of_scope:
  - excluded work for this plan
- divergence_from_design: none
```

Requirements:

- `design_ref` is mandatory for plans intended to drive implementation review
- `design_version` must pin the referenced design state
- `impl_file_refs` in the plan must be a subset of the design's `impl_file_refs`
- if a plan intentionally exceeds the design surface, it must declare `divergence_from_design` and should normally be rejected until the design is updated
- the plan should reference design constraints rather than duplicating large sections of design text

## Review Semantics

### Review Plan

`review-plan` becomes validation of a plan as a legal execution slice of a design, not just a free-form document critique.

For any implementation-driving plan, `design_ref` is required. The wrapper must:

- resolve and load the upstream design
- require the design to include `impl_file_refs`
- verify the plan's implementation and test refs are compatible with the design
- fail fast on missing or inconsistent artifact linkage before invoking the reviewer

If `design_ref` is missing, `review-plan` must fail pre-validation rather than treating the plan as free-form intent.

Evaluation order:

1. Is the upstream design reference valid and pinned?
2. Is the plan a coherent subset of the design?
3. Are scope, verification, and acceptance criteria concrete and non-drifting?

### Review Code Implementation

`review-code-impl` must no longer review code against only local diff intent when a plan exists.

Required review context:

1. upstream `design`
2. current `plan`
3. scoped implementation files
4. scoped tests
5. current-round blocking findings, when in repair mode

Evaluation order:

1. does the implementation violate design boundaries or non-goals?
2. does it fail to satisfy the plan's intended slice?
3. does it have correctness, security, test, or production-readiness issues inside that slice?

This order is mandatory because otherwise reviewers and hosts are too likely to drift from local code signals into design-expanding repairs.

## Allowed Touch Set

For code implementation work, define:

- `design_ceiling = design.impl_file_refs`
- `allowed_touch_set = plan.impl_file_refs + plan.test_file_refs`

Rules:

- `allowed_touch_set` must be non-empty
- `allowed_touch_set` must stay within `design_ceiling`
- code review scope may be collected from git, but repair authority is bounded by `allowed_touch_set`
- touching files outside `allowed_touch_set` is a scope violation unless the plan is explicitly revised first

This keeps review scope observationally broad enough to detect drift while keeping repair scope operationally narrow.

## Finding Taxonomy

Severity alone is not enough. Findings must also be classified by scope relationship.

### `baseline_mismatch`

Definition:

- design and plan conflict
- plan is missing required upstream linkage
- implementation requires changing plan or design before code repair makes sense

Handling:

- blocking
- do not enter code auto-repair
- fix the artifact baseline first

### `in_scope_blocking`

Definition:

- critical or important issue
- inside the current `design -> plan -> impl` chain
- inside `allowed_touch_set`

Handling:

- eligible for bounded `repair-review`

### `adjacent_debt`

Definition:

- nearby real issue
- plausibly in the same broader design surface
- outside the current plan slice

Handling:

- report it
- do not auto-fix it in the current loop
- candidate for a later plan

### `out_of_dag_issue`

Definition:

- unrelated historical issue or separate subsystem problem
- outside the current design/plan lineage

Handling:

- report only
- no auto-repair in the current loop

### `external_verification_failure`

Definition:

- verification failure caused by environment, unrelated suite breakage, or global workspace noise

Handling:

- do not treat as an implementation finding to auto-fix
- require human decision or scoped verification adjustment

## Repair Fence Policy

### Design Review

Default mode should remain review-only.

If any repair assistance is later allowed, it must stay limited to:

- missing references
- missing implementation/test refs
- local ambiguity
- internal contradiction cleanup

It must not:

- rewrite goals
- expand non-goals
- widen design boundaries
- enlarge the implementation surface automatically

### Plan Review

Default mode should remain review-only.

If any repair assistance is later allowed, it must stay limited to:

- adding `design_ref`
- adding `design_version`
- adding or tightening `impl_file_refs`
- adding verification mapping
- tightening scope wording

It must not:

- expand the plan to absorb adjacent work
- rewrite the upstream design intent
- legalize design-external implementation through auto-editing

### Code Implementation Review

`repair-review` remains opt-in.

Automatic repair is allowed only when all conditions hold:

- finding class is `in_scope_blocking`
- the required edit stays within `allowed_touch_set`
- the fix does not require changing design or plan
- the fix does not require widening verification scope

If any of the following is true, return `manual_review_required` instead of auto-repair:

- the fix requires touching files outside `allowed_touch_set`
- the fix would change design boundaries or plan scope
- the finding is `baseline_mismatch`
- the finding is `adjacent_debt`
- the finding is `out_of_dag_issue`
- the finding is `external_verification_failure`

## Multi-Round Context Policy

Repair loops should carry only the minimum bounded context.

Carry forward:

- pinned `design_ref`
- pinned `design_version`
- pinned `plan_ref`
- current blocking findings
- current batch/round metadata

Do not carry forward:

- full chat transcripts
- all prior findings
- non-blocking findings
- unrelated verification noise
- broad working-tree context outside the allowed slice

This keeps each rerun anchored to the same baseline rather than letting the context balloon round by round.

## Why This Direction

The comparison baseline is useful:

- `openai/codex-plugin-cc` is strong on runtime ergonomics such as background jobs, status/result retrieval, cancellation, and stop-time gating
- the current repository's review system is stronger on cross-model governance, structured outputs, workspace isolation, and bounded repair loops

The main gap in the current repository is not job orchestration. It is baseline control.

Without an explicit artifact DAG:

- code review tends to collapse into diff review
- repair loops overfit to local failing tests
- TDD and verification noise can pull the host into unrelated work

This proposal addresses that gap first.

Runtime UX improvements such as job status, result retrieval, cancellation, or stop-gate hooks are valuable follow-up work, but they should be layered on top of the artifact DAG rather than used as a substitute for it.

## Risks

- Authors may resist adding explicit file refs to design and plan docs.
- File-ref lists can become stale if document maintenance is weak.
- Some implementation slices may begin with only rough module-level refs rather than precise files.

These are acceptable trade-offs. Soft, occasionally stale explicit boundaries are still better than no explicit boundary at all.

## Acceptance Criteria

- Every implementation-driving plan references exactly one upstream design.
- Every referenced design includes explicit implementation-surface refs.
- `review-plan` fails fast on missing or inconsistent design linkage.
- `review-code-impl` always evaluates `design -> plan -> code` in that order when a plan is present.
- repair-review only auto-fixes `in_scope_blocking` findings within `allowed_touch_set`.
- adjacent or unrelated issues are surfaced without being silently absorbed into the active repair loop.

## Decided Defaults

- `design_version` should be a git commit SHA for committed design documents.
- `impl_file_refs` should start with stable path or module references, not globs.
- `verification_scope` may include targeted commands and test-file refs, but each entry must stay explicitly scoped to the current plan slice.
