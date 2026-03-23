---
name: quality-standards
description: "Use when configuring linters, setting coverage thresholds, defining CI quality gates, or reviewing technical debt metrics. 中文触发：配置 linter、覆盖率阈值、CI 质量门禁、技术债务。"
---
## Purpose

Define code quality metrics and continuous improvement guidelines that can be applied across services and languages, with explicit thresholds for complexity, maintainability, and static analysis coverage.

## IO Semantics

Input: Code repositories and quality reports that need structured metrics and thresholds.

Output: Measurable targets and configuration examples for complexity, maintainability, and static analysis that can be enforced in CI.

Side Effects: Introducing or tightening quality standards may require refactoring, additional tests, and tooling configuration updates.

## Complexity Standards

Enforce cyclomatic complexity thresholds:
- Simple functions: complexity ≤ 5
- Moderate functions: complexity ≤ 10
- Complex functions: complexity ≤ 15
- Refactor functions exceeding 20 complexity

## Maintainability Index

Implement maintainability measurement:
- Target maintainability index: 70+ for new code
- Minimum index: 50 for existing code
- Track index trends over time
- Prioritize refactoring for low-index modules

Factors affecting maintainability:
- Code volume (lines of code)
- Cyclomatic complexity
- Halstead volume metrics
- Comment density

## Static Analysis Integration

### Python with Ruff
- Enable pycodestyle, pyflakes, isort, flake8-bugbear
- Set max-complexity to 10
- Configure line-length to 88

### Go with golangci-lint
- Enable complexity checks (max 10)
- Set function length limits (100 lines, 50 statements)
- Enable gocyclo with min-complexity 15

### JavaScript with ESLint
- Set complexity rule to error at 10
- Limit max-lines-per-function to 100
- Set max-depth to 4, max-params to 5

## Code Review Process

### Mandatory Review Criteria
- Functionality correctness and completeness
- Security vulnerability assessment
- Performance impact evaluation
- Code maintainability and readability
- Test coverage adequacy

### Technical Debt Management
- Classify debt: code_quality, security, performance, documentation
- Prioritize by severity and effort
- Track debt items and remediation progress
- Schedule regular debt reduction sprints

## Continuous Improvement

### Quality Metrics Tracking
- Collect metrics: complexity, maintainability, coverage, duplicates
- Track security vulnerabilities and scores
- Monitor build/test times and deployment frequency
- Analyze trends over time

### Team Development
- Assess team skill gaps
- Create training plans for identified gaps
- Schedule knowledge sharing sessions
- Rotate presenters for brown bag sessions

## Checklist

- [ ] Complexity thresholds configured in linters
- [ ] Maintainability index tracked
- [ ] Static analysis integrated in CI
- [ ] Code review checklist defined
- [ ] Technical debt tracked and prioritized
- [ ] Quality metrics dashboard available
- [ ] Team skill development plan in place

## References

- [Python Quality Examples](references/examples-python.md)
- [Linter Configurations](references/linter-configs.md)
