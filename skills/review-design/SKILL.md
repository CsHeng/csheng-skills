---
name: review-design
description: "Use for same-model review of design docs, architecture decisions, goals and non-goals, boundaries, risks, and acceptance criteria; cross/adversarial review is explicit opt-in."
---

# Review Design

Review a design document with a same-model workflow by default:
- The primary review uses the same reviewer driver as the host unless the user explicitly requests `cross`, `cross-model`, or `adversarial` review.
- Opposite-driver review is opt-in and must be reflected by `--cross-model` or `--adversarial`.
- Default reviewer model targets are `gpt-5.4` for Codex, `claude-opus-4-6` for Claude, and `gemini-3.1-pro-preview` for Gemini.
- Default reviewer timeout is `1800` seconds per invocation.
- Design docs intended for downstream plan/code review should declare `## Implementation Surface` with `impl_file_refs` and `test_file_refs`.
- The reviewer covers goals, non-goals, boundaries, architecture, risks, and acceptance criteria in one structured pass.
- The host agent owns the repair loop and final stop/go decision.
- Repair rounds stop after 3 rounds and require explicit human approval before starting another batch.

## Modes

- `review-only`: produce findings and verdict, do not edit the design
- `repair-review`: the host agent fixes only Critical/Important findings with `scope_class: in_scope_blocking` and reruns fresh review up to 3 rounds per batch
- command wrappers should default to `review-only`; `repair-review` is explicit opt-in

## Inputs

- Design file path: caller-specified (required)
- Implementation surface refs inside the design: `## Implementation Surface` with `impl_file_refs` and `test_file_refs` for downstream artifact-DAG linkage
- User intent and acceptance criteria: caller prompt and any linked docs (required)
- Project context: `AGENTS.md` or `CLAUDE.md` if present, plus nearby docs only as needed

## Review Concerns

| Concern | Focus |
|---------|-------|
| Goals and scope | Missing goals, unclear non-goals, scope leaks, requirement ambiguity |
| Architecture and boundaries | Ownership, layering, dependency direction, interface boundaries |
| Risks and operability | Rollout, rollback, failure modes, observability, verification |

## Invocation

Prefer command wrappers that resolve the shared runner from the installed plugin root. If invoking the runner directly, resolve it before switching to the target repository:

```bash
CODING_PLUGIN_ROOT="/absolute/path/to/coding-plugin"
DESIGN_PATH="/absolute/path/to/design.md"
REVIEW_RUNNER="$(realpath "$CODING_PLUGIN_ROOT/skills/_review-libs/run-review.sh")"
bash "$REVIEW_RUNNER" --mode design --host claude --plan "$DESIGN_PATH"
bash "$REVIEW_RUNNER" --mode design --host codex --plan "$DESIGN_PATH"
```

- Add `--reviewer <name>` to override the reviewer driver within the selected strategy
- Add `--cross-model` or `--adversarial` only when the user explicitly requests cross/adversarial review
- The shared runner enforces reviewer selection and workspace isolation centrally
- Do not invoke `skills/_review-libs/run-review.sh` as a target-repository relative path

## Output Schema

Structured JSON schema is bundled under the coding plugin root at `skills/_review-libs/schemas/adversarial-reviewer-output.schema.json`. Resolve it to an absolute path before passing it to CLIs that run with the target repository as cwd.

## References

- [Workflow Details](references/workflow-details.md) - Full workflow steps, constraints
- [Evidence Contracts](references/evidence-contracts.md) - Required fields, PASS criteria
- [Security Rules](references/security-rules.md) - Workspace isolation, path validation

## Compact Instructions

Preserve: trigger conditions, concern names, shim path.
Drop: examples, error details, security specifics (recoverable from references/).
