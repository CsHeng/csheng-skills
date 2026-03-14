---
name: review-impl
description: "Review code changes with adversarial cross-model review. Use an opposite coding CLI as the primary reviewer, split review across lenses, verify evidence, and synthesize with a lead judge. Supports review-only by default and optional repair rounds when the caller explicitly asks to fix the implementation. Activates for: review implementation, review code, code review, adversarial review, 审查实现, 代码审查。"
---

# Review Implementation

Review implementation changes with an adversarial workflow:
- The primary review must come from an opposite coding CLI when available.
- Multiple reviewer lenses challenge the implementation in parallel.
- A lead judge synthesizes findings and decides PASS or FAIL.
- The reviewer does not fix its own findings.
- Repair rounds are optional and only run when the caller explicitly asks to edit code.

## Modes

- `review-only` (default): produce findings and verdict, do not edit code
- `repair-review`: after a FAIL, the host agent may fix Critical/Important issues, then rerun fresh review up to 3 total rounds

## Inputs

- Review scope: auto-determine from git (required)
- Plan file path: caller-specified (optional but strongly preferred for spec compliance)
- User intent and acceptance criteria: caller prompt and linked docs
- Project context: `AGENTS.md` or `CLAUDE.md` if present

Collect scope with:

```bash
git status --short
git diff --stat
git diff
git diff --cached --stat
git diff --cached
```

## Reviewer Roles

- Opposite-model reviewers: primary source of challenge and findings
- Lead judge: consolidates reviewer outputs, removes duplicates, verifies evidence completeness, decides PASS/FAIL
- Fixer: only in `repair-review`; applies fixes after the judge issues FAIL

## Review Lenses

Run at least these three lenses:

| Lens | Focus |
|------|-------|
| Spec compliance | Match against plan or stated intent, detect missing features and unapproved extras |
| Correctness and security | Functional correctness, data handling, validation, error paths, obvious security issues |
| Tests and production readiness | Test adequacy, migrations, backward compatibility, observability, rollout safety |

## Evidence Contract

Every Critical or Important finding must include:
- `severity`: `Critical` or `Important`
- `location`: concrete `file:line` or closest available file reference
- `evidence`: brief code-based explanation grounded in the diff or file contents
- `impact`: user-visible, operational, or security consequence
- `fix`: the smallest viable correction
- `confidence`: `high`, `medium`, or `low`

Minor findings should use the same field shape as other findings, including `confidence`, so reviewer output stays schema-compatible.

A PASS verdict is invalid unless:
- all reviewer outputs were collected
- no Critical or Important issues remain
- the lead judge provides a short pass rationale grounded in the actual changes

## Structured Reviewer Output

Each reviewer must return a structured result equivalent to:

```json
{
  "lens": "correctness-security",
  "verdict": "FAIL",
  "summary": "Short technical assessment.",
  "findings": [
    {
      "severity": "Critical",
      "location": "src/api/server.ts:84",
      "evidence": "The new handler trusts user-provided path segments and forwards them directly to the shell command.",
      "impact": "This creates command-injection risk for production requests.",
      "fix": "Replace shell interpolation with argument arrays or strict allow-list validation.",
      "confidence": "high"
    }
  ],
  "pass_rationale": "Only required when verdict is PASS"
}
```

## Workflow

1. Collect review scope from git and identify changed files.
2. If no relevant changes are present, stop and report that review scope is empty.
3. If a plan is provided, read it and extract the implementation baseline:
   - required behavior
   - non-goals
   - constraints
   - acceptance criteria
4. If no plan is provided, extract intent from the caller prompt and changed files, then report `spec baseline: inferred` in the final summary.
5. Read only the changed files plus the minimum supporting context needed to understand them.
6. Prefer the script entrypoint when it is available:
   - `scripts/run-review.sh --mode impl --host claude` from Claude
   - `scripts/run-review.sh --mode impl --host codex` from Codex
   - add `--plan <path>` when a plan baseline exists
   - add `--reviewer <name>` to override the default opposite-model selection
   - the script must own reviewer selection so cross-tool execution is enforced instead of implied
7. If the script is unavailable, select the primary reviewer CLI manually:
   - If the current host can invoke `codex` and the active session is not already a Codex-hosted review, prefer `codex exec` or `codex review`
   - If the current host can invoke `claude` and the active session is not already a Claude-hosted review, prefer `claude -p`
   - Detect the opposite reviewer by checking CLI availability first (`command -v codex`, `command -v claude`) and then preferring the CLI that is different from the current host
   - If the opposite CLI is unavailable, continue with `same-model fallback` and report that explicitly in the final result
8. Verify or create an isolated reviewer workspace before invoking the opposite model:
   - canonicalize the workspace root with `realpath`
   - ensure it contains only the files under review and required local context
   - reject the workspace if it contains secrets, credentials, private keys, `.env` files, or unrelated source trees
   - if the current workspace is not isolated, create a temporary worktree or temporary directory containing only the review scope and required context
9. Create a temporary review packet containing:
   - changed files
   - git status and diff summary
   - plan baseline or inferred intent
   - relevant project context
   - lens-specific instructions
   - required output schema
10. Run the lens reviewers with the opposite CLI, preferably in parallel.
11. Verify reviewer outputs before synthesis:
   - each lens produced output
   - each Critical/Important finding includes location, evidence, impact, fix, and confidence
   - empty output is treated as reviewer failure, not PASS
12. Lead judge synthesis:
   - merge duplicate findings
   - downgrade unsupported claims
   - reject findings without concrete evidence
   - decide PASS or FAIL
13. If mode is `review-only`, stop after the lead judge report.
14. If mode is `repair-review` and verdict is FAIL:
   - the host agent may edit code to fix only Critical/Important issues
   - rerun fresh opposite-model review
   - stop after PASS or 3 total rounds
15. If unresolved Critical/Important issues remain after round 3, return FAIL with the unresolved checklist.

## Security Requirements

- Run opposite-model reviewers only from an isolated workspace, such as a temporary worktree or CI checkout that contains only the files under review and required local context.
- The isolated workspace must not contain secrets, credentials, private keys, `.env` files, production configs, or unrelated source trees.
- Validate caller-provided plan paths before generating prompt files.
- Keep prompt-file generation static in examples; do not teach shell interpolation of caller input in the example commands.
- Canonicalize all file and workspace paths with `realpath` before use and reject any path that resolves outside the isolated workspace or other explicitly allowed roots.
- In automation, invoke reviewer CLIs with argument arrays in the host language runtime. Do not build shell command strings from untrusted input.

## CLI Guidance

Use the opposite coding CLI non-interactively and require structured output.

The examples below use fixed literal paths. In real orchestration, treat those paths as already-validated trusted values and pass reviewer arguments as argv arrays from the host runtime instead of constructing shell strings.

### Claude host -> Codex reviewer

Prefer `codex exec` with the shared schema at `docs/schemas/adversarial-reviewer-output.schema.json` when you need lens-specific review output. Prefer `codex review --uncommitted` for an additional holistic pass after the lens reviews.

```bash
cat > /tmp/review-impl.prompt <<'EOF'
Review the current changes using the spec-compliance lens only.
Return structured JSON matching the shared reviewer schema.
EOF

codex exec \
  -C /absolute/path/to/repo \
  -s read-only \
  --output-schema "docs/schemas/adversarial-reviewer-output.schema.json" \
  -o /tmp/review-impl-spec.json \
  - < /tmp/review-impl.prompt
```

### Codex host -> Claude reviewer

Prefer `claude -p` with the same shared schema and the same prompt file:

```bash
claude -p \
  --tools Read,Glob,Grep,Bash \
  --json-schema "$(cat docs/schemas/adversarial-reviewer-output.schema.json)" \
  < /tmp/review-impl.prompt
```

`codex exec -s read-only` prevents writes but still allows the reviewer to read files inside the specified workspace. This is why workspace isolation is mandatory.

If plan context is needed, have the orchestrator write a separate prompt file with a validated canonical absolute path already substituted by the host language runtime. Do not construct shell commands by interpolating untrusted path input.

Use equivalent commands for the other lenses.

## Output Format

For each invocation, return only the lead judge result.

### Review Mode
- `cross-model`
- `same-model fallback`

### Scope Summary
- Changed files reviewed
- Spec baseline: `plan` | `inferred`
- Review round `N/3`
- `Verdict: PASS | FAIL`
- `Code modified: yes | no`

### Findings

#### Critical (Must Fix)
- `[file:line]` issue
  Evidence: ...
  Impact: ...
  Fix: ...
  Confidence: ...

#### Important (Should Fix)
- `[file:line]` issue
  Evidence: ...
  Impact: ...
  Fix: ...
  Confidence: ...

#### Minor (Nice to Have)
- `[file:line]` issue

### Judge Summary
- Reviewer lenses used
- Reviewer CLI used
- Evidence completeness: `complete | incomplete`
- Pass rationale or fail rationale in 1-3 sentences

## Constraints

- Do not let the same reviewer both raise findings and clear them.
- Do not edit code in `review-only` mode.
- Review the changed scope, not the entire codebase, unless a changed boundary clearly requires adjacent context.
- Do not mark PASS if any reviewer output is missing.
- Minor findings never block PASS.
