# Artifact DAG Parsing Plan Fixture

## Upstream Design

- design_ref: skills/_review-libs/smoke-test/fixtures/sample-design.md
- design_version: f203ff0

## Scope

Narrow implementation to review-runner DAG helpers and review-runner integration points.

## Implementation Scope

- scope_slice: run-review + workspace + prompt-builder + artifact-dag helper validation
- verification_scope: parse markdown bullet lists for both `impl_file_refs` and `test_file_refs`, verify design linkage and touch-set gating, and confirm the targeted plan smoke path still returns valid structured output
- out_of_scope:
  - driver wrapper implementation changes
  - reviewer output schema changes
- divergence_from_design: none
- impl_file_refs:
  - skills/_review-libs/artifact-dag.sh
  - skills/_review-libs/run-review.sh
  - skills/_review-libs/workspace.sh
  - skills/_review-libs/prompt-builder.sh
  - skills/_review-libs/smoke-test/run-review.sh
- test_file_refs:
  - skills/_review-libs/smoke-test/test-artifact-dag.sh
  - skills/_review-libs/smoke-test/smoke-cross-model-review.sh

## Validation

- `bash skills/_review-libs/smoke-test/test-artifact-dag.sh`
- `bash -n skills/_review-libs/smoke-test/smoke-cross-model-review.sh`
- `bash skills/_review-libs/smoke-test/smoke-cross-model-review.sh plan --reviewer claude --timeout 1800 --plan skills/_review-libs/smoke-test/fixtures/sample-plan.md`
- Optional local fallback when the preferred reviewer is unavailable: `bash skills/_review-libs/smoke-test/smoke-cross-model-review.sh plan --reviewer codex --timeout 600 --plan skills/_review-libs/smoke-test/fixtures/sample-plan.md`

Success means:

- markdown list parsing succeeds for both implementation and test refs
- plan refs remain a strict subset of the upstream design surface
- the preferred plan-mode smoke path returns valid structured harness output with required fields: `review_mode`, `reviewer`, `reviewer_model`, `status`, `next_action`, `blocking_findings`, and `result.verdict`
- no driver wrapper implementation changes are required for this slice; the smoke run is a compatibility check against the existing driver layer
