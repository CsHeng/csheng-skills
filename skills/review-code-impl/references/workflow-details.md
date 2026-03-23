# Workflow Details

## Full Workflow Steps

1. Collect review scope from git and identify changed files.
2. If no relevant changes are present, stop and report that review scope is empty.
3. If an implementation plan is provided, read it and extract the implementation baseline:
   - required behavior
   - non-goals
   - constraints
   - acceptance criteria
4. If no implementation plan is provided, extract intent from the caller prompt and changed files, then report `spec baseline: inferred` in the final summary.
5. Read only the changed files plus the minimum supporting context needed to understand them.
6. Prefer the skill-local wrapper entrypoint when it is available:
   - `skills/review-code-impl/scripts/run-review.sh --host claude` from Claude
   - `skills/review-code-impl/scripts/run-review.sh --host codex` from Codex
   - add `--plan <path>` when an implementation plan baseline exists
   - add `--reviewer <name>` to override the default opposite-model selection
   - the wrapper delegates to `skills/_review-libs/` so cross-tool execution and workspace isolation are enforced centrally
7. If the wrapper is unavailable, select the primary reviewer CLI manually:
   - If the current host can invoke `codex` and the active session is not already a Codex-hosted review, prefer `codex exec` or `codex review`
   - If the current host can invoke `claude` and the active session is not already a Claude-hosted review, prefer `claude -p`
   - Detect the opposite reviewer by checking CLI availability first (`command -v codex`, `command -v claude`) and then preferring the CLI that is different from the current host
   - If the opposite CLI is unavailable, continue with same-driver review and report that explicitly in the final result
   - Before any direct CLI fallback, the host must create and validate an isolated workspace equivalent to the wrapper-managed workspace; do not invoke a reviewer directly against the full working tree
8. Let the wrapper create an isolated reviewer workspace before invoking the opposite model:
   - canonicalize the workspace root with `realpath`
   - copy only the files under review and required local context
   - reject implementation plan paths outside these allowed roots: the canonical repository root, the canonical plugin root, and `CLAUDE_PLUGIN_ROOT` when it is set and canonicalized
9. Run the wrapper and inspect the structured result:
   - verify the wrapper reported `review_mode`, `reviewer`, and `reviewer_model`
   - verify `status`, `next_action`, `manual_intervention_required`, and `suggested_next_*`
   - verify each Critical/Important finding includes location, evidence, impact, fix, and confidence
   - empty output is treated as reviewer failure, not PASS
10. If mode is `review-only`, stop after reporting the reviewer result.
11. If mode is `repair-review` and verdict is FAIL:
   - if `.status == "needs_fixes"`, the host agent may edit code to fix only `.blocking_findings`
   - keep the implementation plan passed by `--plan` as the fixed baseline for the whole loop
   - save current `.blocking_findings` to a temp file and pass via `--prior-findings` on the next round
   - rerun fresh opposite-model review with `--batch <current batch>` and `--round <suggested_next_round>`
   - stop after PASS or `manual_review_required`
12. If `.status == "manual_review_required"`, return FAIL with `.blocking_findings` and require explicit human approval before any new batch.
13. After human approval, the next batch must start with `--batch <suggested_next_batch> --round 1 --approve-next-batch`.
14. `--max-rounds` may only tighten the loop below the hard cap of 3; default is 2.

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
- Do not mark PASS if the reviewer output is missing.
- Minor findings never block PASS.
- After 3 failed rounds, stop and require explicit human approval before continuing.
- Starting any batch after batch 1 requires explicit approval and `--approve-next-batch`.
