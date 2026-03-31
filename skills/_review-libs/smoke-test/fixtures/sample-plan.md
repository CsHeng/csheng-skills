# Artifact DAG Parsing Plan Fixture

## Upstream Design

- design_ref: skills/_review-libs/smoke-test/fixtures/sample-design.md
- design_version: f203ff0

## Scope

Narrow implementation to review-runner DAG helpers and review-runner integration points.

## Implementation Scope

- scope_slice: artifact-dag helper parsing plus shared-runner integration for design linkage, touch-set gating, and review-state classification
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
  - skills/_review-libs/output-validator.sh
- test_file_refs:
  - skills/_review-libs/smoke-test/test-artifact-dag.sh
  - skills/_review-libs/smoke-test/test-review-gating.sh
  - skills/_review-libs/smoke-test/smoke-cross-model-review.sh

## File Responsibilities

- `skills/_review-libs/artifact-dag.sh`
  Parse `design_ref`, `design_version`, `impl_file_refs`, and `test_file_refs`, and expose the parsed surfaces used by the shared runner.
- `skills/_review-libs/run-review.sh`
  Resolve the upstream design before review, reject out-of-root design refs, enforce strict-subset checks between plan and design surfaces, and carry the derived `allowed_touch_set` into run metadata.
- `skills/_review-libs/workspace.sh`
  Filter touched files to the allowed touch set, record out-of-scope touched files, and copy the plan and design into the isolated review workspace.
- `skills/_review-libs/prompt-builder.sh`
  Inject the upstream design baseline so review order stays `design -> plan -> code`.
- `skills/_review-libs/output-validator.sh`
  Reconcile reviewer findings into the run-level control plane so only `in_scope_blocking` remains auto-repairable.

## Validation

- `bash skills/_review-libs/smoke-test/test-artifact-dag.sh`
- `bash skills/_review-libs/smoke-test/test-review-gating.sh`
- `bash -n skills/_review-libs/smoke-test/smoke-cross-model-review.sh`
- `bash skills/_review-libs/smoke-test/smoke-cross-model-review.sh plan --reviewer claude --timeout 1800 --plan skills/_review-libs/smoke-test/fixtures/sample-plan.md`
- Optional local fallback when the preferred reviewer is unavailable: `bash skills/_review-libs/smoke-test/smoke-cross-model-review.sh plan --reviewer codex --timeout 600 --plan skills/_review-libs/smoke-test/fixtures/sample-plan.md`
- `bash skills/_review-libs/smoke-test/test-artifact-dag.sh` must also cover negative-path aborts for: missing `Implementation Surface` refs, plan refs outside the design surface, and empty in-scope code after allowed-touch filtering

Rollout and rollback:

- Rollout mode: enforce the artifact-DAG gate directly in the shared runner for this fixture path.
- Compatibility expectation: plans lacking `## Upstream Design` or touching files outside the design surface are expected to fail fast.
- Rollback: revert the artifact-DAG gate wiring in the shared runner or disable the fixture path from smoke validation if compatibility issues surface during testing.

Success means:

- markdown list parsing succeeds for both implementation and test refs
- plan refs remain a strict subset of the upstream design surface
- a design artifact missing `Implementation Surface` refs causes plan/code review setup to abort before reviewer invocation
- an empty in-scope code set after allowed-touch filtering causes code-implementation review to abort instead of widening scope
- the preferred plan-mode smoke path returns valid structured harness output with required fields: `review_mode`, `reviewer`, `reviewer_model`, `status`, `next_action`, `blocking_findings`, and `result.verdict`
- no driver wrapper implementation changes are required for this slice; the smoke run is a compatibility check against the existing driver layer
