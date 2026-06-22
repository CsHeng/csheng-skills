---
name: review-plan
description: "Use for same-model review of implementation plans: task order, dependencies, test coverage, rollback, and operational readiness; cross/adversarial review is explicit opt-in."
---

# Review Implementation Plan

Review an implementation plan with a same-model workflow by default:
- The primary review uses the same reviewer driver as the host unless the user explicitly requests `cross`, `cross-model`, or `adversarial` review.
- Opposite-driver review is opt-in and must be reflected by `--cross-model` or `--adversarial`.
- Default reviewer model targets are `gpt-5.4` for Codex, `claude-opus-4-6` for Claude, and `gemini-3.1-pro-preview` for Gemini.
- Default reviewer timeout is `1800` seconds per invocation.
- The plan is artifact-DAG-linked to an upstream design: `design_ref is required`, `design_version` is required, and the runner loads that design first before judging the plan.
- The plan's `Implementation Scope` must stay within the upstream design's `Implementation Surface`.
- The reviewer covers requirements, architecture, testing, and operations in one structured pass.
- The host agent owns the repair loop and final stop/go decision.
- Repair rounds stop after 3 rounds and require explicit human approval before starting another batch.

## Modes

- `review-only`: produce findings and verdict, do not edit the plan
- `repair-review`: the host agent fixes only Critical/Important findings with `scope_class: in_scope_blocking` and reruns fresh review up to 3 rounds per batch
- command wrappers should default to `review-only`; `repair-review` is explicit opt-in

## Inputs

- Plan file path: caller-specified (required)
- Upstream design linkage inside the plan: `## Upstream Design` with `design_ref` and `design_version` (required)
- User intent: caller prompt and any acceptance criteria (required)
- Project context: `AGENTS.md` or `CLAUDE.md` if present, plus relevant repo structure

## Review Lenses

| Lens | Focus |
|------|-------|
| Requirements and risk | Missing scope, unclear success criteria, rollout/rollback, operational risk |
| Architecture and dependencies | Layering, ownership, sequencing, coupling, dependency ordering |
| Test strategy and operations | Test pyramid fit, acceptance criteria, observability, deployment/verification |

## Invocation

Prefer command wrappers that resolve the shared runner from the installed plugin root. If invoking the runner directly, resolve it before switching to the target repository:

```bash
CODING_PLUGIN_ROOT="/absolute/path/to/coding-plugin"
PLAN_PATH="/absolute/path/to/plan.md"
REVIEW_RUNNER="$(realpath "$CODING_PLUGIN_ROOT/skills/_review-libs/run-review.sh")"
bash "$REVIEW_RUNNER" --mode plan --host claude --plan "$PLAN_PATH"
bash "$REVIEW_RUNNER" --mode plan --host codex --plan "$PLAN_PATH"
```

- Add `--reviewer <name>` to override the reviewer driver within the selected strategy
- Add `--cross-model` or `--adversarial` only when the user explicitly requests cross/adversarial review
- The shared runner enforces reviewer selection and workspace isolation centrally
- Do not invoke `skills/_review-libs/run-review.sh` as a target-repository relative path

## Output Schema

Structured JSON schema is bundled under the coding plugin root at `skills/_review-libs/schemas/adversarial-reviewer-output.schema.json`. Resolve it to an absolute path before passing it to CLIs that run with the target repository as cwd.

## References

- [Workflow Details](references/workflow-details.md) - Full workflow steps, output format, constraints
- [CLI Examples](references/cli-examples.md) - Direct CLI invocation patterns
- [Evidence Contracts](references/evidence-contracts.md) - Required fields, PASS criteria, structured output
- [Security Rules](references/security-rules.md) - Workspace isolation, path validation

## Compact Instructions

Preserve: trigger conditions, lens names, shim path.
Drop: examples, error details, security specifics (recoverable from references/).
