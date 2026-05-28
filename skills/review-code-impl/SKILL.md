---
name: review-code-impl
description: "Use for cross-model review of implementation code, code fixes, or plan-bound changes; supports review-only and repair-review loops."
---

# Review Code Implementation

Review code implementation changes against an implementation plan with a cross-model workflow:
- The primary review must come from an opposite coding CLI when available.
- Default reviewer model targets are `gpt-5.4` for Codex, `claude-opus-4-6` for Claude, and `gemini-3.1-pro-preview` for Gemini.
- Default reviewer timeout is `1800` seconds per invocation.
- Reviewer execution modes are read-only sandbox for Codex, plan/read-only for Claude, and `--approval-mode yolo` for Gemini inside the isolated review workspace.
- For artifact-DAG fenced review, the runner loads the upstream design via the plan's `design_ref` and evaluates `design -> plan -> code`.
- The bounded repair surface is `.scope.allowed_touch_set`, derived as `plan.impl_file_refs + plan.test_file_refs`.
- The implementation plan passed by `--plan` is the fixed initial baseline for the repair loop.
- The reviewer covers spec compliance, correctness, security, testing, and production-readiness in one structured pass.
- The host agent owns the repair loop and final stop/go decision.
- Readonly review scope may expand to the relevant plan-bound design surface when needed for understanding; automatic edits still remain bounded by `.scope.allowed_touch_set`.
- Repair rounds stop after 3 rounds and require explicit human approval before starting another batch.

## Modes

- `review-only`: produce findings and verdict, do not edit code
- `repair-review`: the host agent fixes only Critical/Important findings with `scope_class: in_scope_blocking`, and only inside `.scope.allowed_touch_set`, then reruns fresh review up to 3 rounds per batch
- `repair-review` is an optional bounded accelerator for the main execution loop, not the lifecycle owner of the whole change
- command wrappers should default to `review-only`; `repair-review` is explicit opt-in

## Inputs

- Review scope: auto-determine from git or explicit file list (required)
- Implementation plan path: caller-specified and strongly recommended as the baseline; for artifact-DAG fenced review, `design_ref is required`
- User intent and acceptance criteria: caller prompt and linked docs
- Project context: `AGENTS.md` or `CLAUDE.md` if present

## Review Concerns

| Concern | Focus |
|---------|-------|
| Spec compliance | Match against the implementation plan or stated intent, detect missing features and unapproved extras |
| Correctness and security | Functional correctness, data handling, validation, error paths, obvious security issues |
| Tests and production readiness | Test adequacy, backward compatibility, observability, rollout safety |

## Invocation

Prefer command wrappers that resolve the shared runner from the installed plugin root. If invoking the runner directly, resolve it before switching to the target repository:

```bash
CODING_PLUGIN_ROOT="/absolute/path/to/coding-plugin"
REVIEW_RUNNER="$(realpath "$CODING_PLUGIN_ROOT/skills/_review-libs/run-review.sh")"
bash "$REVIEW_RUNNER" --mode code-impl --host claude
bash "$REVIEW_RUNNER" --mode code-impl --host codex
```

- add `--plan <path>` when an implementation plan baseline exists
- add `--reviewer <name>` to override the default opposite-model selection
- The shared runner enforces cross-tool execution and workspace isolation centrally
- Do not invoke `skills/_review-libs/run-review.sh` as a target-repository relative path

## Output Schema

Structured JSON schema is bundled under the coding plugin root at `skills/_review-libs/schemas/adversarial-reviewer-output.schema.json`. Resolve it to an absolute path before passing it to CLIs that run with the target repository as cwd.

## References

- [Workflow Details](references/workflow-details.md) - Full workflow steps, scope collection, constraints
- [Evidence Contracts](references/evidence-contracts.md) - Required fields, PASS criteria
- [Security Rules](references/security-rules.md) - Workspace isolation, path validation

## Compact Instructions

Preserve: trigger conditions, concern names, shim path.
Drop: examples, error details, security specifics (recoverable from references/).
