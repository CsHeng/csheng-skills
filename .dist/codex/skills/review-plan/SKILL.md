---
name: review-plan
description: "Use for same-driver review of implementation plans: task order, dependencies, test coverage, rollback, and operational readiness."
---

# Review Implementation Plan

Review an implementation plan with a same-driver workflow:
- The reviewer driver must match the current host.
- The skills layer does not spawn, select, or arbitrate between different LLM providers.
- External review reports may be attached as passive evidence, but they do not replace local artifact review.
- Default reviewer timeout is `1800` seconds per invocation.
- The plan is artifact-DAG-linked to an upstream design: `design_ref is required`, `design_version` is required, and the runner loads that design first before judging the plan.
- The plan's `Implementation Scope` must stay within the upstream design's `Implementation Surface`.
- The reviewer covers requirements, architecture, testing, and operations in one structured pass.
- Default plan review depth is `boundary`: judge whether the plan can safely enter execution, not whether every implementation detail has been specified.
- The host agent owns the repair loop and final stop/go decision.
- Default plan repair stops after 1 round; deeper rounds require explicit harness-maintainer override.
- Plan review has a default budget of 2 batches total. A third batch requires an explicit harness override, not ordinary "go fix and review again" approval.
- The reviewer must judge the current milestone, not force full future-phase closure into the active plan.

## Modes

- `review-only`: produce findings and verdict, do not edit the plan
- `repair-review`: the host agent fixes only Critical/Important findings with `scope_class: in_scope_blocking` and reruns fresh review within the plan review budget
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

## Readiness And Finding Semantics

Review `## Work Package Readiness` before judging task details.

Map decision semantics onto the existing `scope_class` field:
- `in_scope_blocking`: must fix within the current milestone and review budget
- `baseline_mismatch`: needs upstream design decision or approved baseline correction
- `adjacent_debt`: real issue, but defer to future phase
- `out_of_dag_issue`: scope escaped the approved plan/design DAG and must stop for split/re-scope
- `external_verification_failure`: required evidence depends on a runtime or external surface and must stop for manual/probe decision

Treat a missing executable oracle strategy as blocking only when the task changes durable behavior, architecture, runtime semantics, security boundary, or compatibility. For docs-only, exploratory, or manual-evidence-only tasks, require the plan to say that explicitly.

If most findings are future-phase, baseline, or out-of-DAG issues, return manual decision instead of converting them into current-plan repairs.

Critical/Important findings in plan review are only for current-milestone blockers:
- unexecutable DAG or missing dependency edge
- scope outside the upstream design
- missing executable oracle for a behavior-changing task
- rollback/approval/readiness gap that prevents execution
- ownership or production-boundary conflict
- hidden confirmation or live-risk gate that would interrupt execution but is absent from `## Execution Continuity`
- `execution_continuity: continuous_after_plan_approval` while unresolved confirmations remain
- high-risk, live, destructive, or external-dependency tasks ordered before lower-risk independent work without a stated prerequisite reason

Do not block a plan for exact command flags, field-level parity tables, fixture contents, dashboard panel lists, cleanup polish, or code-level implementation risks unless the missing detail makes the current DAG, oracle, ownership, or rollback boundary unreviewable. Put those concerns into execution notes or Minor `adjacent_debt` findings.

## Execution Continuity Review

Plan review should protect uninterrupted execution after approval.

Require new plans to make known execution interruptions explicit in `## Execution Continuity`:
- `confirmation_clearance`: known user decisions and pre-confirmable live/destructive/external-dependency choices
- `runtime_contingencies`: execution-time surprises only
- `planned_stop_points`: normally empty; non-empty only when a known issue cannot be safely resolved during planning

Prefer plans that resolve known gates before approval. Do not ask for stop-after gates just to be cautious.

Block the plan if:
- known confirmations are hidden inside task prose instead of listed as `C*` clearance items
- unresolved confirmations exist but the plan claims continuous execution after approval
- `runtime_contingencies` contains known human decisions that should be pre-confirmed instead
- task ordering defers low-risk independent work behind a high-risk/live/destructive task without dependency justification
- the final planning summary does not tell the user whether approval authorizes continuous execution or names the remaining `C*` confirmations

## Invocation

Prefer command wrappers that resolve the shared runner from the installed plugin root. If invoking the runner directly, resolve it before switching to the target repository:

```bash
CODING_PLUGIN_ROOT="/absolute/path/to/coding-plugin"
PLAN_PATH="/absolute/path/to/plan.md"
REVIEW_RUNNER="$(realpath "$CODING_PLUGIN_ROOT/skills/_review-libs/run-review.sh")"
bash "$REVIEW_RUNNER" --mode plan --host claude --plan "$PLAN_PATH"
bash "$REVIEW_RUNNER" --mode plan --host codex --plan "$PLAN_PATH"
```

- The shared runner enforces same-driver selection and workspace isolation centrally
- `--depth auto` resolves to `boundary` for plan review; `--depth thorough` is a deliberate maintainer override, not the default
- Do not invoke `skills/_review-libs/run-review.sh` as a target-repository relative path

## Output Schema

Structured JSON schema is bundled under the coding plugin root at `skills/_review-libs/schemas/reviewer-output.schema.json`. Resolve it to an absolute path before passing it to CLIs that run with the target repository as cwd.

## References

- [Workflow Details](references/workflow-details.md) - Full workflow steps, output format, constraints
- [CLI Examples](references/cli-examples.md) - Direct CLI invocation patterns
- [Evidence Contracts](references/evidence-contracts.md) - Required fields, PASS criteria, structured output
- [Security Rules](references/security-rules.md) - Workspace isolation, path validation

## Compact Instructions

Preserve: trigger conditions, lens names, shim path.
Drop: examples, error details, security specifics (recoverable from references/).
