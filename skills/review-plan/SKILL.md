---
name: review-plan
description: "Review an implementation plan with adversarial cross-model review. Use an opposite coding CLI as the primary reviewer, split review across lenses, verify evidence, and synthesize with a lead judge. Supports review-only by default and optional repair rounds when the caller explicitly asks to fix the plan. Activates for: review plan, check plan, plan review, adversarial review, 审查计划, 检查方案。"
---

# Review Plan

Review an implementation plan with an adversarial workflow:
- The primary review must come from an opposite coding CLI when available.
- Multiple reviewer lenses challenge the plan in parallel.
- A lead judge synthesizes findings and decides PASS or FAIL.
- The reviewer does not fix its own findings.
- Repair rounds are optional and only run when the caller explicitly asks to edit the plan.

## Modes

- `review-only` (default): produce findings and verdict, do not edit the plan
- `repair-review`: after a FAIL, the host agent may fix Critical/Important issues, then rerun fresh review up to 3 total rounds

## Inputs

- Plan file path: caller-specified (required)
- User intent: caller prompt and any acceptance criteria (required)
- Project context: `AGENTS.md` or `CLAUDE.md` if present, plus relevant repo structure

## Reviewer Roles

- Opposite-model reviewers: primary source of challenge and findings
- Lead judge: consolidates reviewer outputs, removes duplicates, verifies evidence completeness, decides PASS/FAIL
- Fixer: only in `repair-review`; applies fixes after the judge issues FAIL

## Review Lenses

Run at least these three lenses:

| Lens | Focus |
|------|-------|
| Requirements and risk | Missing scope, unclear success criteria, rollout/rollback, operational risk |
| Architecture and dependencies | Layering, ownership, sequencing, coupling, dependency ordering |
| Test strategy and operations | Test pyramid fit, acceptance criteria, observability, deployment/verification |

## Evidence Contract

Every Critical or Important finding must include:
- `severity`: `Critical` or `Important`
- `location`: concrete section, heading, or paragraph reference in the plan
- `evidence`: brief quote or paraphrase tied to the plan text
- `impact`: why this could fail in implementation or rollout
- `fix`: the smallest viable change to correct it
- `confidence`: `high`, `medium`, or `low`

Minor findings should use the same field shape as other findings, including `confidence`, so reviewer output stays schema-compatible.

A PASS verdict is invalid unless:
- all reviewer outputs were collected
- no Critical or Important issues remain
- the lead judge provides a short pass rationale grounded in the plan

## Structured Reviewer Output

Each reviewer must return a structured result equivalent to:

```json
{
  "lens": "requirements-risk",
  "verdict": "PASS",
  "summary": "Short technical assessment.",
  "findings": [
    {
      "severity": "Important",
      "location": "Task 2 / Step 3",
      "evidence": "Plan updates schema but omits migration rollback.",
      "impact": "Rollback would require manual repair during deployment.",
      "fix": "Add a rollback step and ownership for reversal.",
      "confidence": "high"
    }
  ],
  "pass_rationale": "Only required when verdict is PASS"
}
```

## Workflow

1. Read the specified plan file.
2. Read relevant project context (`AGENTS.md` or `CLAUDE.md` if present, plus nearby docs only as needed).
3. Extract the review baseline before judging:
   - stated goal
   - non-goals or scope limits
   - deliverables
   - constraints
   - acceptance criteria
4. Prefer the script entrypoint when it is available:
   - `scripts/run-review.sh --mode plan --host claude --plan <path>` from Claude
   - `scripts/run-review.sh --mode plan --host codex --plan <path>` from Codex
   - Add `--reviewer <name>` to override the default opposite-model selection
   - The script must own reviewer selection so cross-tool execution is enforced instead of implied
5. If the script is unavailable, select the primary reviewer CLI manually:
   - If running inside Claude, prefer `codex exec`
   - If running inside Codex, prefer `claude -p`
   - If the opposite CLI is unavailable, continue with `same-model fallback` and report that explicitly in the final result
6. Create a temporary review packet containing:
   - plan path
   - extracted baseline
   - relevant project context
   - lens-specific instructions
   - required output schema
7. Run the lens reviewers with the opposite CLI, preferably in parallel.
8. Verify reviewer outputs before synthesis:
   - each lens produced output
   - each Critical/Important finding includes evidence, impact, fix, and confidence
   - empty output is treated as reviewer failure, not PASS
9. Lead judge synthesis:
   - merge duplicate findings
   - downgrade unsupported claims
   - reject findings without concrete evidence
   - decide PASS or FAIL
10. If mode is `review-only`, stop after the lead judge report.
11. If mode is `repair-review` and verdict is FAIL:
   - the host agent may edit the plan to fix only Critical/Important issues
   - rerun fresh opposite-model review
   - stop after PASS or 3 total rounds
12. If unresolved Critical/Important issues remain after round 3, return FAIL with the unresolved checklist.

## Security Requirements

- Run opposite-model reviewers only from an isolated workspace, such as a temporary worktree or CI checkout that contains only the files under review.
- Validate caller-provided paths before generating prompt files.
- Keep prompt-file generation static in examples; let automation substitute concrete paths safely before execution.

## CLI Guidance

Use the opposite coding CLI non-interactively and require structured output.

### Claude host -> Codex reviewer

Prefer `codex exec` with the shared schema at `docs/schemas/adversarial-reviewer-output.schema.json` and a prompt file passed on stdin:

```bash
printf '%s\n' \
  'Review the plan at "/absolute/path/to/plan.md" using the requirements-risk lens only.' \
  'Return structured JSON matching the shared reviewer schema.' \
  > /tmp/review-plan.prompt

codex exec \
  -C /absolute/path/to/repo \
  -s read-only \
  --skip-git-repo-check \
  --output-schema "docs/schemas/adversarial-reviewer-output.schema.json" \
  -o /tmp/review-plan-requirements.json \
  - < /tmp/review-plan.prompt
```

### Codex host -> Claude reviewer

Prefer `claude -p` with the same shared schema and the same prompt file:

```bash
claude -p \
  --tools Read,Glob,Grep,Bash \
  --json-schema "$(cat docs/schemas/adversarial-reviewer-output.schema.json)" \
  < /tmp/review-plan.prompt
```

Use a concrete plan path in the prompt file. In automation, have the orchestrator write the prompt file with the real path already substituted instead of generating shell commands by interpolating untrusted path input.

Use equivalent commands for the other lenses.

## Output Format

For each invocation, return only the lead judge result.

### Review Mode
- `cross-model`
- `same-model fallback`

### Round Result
- `Review round N/3`
- `Verdict: PASS | FAIL`
- `Plan modified: yes | no`

### Findings

#### Critical (Must Fix)
- `[location]` issue
  Evidence: ...
  Impact: ...
  Fix: ...
  Confidence: ...

#### Important (Should Fix)
- `[location]` issue
  Evidence: ...
  Impact: ...
  Fix: ...
  Confidence: ...

#### Minor (Nice to Have)
- `[location]` issue

### Judge Summary
- Reviewer lenses used
- Reviewer CLI used
- Evidence completeness: `complete | incomplete`
- Pass rationale or fail rationale in 1-3 sentences

## Constraints

- Do not let the same reviewer both raise findings and clear them.
- Do not edit the plan in `review-only` mode.
- Do not introduce new product scope while fixing the plan.
- Do not mark PASS if any reviewer output is missing.
- Minor findings never block PASS.
