---
name: review-impl
description: "Review code implementation against plan for spec compliance, code quality, architecture, testing, security, and production readiness. Uses git diff/status for scope. Supports iterative multi-round review (max 5 rounds). Activates for: review implementation, review code, code review, 审查实现, 代码审查。"
---

# Review Implementation

Review code changes against an implementation plan (if provided) and general quality standards. Iteratively identify issues, fix them, and re-review until acceptance criteria are met or the round limit is reached.

## Input

- Plan file path: user-specified (optional, enables spec compliance checking)
- Review scope: auto-determined via git

```bash
git status --short
git diff --stat
git diff
git diff --cached --stat
git diff --cached
```

- Project context: auto-discover AGENTS.md or CLAUDE.md

## Workflow

1. Run git status/diff to determine changed files and scope
2. If plan path provided, read the plan for spec compliance baseline
3. Read project context (AGENTS.md or CLAUDE.md if present)
4. Read all changed files
5. Review against all dimensions below
6. Output structured report
7. Enter review loop if verdict is FAIL

## Review Dimensions

| Dimension | Checks |
|-----------|--------|
| Spec compliance | Implementation matches plan, no missing features, no unneeded extras (skip if no plan provided) |
| Code quality | Naming, structure, DRY, error handling, type safety |
| Architecture | Separation of concerns, coupling, SOLID, design patterns |
| Testing | Coverage, edge cases, tests verify real logic (not mocks) |
| Security | Input validation, injection risks, credential leaks, OWASP top 10 |
| Performance | Obvious perf issues, resource leaks, N+1 queries |
| Production readiness | Backward compatibility, migration strategy, documentation completeness |

## Output Format

For each review round, produce:

### Review Round N/5

#### Issues

##### Critical (Must Fix)
- [file:line] description + reason + fix suggestion

##### Important (Should Fix)
- [file:line] description + reason + fix suggestion

##### Minor (Nice to Have)
- [file:line] description

#### Verdict: PASS / FAIL
Reasoning: [1-2 sentence technical assessment]

## Review Loop Protocol

Maximum 5 rounds per invocation.

### Round flow

```
Round N (N=1..5):
  1. Collect git diff (re-run each round to capture fixes)
  2. Review against all dimensions
  3. Output structured report
  4. Verdict:
     ├─ PASS (no Critical/Important) → exit loop, output final summary
     ├─ FAIL + N<5 → fix Critical and Important issues in code → round N+1
     └─ FAIL + N=5 → escalate to user with unresolved issues list
```

### Inter-round constraints

- Each subsequent round focuses on whether previous round's issues are resolved
- New Critical/Important issues in later rounds only allowed if the fix introduced a new bug
- Minor issues never block PASS verdict

### Escalation (Round 5 FAIL)

Output all unresolved issues. State clearly that automated review could not resolve them. Present remaining issue checklist for user intervention.

## Constraints

- Do not modify code until after the first review round produces a FAIL verdict
- Review what was changed, not the entire codebase
- YAGNI — flag over-engineering, do not add requirements
- Do not re-review dimensions unrelated to the fixes made between rounds
