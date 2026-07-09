# Cross-Model Review Runner Design Fixture

## Goals

- Treat the design artifact as the upper boundary for downstream plan and code review.
- Parse markdown `impl_file_refs` and `test_file_refs` lists from the design and the plan.
- Reject plans that reference files outside the design surface before review execution starts.
- Keep artifact-DAG validation read-only and deterministic inside the shared review runner.

## Success Criteria

- Plan review aborts before reviewer invocation when the upstream design omits `Implementation Surface` refs.
- Plan review aborts when the plan references a file outside the design surface.
- Code-implementation review aborts when allowed-touch filtering leaves no in-scope files.
- The resolved plan and design are materialized into the isolated workspace before reviewer invocation.

## Non-Goals

- Changing reviewer driver implementations.
- Changing reviewer output schema shape.
- Adding a central artifact registry or external metadata store.

## Summary

This fixture models a design artifact for the review-runner flow in `skills/_review-libs`.
It is intentionally small but repo-relevant, and is used by smoke tests for artifact DAG parsing.

## Problem

The review runner needs deterministic scope controls so plan artifacts can only touch files already declared by the design artifact.

## Architecture And Boundaries

- `skills/_review-libs/artifact-dag.sh` Owns markdown parsing of `impl_file_refs`, `test_file_refs`, `design_ref`, and `design_version`.
- `skills/_review-libs/run-review.sh` Resolves the upstream design from the plan, enforces allowed-root containment, derives the plan-scoped touch set, and persists the resulting touch-set metadata for downstream review reporting.
- `skills/_review-libs/workspace.sh` Filters touched code files to the allowed touch set, records out-of-scope touched files for diagnostics, and materializes the plan and design into the isolated workspace.
- `skills/_review-libs/prompt-builder.sh` Injects upstream design context so downstream review happens in `design -> plan -> code` order.
- `skills/_review-libs/output-validator.sh` Normalizes reviewer JSON, validates the shared output contract, and reconciles blocking findings so only `scope_class: in_scope_blocking` remains auto-repairable.
- `skills/_review-libs/smoke-test/run-review.sh` Provides a harness entrypoint for smoke validation without changing driver behavior.

## Data Flow

1. Load a plan artifact and resolve its upstream `design_ref`.
2. Parse design and plan file surfaces from markdown.
3. Reject out-of-root or out-of-surface references before reviewer invocation.
4. Copy the validated plan and design into the isolated workspace.
5. Run downstream review with `design -> plan -> code` ordering.

## Implementation Surface

- impl_file_refs:
  - skills/_review-libs/run-review.sh
  - skills/_review-libs/workspace.sh
  - skills/_review-libs/prompt-builder.sh
  - skills/_review-libs/artifact-dag.sh
  - skills/_review-libs/output-validator.sh
- test_file_refs:
  - skills/_review-libs/smoke-test/test-artifact-dag.sh
  - skills/_review-libs/smoke-test/test-review-gating.sh
  - skills/_review-libs/smoke-test/smoke-same-driver-review.sh
- out_of_scope_file_refs:
  - skills/_review-libs/drivers/claude.sh
  - skills/_review-libs/drivers/codex.sh
  - skills/_review-libs/drivers/codex.sh

## Scope Rationale

Driver files are out of scope because this fixture focuses on artifact-DAG parsing, plan/design linkage, and bounded review scope. Driver interface or transport changes require a separate design.

## Validation

- Parse markdown lists for implementation and test references.
- Ensure plan references are a strict subset of this design surface.
- Abort review-plan / code-impl setup when the plan references a file outside the design surface.
- Materialize the resolved plan and design into the isolated workspace before reviewer invocation.

## Risks And Operability

- Missing `Implementation Surface` refs in the design: abort plan/code review setup before invoking a reviewer.
- Plan references a file outside the design surface: abort setup, report the violating file path, and require baseline correction.
- Empty in-scope code set after allowed-touch filtering: abort code-implementation review rather than silently widening scope.
- Validation is read-only: no rollback is required because no repository state is mutated by the artifact-DAG gate itself.
