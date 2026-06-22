# Workflow Details

## Full Workflow Steps

1. Collect review scope from git and identify changed files.
2. If no relevant changes are present, stop and report that review scope is empty.
3. If an implementation plan is provided, resolve upstream design linkage before reading code:
   - `design_ref is required`
   - `design_version` is required
   - load the upstream design first
   - fail fast if that linkage is missing or unresolved
4. If an implementation plan is provided, review in this order: `design -> plan -> code`.
5. If an implementation plan is provided, derive `allowed_touch_set = plan.impl_file_refs + plan.test_file_refs`.
6. If an implementation plan is provided, filter the changed-file scope to the active plan-bound review read surface, record any `out_of_scope_touched_files` relative to `allowed_touch_set`, and stop if no in-scope files remain after filtering.
7. If no implementation plan is provided, extract intent from the caller prompt and changed files, then report `spec baseline: inferred` in the final summary.
8. Read only the changed files that remain in scope plus the minimum supporting context needed to understand them. Read scope may be wider than repair scope, but it must remain inside the active design/plan lineage.
9. Use a command wrapper or a resolved plugin-root runner path:
   - `bash "$REVIEW_RUNNER" --mode code-impl --host claude` from Claude
   - `bash "$REVIEW_RUNNER" --mode code-impl --host codex` from Codex
   - `REVIEW_RUNNER` must be the absolute path to `skills/_review-libs/run-review.sh` under the coding plugin root, not a path relative to the target repository
   - add `--plan <path>` when an implementation plan baseline exists
   - add `--reviewer <name>` to override the reviewer driver within the selected strategy
   - add `--cross-model` or `--adversarial` only when the user explicitly requests cross/adversarial review
   - the shared runner enforces reviewer selection and workspace isolation centrally
10. If the shared runner is unavailable, select the primary reviewer CLI manually:
   - Prefer the same driver as the host by default
   - Use an opposite driver only when the user explicitly requested cross/adversarial review
   - Before any direct CLI fallback, the host must create and validate an isolated workspace equivalent to the wrapper-managed workspace; do not invoke a reviewer directly against the full working tree
11. Let the wrapper create an isolated reviewer workspace before invoking the reviewer:
   - canonicalize the workspace root with `realpath`
   - copy only the files under review and required local context
   - reject implementation plan paths outside these allowed roots: the canonical repository root, the canonical plugin root, and `CLAUDE_PLUGIN_ROOT` when it is set and canonicalized
12. Run the wrapper and inspect the structured result:
   - verify the wrapper reported `review_mode`, `reviewer`, and `reviewer_model`
   - verify `status`, `next_action`, `manual_intervention_required`, and `suggested_next_*`
   - verify `.scope.allowed_touch_set` matches the bounded repair surface derived from the plan
   - verify each Critical/Important finding includes location, evidence, impact, fix, and confidence
   - empty output is treated as reviewer failure, not PASS
13. If mode is `review-only`, stop after reporting the reviewer result.
14. If mode is `repair-review` and verdict is FAIL:
   - if `.status == "needs_fixes"`, the host agent may edit code to fix only `.blocking_findings` where `scope_class == "in_scope_blocking"`
   - keep the implementation plan passed by `--plan` as the fixed baseline for the whole loop
   - keep all edits inside `allowed_touch_set`
   - any blocking finding with `scope_class != "in_scope_blocking"` must force `manual_review_required`
   - save current `.blocking_findings` to a temp file and pass via `--prior-findings` on the next round
   - rerun fresh review with `--batch <current batch>` and `--round <suggested_next_round>`
   - stop after PASS or `manual_review_required`
15. If `.status == "manual_review_required"`, return FAIL with `.blocking_findings` and require explicit human approval before any new batch.
16. After human approval, the next batch must start with `--batch <suggested_next_batch> --round 1 --approve-next-batch`.
17. `--max-rounds` may only tighten the loop below the hard cap of 3; default is 3.

## Scope Collection

Collect scope with:

```bash
git status --short
git diff --stat
git diff
git diff --cached --stat
git diff --cached
```

## Constraints

- Do not edit code in `review-only` mode.
- Do not introduce new product scope while fixing code.
- Only `scope_class: in_scope_blocking` findings are eligible for `repair-review`.
- Read scope may be wider than repair scope when a plan baseline exists, but it must remain within the current design/plan surface.
- When a plan baseline exists, keep repairs inside `allowed_touch_set`.
- Do not mark PASS if the reviewer output is missing.
- Minor findings never block PASS.
- After 3 failed rounds, stop and require explicit human approval before continuing.
- Starting any batch after batch 1 requires explicit approval and `--approve-next-batch`.
