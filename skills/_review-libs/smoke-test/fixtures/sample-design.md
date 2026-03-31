# Cross-Model Review Runner Design Fixture

## Summary

This fixture models a design artifact for the review-runner flow in `skills/_review-libs`.
It is intentionally small but repo-relevant, and is used by smoke tests for artifact DAG parsing.

## Problem

The review runner needs deterministic scope controls so plan artifacts can only touch files
already declared by the design artifact.

## Implementation Surface

- impl_file_refs:
  - skills/_review-libs/run-review.sh
  - skills/_review-libs/workspace.sh
  - skills/_review-libs/prompt-builder.sh
  - skills/_review-libs/artifact-dag.sh
  - skills/_review-libs/smoke-test/run-review.sh
- test_file_refs:
  - skills/_review-libs/smoke-test/test-artifact-dag.sh
  - skills/_review-libs/smoke-test/smoke-cross-model-review.sh
- out_of_scope_file_refs:
  - skills/_review-libs/drivers/claude.sh
  - skills/_review-libs/drivers/codex.sh
  - skills/_review-libs/drivers/gemini.sh

## Validation

- Parse markdown lists for implementation and test references.
- Ensure plan references are a strict subset of this design surface.
