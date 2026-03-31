# Artifact DAG Parsing Plan Fixture

## Upstream Design

- design_ref: skills/_review-libs/smoke-test/fixtures/sample-design.md
- design_version: f203ff0

## Scope

Narrow implementation to review-runner DAG helpers and review-runner integration points.

## Implementation Scope

- scope_slice: run-review + workspace + prompt-builder + artifact DAG validation
- verification_scope: fixture-backed parser checks for design linkage and touch-set gating
- out_of_scope:
  - driver wrappers
  - reviewer output schema
- divergence_from_design: none
- impl_file_refs:
  - skills/_review-libs/run-review.sh
  - skills/_review-libs/workspace.sh
  - skills/_review-libs/prompt-builder.sh
  - skills/_review-libs/smoke-test/run-review.sh
- test_file_refs:
  - skills/_review-libs/smoke-test/test-artifact-dag.sh
  - skills/_review-libs/smoke-test/smoke-cross-model-review.sh
