---
name: review-plan
description: "Review an implementation plan with cross-model review. Use an opposite coding CLI as the primary reviewer, return structured evidence, and support host-driven repair batches with explicit human approval after 3 failed rounds. Activates for: review plan, check implementation plan, implementation plan review, 审查实现计划, 审查计划。"
---

# Review Implementation Plan

Review an implementation plan with a cross-model workflow:
- The primary review must come from an opposite coding CLI when available.
- Default reviewer model targets are `gpt-5.4` for Codex, `claude-opus-4-6` for Claude, and `gemini-3.1-pro-preview` for Gemini.
- Default reviewer timeout is `1800` seconds per invocation.
- The reviewer covers requirements, architecture, testing, and operations in one structured pass.
- The host agent owns the repair loop and final stop/go decision.
- Repair rounds stop after 3 rounds and require explicit human approval before starting another batch.

## Modes

- `review-only`: produce findings and verdict, do not edit the plan
- `repair-review`: the host agent fixes Critical/Important issues and reruns fresh review up to 3 rounds per batch
- command wrappers should default to `review-only`; `repair-review` is explicit opt-in

## Inputs

- Plan file path: caller-specified (required)
- User intent: caller prompt and any acceptance criteria (required)
- Project context: `AGENTS.md` or `CLAUDE.md` if present, plus relevant repo structure

## Review Lenses

| Lens | Focus |
|------|-------|
| Requirements and risk | Missing scope, unclear success criteria, rollout/rollback, operational risk |
| Architecture and dependencies | Layering, ownership, sequencing, coupling, dependency ordering |
| Test strategy and operations | Test pyramid fit, acceptance criteria, observability, deployment/verification |

## Invocation

Prefer the skill-local wrapper entrypoint:
- `skills/review-plan/scripts/run-review.sh --host claude --plan <path>` from Claude
- `skills/review-plan/scripts/run-review.sh --host codex --plan <path>` from Codex
- Add `--reviewer <name>` to override the default opposite-model selection
- The wrapper delegates to `skills/_review-libs/` for cross-tool execution and workspace isolation

## Output Schema

Structured JSON at `skills/_review-libs/schemas/adversarial-reviewer-output.schema.json`

## References

- [Workflow Details](references/workflow-details.md) - Full workflow steps, output format, constraints
- [CLI Examples](references/cli-examples.md) - Direct CLI invocation patterns
- [Evidence Contracts](references/evidence-contracts.md) - Required fields, PASS criteria, structured output
- [Security Rules](references/security-rules.md) - Workspace isolation, path validation

## Compact Instructions

Preserve: trigger conditions, lens names, shim path.
Drop: examples, error details, security specifics (recoverable from references/).
