# Go Code Review Checklist

## Input

- Target file path: caller-specified (required)

## DEPTH Workflow

### D - Decomposition

- Objective: Complete Go code audit with auto-fix suggestions
- Scope: Guidelines compliance, golangci-lint diagnostics, syntax validation
- Output: Structured report with diff-style patches for violations
- Reference: go-guidelines SKILL.md

### E - Explicit Reasoning

- Findings: Line number, description, guideline section, explicit reasoning
- Patches: Only modify lines with violations, preserve structure
- Constraints: No stylistic changes, avoid false positives

### P - Parameters

- Strictness: Maximum compliance enforcement
- Fixes: Conservative, rule-driven modifications
- Determinism: Required output consistency
- Format: Unified diff patches

### T - Test Cases

- Failure Case: Syntax errors, unused variables, missing error handling -> generate patch
- Success Case: Proper structure, error handling, clean imports -> PASS status

### H - Heuristics

- Minimal Surface: Fix only necessary lines
- No Reformatting: Preserve original structure and logic
- Safe Output: Ensure patches produce valid Go code
- Deterministic Order: Imports -> error handling -> unused code -> style

## Workflow

1. File Validation: Read Go file and verify file exists and is readable
2. Module Detection: Identify go.mod context or standalone file
3. Syntax Validation: Run Go syntax checking (go build or go vet)
4. Static Analysis: Execute golangci-lint with structured output
5. Format Check: Run gofmt -d to detect formatting deviations
6. Guidelines Compliance: Check against Go best practices
7. Parameter Style Validation: Check for single-letter flag names or Cobra shorthand usage
8. Violation Analysis: Categorize findings by severity and type
9. Patch Generation: Create unified diff patches for identified violations
10. Validation: Ensure patches produce valid and safe Go code

## Parameter Style Validation

- Detection: Search for flag package or Cobra command definitions with short parameters
- Violation Patterns:
  - flag package: Single-letter flag names (flag.String("x", ...))
  - Cobra: Shorthand parameter definitions (*P methods or Shorthand field)
- Compliant Pattern: Multi-character flag names with no shorthand
- Scope: Custom CLI applications only; third-party library usage is excluded
- Output: FAIL if short parameter definitions detected, PASS otherwise

## Output

- Summary: Pass/fail status with issue count
- Deviations: Line-by-line violations with guideline references
- golangci-lint Output: Raw static analysis results
- Syntax Check: Go validation results
- Parameter Style Check: PASS/FAIL with violation locations
- Auto-Fix Patch: Unified diff format (or "No changes needed")
- Verdict: Final PASS/FAIL determination
