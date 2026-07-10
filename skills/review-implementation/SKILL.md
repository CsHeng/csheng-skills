---
name: review-implementation
description: "Review implementation code, diffs, fixes, or plan-bound changes with same-driver evidence. Use as the primary evaluation workflow when the user asks to check, inspect, or review an implementation, and combine it with matching language or domain policy skills such as Go or Shell guidelines. Return findings and a verdict only; lifecycle controllers own repairs."
---

# Review Implementation

Review code implementation changes against an implementation plan with a same-driver workflow:
- The reviewer driver must match the current host.
- The skills layer does not spawn, select, or arbitrate between different LLM providers.
- External review reports may be attached as passive evidence, but they do not replace local artifact review.
- Default reviewer timeout is `1800` seconds per invocation.
- Reviewer execution must stay inside the isolated review workspace created by the shared runner.
- For artifact-DAG fenced review, the runner loads the upstream design via the plan's `design_ref` and evaluates `design -> plan -> code`.
- The bounded repair surface is `.scope.allowed_touch_set`, derived as `plan.impl_file_refs + plan.test_file_refs`.
- The implementation plan passed by `--plan` is the fixed baseline for every review round.
- The reviewer covers spec compliance, correctness, security, testing, and production-readiness in one structured pass.
- Default code implementation review depth is `thorough`: code diff review is where implementation details, tests, exact behavior, and production-readiness defects should be strict.
- `implement-change` owns the repair loop and final stop/go decision when this review runs inside implementation delivery.
- Read-only review scope may expand to the relevant plan-bound design surface when needed for understanding.
- The reviewer never edits code, invokes `implement-change`, invokes `review-change`, or invokes itself.
- Round and prior-finding metadata are caller context, not lifecycle authority.

## Review Behavior

- Produce evidence-backed findings and one normalized verdict.
- Classify every Critical/Important finding with the existing scope classes.
- Direct user review stops after reporting the verdict.
- When called by `implement-change`, return `in_scope_blocking` findings for controller classification; do not apply them.
- Accept previous findings as context so a fresh review can determine whether evidence converged, repeated, or expanded.

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
- The shared runner enforces same-driver selection and workspace isolation centrally
- `--depth auto` resolves to `thorough` for code implementation review
- implementation review metadata defaults to the hard cap of 10 rounds; expected convergence remains 5 and the caller owns iteration
- Do not invoke `skills/_review-libs/run-review.sh` as a target-repository relative path

## Output Schema

Structured JSON schema is bundled under the coding plugin root at `skills/_review-libs/schemas/reviewer-output.schema.json`. Resolve it to an absolute path before passing it to CLIs that run with the target repository as cwd.

## References

- [Workflow Details](references/workflow-details.md) - Full workflow steps, scope collection, constraints
- [Evidence Contracts](references/evidence-contracts.md) - Required fields, PASS criteria
- [Security Rules](references/security-rules.md) - Workspace isolation, path validation

## Compact Instructions

Preserve: trigger conditions, concern names, shim path.
Drop: examples, error details, security specifics (recoverable from references/).
