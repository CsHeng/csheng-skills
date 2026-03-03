---
name: review-plan
description: "Review implementation plan for completeness, feasibility, risks, architecture, tech choices, dependencies, and test strategy. Supports iterative multi-round review (max 5 rounds). Activates for: review plan, check plan, plan review, 审查计划, 检查方案。"
---

# Review Plan

Review an implementation plan document against seven dimensions. Iteratively identify issues, fix them, and re-review until acceptance criteria are met or the round limit is reached.

## Input

- Plan file path: user-specified (required)
- Project context: auto-discover AGENTS.md or CLAUDE.md, scan directory structure

## Workflow

1. Read the specified plan file
2. Read project context (AGENTS.md or CLAUDE.md if present, directory structure via ls/tree)
3. Review against all dimensions below
4. Output structured report
5. Enter review loop if verdict is FAIL

## Review Dimensions

| Dimension | Checks |
|-----------|--------|
| Completeness | All requirements covered, no missing steps, boundary conditions considered |
| Feasibility | Steps executable, dependencies available, sequencing logical |
| Risk | Technical risk, integration risk, rollback plan, breaking changes |
| Architecture | Layering, responsibility separation, extensibility |
| Tech choices | Language/framework/tool selection, over-engineering detection |
| Dependencies | Task dependency correctness, circular dependency detection, parallelization opportunities |
| Test strategy | Coverage adequacy, test type matching, acceptance criteria clarity |

## Output Format

For each review round, produce:

### Review Round N/5

#### Issues

##### Critical (Must Fix)
- [location in plan] description + reason + fix suggestion

##### Important (Should Fix)
- [location in plan] description + reason + fix suggestion

##### Minor (Nice to Have)
- [location in plan] description

#### Verdict: PASS / FAIL
Reasoning: [1-2 sentence technical assessment]

## Review Loop Protocol

Maximum 5 rounds per invocation.

### Round flow

```
Round N (N=1..5):
  1. Review plan against all dimensions
  2. Output structured report
  3. Verdict:
     ├─ PASS (no Critical/Important) → exit loop, output final summary
     ├─ FAIL + N<5 → fix Critical and Important issues in plan → round N+1
     └─ FAIL + N=5 → escalate to user with unresolved issues list
```

### Inter-round constraints

- Each subsequent round focuses on whether previous round's issues are resolved
- New Critical/Important issues in later rounds only allowed if the fix introduced a new problem
- Minor issues never block PASS verdict

### Escalation (Round 5 FAIL)

Output all unresolved issues. State clearly that automated review could not resolve them. Present remaining issue checklist for user intervention.

## Constraints

- Do not modify the plan until after the first review round produces a FAIL verdict
- Do not introduce scope creep — review against what the plan claims to deliver, not what you think it should deliver
- YAGNI — flag over-engineering, do not add requirements
