---
name: review-design
description: "Review design documents with cross-model review. Use an opposite coding CLI as the primary reviewer, focus on goals, boundaries, architecture, and risks, and support opt-in host-driven repair batches with explicit human approval after 3 failed rounds. Activates for: review design, design review, architecture review, 审查设计, 设计审查。"
---

# Review Design

Review a design document with a cross-model workflow:
- The primary review must come from an opposite coding CLI when available.
- Default reviewer model targets are `gpt-5.4` for Codex, `claude-opus-4-6` for Claude, and `gemini-3.1-pro-preview` for Gemini.
- Default reviewer timeout is `1800` seconds per invocation.
- The reviewer covers goals, non-goals, boundaries, architecture, risks, and acceptance criteria in one structured pass.
- The host agent owns the repair loop and final stop/go decision.
- Repair rounds stop after 3 rounds and require explicit human approval before starting another batch.

## Modes

- `review-only`: produce findings and verdict, do not edit the design
- `repair-review`: the host agent fixes Critical/Important issues and reruns fresh review up to 3 rounds per batch
- command wrappers should default to `review-only`; `repair-review` is explicit opt-in

## Inputs

- Design file path: caller-specified (required)
- User intent and acceptance criteria: caller prompt and any linked docs (required)
- Project context: `AGENTS.md` or `CLAUDE.md` if present, plus nearby docs only as needed

## Review Concerns

| Concern | Focus |
|---------|-------|
| Goals and scope | Missing goals, unclear non-goals, scope leaks, requirement ambiguity |
| Architecture and boundaries | Ownership, layering, dependency direction, interface boundaries |
| Risks and operability | Rollout, rollback, failure modes, observability, verification |

## Invocation

Prefer the skill-local wrapper entrypoint:
- `skills/review-design/scripts/run-review.sh --host claude --plan <path>` from Claude
- `skills/review-design/scripts/run-review.sh --host codex --plan <path>` from Codex
- Add `--reviewer <name>` to override the default opposite-model selection
- The wrapper delegates to `skills/_review-libs/` for cross-tool execution and workspace isolation

## Output Schema

Structured JSON at `skills/_review-libs/schemas/adversarial-reviewer-output.schema.json`

## References

- [Workflow Details](references/workflow-details.md) - Full workflow steps, constraints
- [Evidence Contracts](references/evidence-contracts.md) - Required fields, PASS criteria
- [Security Rules](references/security-rules.md) - Workspace isolation, path validation

## Compact Instructions

Preserve: trigger conditions, concern names, shim path.
Drop: examples, error details, security specifics (recoverable from references/).
