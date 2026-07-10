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
   - default `--depth auto` resolves to thorough code implementation review
   - default `--max-rounds` resolves to the hard cap of `10` for code implementation review
   - `REVIEW_RUNNER` must be the absolute path to `skills/_review-libs/run-review.sh` under the coding plugin root, not a path relative to the target repository
   - add `--plan <path>` when an implementation plan baseline exists
   - the shared runner enforces same-driver reviewer selection and workspace isolation centrally
10. If the shared runner is unavailable, select the primary reviewer CLI manually:
   - Use the same driver as the host
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
13. Stop after reporting the reviewer result. This skill never edits implementation or advances lifecycle state.
14. When the caller provides prior findings, compare current evidence with them and return a fresh complete verdict rather than assuming the previous repair succeeded.
15. If `.status == "needs_fixes"`, return only evidence-backed `.blocking_findings` where `scope_class == "in_scope_blocking"` as eligible input to the caller's repair classification.
16. If any blocking finding has another scope class, return `manual_review_required` so the lifecycle controller can choose replan, redesign, authority, external verification, or rollback.
17. Preserve the implementation plan passed by `--plan` as the fixed baseline across rounds.
18. Round metadata defaults to the hard limit of 10; expected convergence is 5, and the lifecycle controller owns every decision to continue or stop earlier.

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
- Only `scope_class: in_scope_blocking` findings are eligible for controller-owned repair.
- Read scope may be wider than repair scope when a plan baseline exists, but it must remain within the current design/plan surface.
- When a plan baseline exists, keep repairs inside `allowed_touch_set`.
- Do not mark PASS if the reviewer output is missing.
- Minor findings never block PASS.
- Do not interpret round or batch metadata as permission to edit code.
- Do not invoke lifecycle controllers or review facades from this evaluator.
