# Workflow Details

## Full Workflow Steps

1. Read the specified plan file.
2. Resolve upstream design linkage from `## Upstream Design`:
   - `design_ref is required`
   - `design_version` is required
   - load the upstream design first
   - fail fast if the linkage is missing, unresolved, or points outside the allowed roots enforced by the runner
3. Read relevant project context (`AGENTS.md` or `CLAUDE.md` if present, plus nearby docs only as needed).
4. Extract the review baseline before judging:
   - upstream design goals, non-goals, and constraints
   - upstream design `Implementation Surface` refs
   - plan deliverables
   - plan constraints
   - plan acceptance criteria
   - plan `Work Package Readiness`
5. Use a command wrapper or a resolved plugin-root runner path:
   - `bash "$REVIEW_RUNNER" --mode plan --host claude --plan "$PLAN_PATH"` from Claude
   - `bash "$REVIEW_RUNNER" --mode plan --host codex --plan "$PLAN_PATH"` from Codex
   - default `--depth auto` resolves to boundary-focused plan review
   - default `--max-rounds` resolves to `1` for plan review
   - `REVIEW_RUNNER` must be the absolute path to `skills/_review-libs/run-review.sh` under the coding plugin root, not a path relative to the target repository
   - `PLAN_PATH` must be the absolute path to the plan artifact
   - The shared runner enforces same-driver reviewer selection and workspace isolation centrally
6. The runner validates the plan's `Implementation Scope` against the upstream design's `Implementation Surface` and computes downstream `allowed_touch_set = plan.impl_file_refs + plan.test_file_refs`.
7. If the shared runner is unavailable, select the primary reviewer CLI manually:
   - Use the same driver as the host
   - Before any direct CLI fallback, the host must create and validate an isolated workspace equivalent to the wrapper-managed workspace; do not invoke a reviewer directly against the full working tree
8. Run the wrapper and inspect the structured result:
   - verify the wrapper reported `review_mode`, `reviewer`, and `reviewer_model`
   - verify `status`, `next_action`, `manual_intervention_required`, and `suggested_next_*`
   - verify each Critical/Important finding includes evidence, impact, fix, and confidence
   - treat empty output as reviewer failure, not PASS
9. If mode is `review-only`, stop after reporting the reviewer result.
10. If mode is `repair-review` and verdict is FAIL:
   - if `.status == "needs_fixes"`, the host agent may edit the plan to fix only `.blocking_findings` where `scope_class == "in_scope_blocking"`
   - any blocking finding with `scope_class != "in_scope_blocking"` must force `manual_review_required`
   - save current `.blocking_findings` to a temp file and pass via `--prior-findings` on the next round
   - rerun fresh review with `--batch <current batch>` and `--round <suggested_next_round>`
   - stop after PASS or `manual_review_required`
11. If `.status == "manual_review_required"`, return FAIL with `.blocking_findings` and require explicit human approval before any new batch.
12. After human approval, the next batch must start with `--batch <suggested_next_batch> --round 1 --approve-next-batch`.
13. `--max-rounds` may only tighten or explicitly override the loop below the hard cap of 3; default is 1 for plan review.
14. Default review budget is 2 batches total. If the lower-plane result suggests `suggested_next_batch > 2`, stop for split scope, upstream design revision, or deliberate harness override.

## Output Format

### Review Mode
- `same-driver`

### Round Result
- Review batch `B`
- `Review round N/3`
- `Verdict: PASS | FAIL`
- `Plan modified: yes | no`
- `Status: pass | needs_fixes | manual_review_required`
- `Next action: stop_passed | host_fix_then_rerun | human_decision_required`

### Findings

#### Critical (Must Fix)
- `[location]` issue
  Evidence: ...
  Impact: ...
  Fix: ...
  Confidence: ...

#### Important (Should Fix)
- `[location]` issue
  Evidence: ...
  Impact: ...
  Fix: ...
  Confidence: ...

#### Minor (Nice to Have)
- `[location]` issue

### Review Summary
- Reviewer concerns covered
- Reviewer CLI used
- Reviewer model used
- Review mode
- Evidence completeness: `complete | incomplete`
- Pass rationale or fail rationale in 1-3 sentences

## Constraints

- Do not edit the plan in `review-only` mode.
- Do not introduce new product scope while fixing the plan.
- Only `scope_class: in_scope_blocking` findings are eligible for `repair-review`.
- Do not mark PASS if the reviewer output is missing.
- Minor findings never block PASS.
- After the default failed round, stop and require explicit human approval before continuing; `--max-rounds 2` or `3` is a deliberate maintainer override.
- Starting any batch after batch 1 requires explicit approval and `--approve-next-batch`.
- Do not treat future-phase or out-of-DAG findings as current-plan repair items.
- Do not treat implementation details as plan blockers unless they make the current DAG, oracle, ownership, or rollback boundary unreviewable.
