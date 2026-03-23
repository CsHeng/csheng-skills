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
4. Prefer the skill-local wrapper entrypoint when it is available:
   - `skills/review-design/scripts/run-review.sh --host claude --plan <path>` from Claude
   - `skills/review-design/scripts/run-review.sh --host codex --plan <path>` from Codex
   - Add `--reviewer <name>` to override the default opposite-model selection
   - The wrapper delegates to `skills/_review-libs/` so cross-tool execution and workspace isolation are enforced centrally
5. If the wrapper is unavailable, select the primary reviewer CLI manually:
   - If running inside Claude, prefer `codex exec`
   - If running inside Codex, prefer `claude -p`
   - If the opposite CLI is unavailable, continue with same-driver review and report that explicitly in the final result
   - Before any direct CLI fallback, the host must create and validate an isolated workspace equivalent to the wrapper-managed workspace; do not invoke a reviewer directly against the full working tree
6. Run the wrapper and inspect the structured result:
   - verify the wrapper reported `review_mode`, `reviewer`, and `reviewer_model`
   - verify `status`, `next_action`, `manual_intervention_required`, and `suggested_next_*`
   - verify each Critical/Important finding includes evidence, impact, fix, and confidence
   - treat empty output as reviewer failure, not PASS
7. If mode is `review-only`, stop after reporting the reviewer result.
8. If mode is `repair-review` and verdict is FAIL:
   - if `.status == "needs_fixes"`, the host agent may edit the design to fix only `.blocking_findings`
   - save current `.blocking_findings` to a temp file and pass via `--prior-findings` on the next round
   - rerun fresh opposite-model review with `--batch <current batch>` and `--round <suggested_next_round>`
   - stop after PASS or `manual_review_required`
9. If `.status == "manual_review_required"`, return FAIL with `.blocking_findings` and require explicit human approval before any new batch.
10. After human approval, the next batch must start with `--batch <suggested_next_batch> --round 1 --approve-next-batch`.
11. `--max-rounds` may only tighten the loop below the hard cap of 3; default is 2.

## Constraints

- Do not edit the design in `review-only` mode.
- Do not introduce new product scope while fixing the design.
- Do not mark PASS if the reviewer output is missing.
- Minor findings never block PASS.
- After 3 failed rounds, stop and require explicit human approval before continuing.
- Starting any batch after batch 1 requires explicit approval and `--approve-next-batch`.
