---
name: review-code-impl
description: "Review code implementation with cross-model review. Use an opposite coding CLI as the primary reviewer, take an implementation plan as the initial baseline, and support opt-in host-driven repair batches with explicit human approval after 3 failed rounds. Activates for: review code implementation, review code impl, review implementation code, code fix loop, 审查代码实现, 审查实现代码。"
---

# Review Code Implementation

Review code implementation changes against an implementation plan with a cross-model workflow:
- The primary review must come from an opposite coding CLI when available.
- Default reviewer model targets are `gpt-5.4` for Codex, `claude-opus-4-6` for Claude, and `gemini-3.1-pro-preview` for Gemini.
- Default reviewer timeout is `1800` seconds per invocation.
- Reviewer execution modes are read-only sandbox for Codex, plan/read-only for Claude, and `--approval-mode yolo` for Gemini inside the isolated review workspace.
- The implementation plan passed by `--plan` is the fixed initial baseline for the repair loop.
- The reviewer covers spec compliance, correctness, security, testing, and production-readiness in one structured pass.
- The host agent owns the repair loop and final stop/go decision.
- Repair rounds stop after 3 rounds and require explicit human approval before starting another batch.

## Modes

- `review-only`: produce findings and verdict, do not edit code
- `repair-review`: the host agent fixes Critical/Important issues and reruns fresh review up to 3 rounds per batch
- command wrappers should default to `review-only`; `repair-review` is explicit opt-in

## Inputs

- Review scope: auto-determine from git or explicit file list (required)
- Implementation plan path: caller-specified and strongly recommended as the baseline
- User intent and acceptance criteria: caller prompt and linked docs
- Project context: `AGENTS.md` or `CLAUDE.md` if present

## Review Concerns

| Concern | Focus |
|---------|-------|
| Spec compliance | Match against the implementation plan or stated intent, detect missing features and unapproved extras |
| Correctness and security | Functional correctness, data handling, validation, error paths, obvious security issues |
| Tests and production readiness | Test adequacy, backward compatibility, observability, rollout safety |

## Invocation

Prefer the skill-local wrapper entrypoint:
- `skills/review-code-impl/scripts/run-review.sh --host claude` from Claude
- `skills/review-code-impl/scripts/run-review.sh --host codex` from Codex
- add `--plan <path>` when an implementation plan baseline exists
- add `--reviewer <name>` to override the default opposite-model selection
- The wrapper delegates to `skills/_review-libs/` for cross-tool execution and workspace isolation

## Output Schema

Structured JSON at `docs/schemas/adversarial-reviewer-output.schema.json`

## References

- [Workflow Details](references/workflow-details.md) - Full workflow steps, scope collection, constraints
- [Evidence Contracts](references/evidence-contracts.md) - Required fields, PASS criteria
- [Security Rules](references/security-rules.md) - Workspace isolation, path validation

## Compact Instructions

Preserve: trigger conditions, concern names, shim path.
Drop: examples, error details, security specifics (recoverable from references/).
