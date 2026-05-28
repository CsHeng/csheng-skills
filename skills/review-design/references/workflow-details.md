# Workflow Details

## Full Workflow Steps

1. Read the specified design file.
2. Read relevant project context (`AGENTS.md` or `CLAUDE.md` if present, plus nearby docs only as needed).
3. Extract the review baseline before judging:
   - stated goal
   - non-goals or scope limits
   - deliverables
   - constraints
   - acceptance criteria
   - `Implementation Surface` refs (`impl_file_refs`, `test_file_refs`, and any declared out-of-scope file refs)
4. Design docs intended for downstream plan/code review should include `Implementation Surface`; missing refs should be treated as a blocker because later plan/design linkage cannot be validated without them.
5. Use a command wrapper or a resolved plugin-root runner path:
   - `bash "$REVIEW_RUNNER" --mode design --host claude --plan "$DESIGN_PATH"` from Claude
   - `bash "$REVIEW_RUNNER" --mode design --host codex --plan "$DESIGN_PATH"` from Codex
   - `REVIEW_RUNNER` must be the absolute path to `skills/_review-libs/run-review.sh` under the coding plugin root, not a path relative to the target repository
   - `DESIGN_PATH` must be the absolute path to the design artifact
   - Add `--reviewer <name>` to override the default opposite-model selection
   - The shared runner enforces cross-tool execution and workspace isolation centrally
6. If the shared runner is unavailable, select the primary reviewer CLI manually:
   - If running inside Claude, prefer `codex exec`
   - If running inside Codex, prefer `claude -p`
   - If the opposite CLI is unavailable, continue with same-driver review and report that explicitly in the final result
   - Before any direct CLI fallback, the host must create and validate an isolated workspace equivalent to the wrapper-managed workspace; do not invoke a reviewer directly against the full working tree
7. Run the wrapper and inspect the structured result:
   - verify the wrapper reported `review_mode`, `reviewer`, and `reviewer_model`
   - verify `status`, `next_action`, `manual_intervention_required`, and `suggested_next_*`
   - verify each Critical/Important finding includes evidence, impact, fix, and confidence
   - treat empty output as reviewer failure, not PASS
8. If mode is `review-only`, stop after reporting the reviewer result.
9. If mode is `repair-review` and verdict is FAIL:
   - if `.status == "needs_fixes"`, the host agent may edit the design to fix only `.blocking_findings` where `scope_class == "in_scope_blocking"`
   - any blocking finding with `scope_class != "in_scope_blocking"` must force `manual_review_required`
   - save current `.blocking_findings` to a temp file and pass via `--prior-findings` on the next round
   - rerun fresh opposite-model review with `--batch <current batch>` and `--round <suggested_next_round>`
   - stop after PASS or `manual_review_required`
10. If `.status == "manual_review_required"`, return FAIL with `.blocking_findings` and require explicit human approval before any new batch.
11. After human approval, the next batch must start with `--batch <suggested_next_batch> --round 1 --approve-next-batch`.
12. `--max-rounds` may only tighten the loop below the hard cap of 3; default is 3.

## Constraints

- Do not edit the design in `review-only` mode.
- Do not introduce new product scope while fixing the design.
- Only `scope_class: in_scope_blocking` findings are eligible for `repair-review`.
- Do not mark PASS if the reviewer output is missing.
- Minor findings never block PASS.
- After 3 failed rounds, stop and require explicit human approval before continuing.
- Starting any batch after batch 1 requires explicit approval and `--approve-next-batch`.
