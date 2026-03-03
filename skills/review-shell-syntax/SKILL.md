---
name: review-shell-syntax
description: "Review shell script syntax, detect violations, and propose auto-fix patches. Activates for: review shell syntax, check shell code, shell lint, 审查Shell语法, 检查Shell代码。"
---

## Input

- Target file path: caller-specified (required)

## DEPTH Workflow

### D - Decomposition

- Objective: Complete shell script audit with auto-fix suggestions
- Scope: Guidelines compliance, ShellCheck diagnostics, syntax validation
- Output: Structured report with diff-style patches for violations
- Reference: skill:shell-guidelines

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

- Failure Case: Missing fi, unquoted variables, no strict mode → generate patch
- Success Case: Proper structure, quoting, strict mode → PASS status

### H - Heuristics

- Minimal Surface: Fix only necessary lines
- No Reformatting: Preserve original structure and logic
- Safe Output: Ensure patches produce valid shell code
- Deterministic Order: Shebang → strict mode → quoting → variables → traps → flow

## Workflow

1. File Validation: Read script and verify file exists and is readable
2. Interpreter Detection: Identify shebang line or default to bash
3. Syntax Validation: Run interpreter-specific syntax checking (bash -n, sh -n, zsh -n)
4. Static Analysis: Execute shellcheck with GCC format for structured output
5. Guidelines Compliance: Check against shell scripting best practices
6. Parameter Style Validation: Check for short parameter aliases in case statements and getopts
7. Violation Analysis: Categorize findings by severity and type
8. Patch Generation: Create unified diff patches for identified violations
9. Report Compilation: Generate structured findings with actionable recommendations
10. Validation: Ensure patches produce valid and safe shell code

## Parameter Style Validation

- Detection: Search for short parameter patterns and bare parameters in case statements and getopts usage
- Violation Patterns:
  - Case statements: -x|--xxx or --xxx|-x patterns
  - Case statements: bare parameters like help|--help or ""|help|--help
  - getopts: Single-letter option definitions
  - Usage functions: Short parameter documentation
- Compliant Pattern: --xxx) case branches with no short alias and no bare parameter
- Scope: Custom CLI scripts only; third-party tool invocations are excluded
- Output: FAIL if short parameter aliases or bare parameters detected, PASS otherwise

## Output

- Summary: Pass/fail status with issue count
- Deviations: Line-by-line violations with guideline references
- ShellCheck Output: Raw static analysis results
- Syntax Check: Interpreter validation results
- Parameter Style Check: PASS/FAIL with violation locations
- Auto-Fix Patch: Unified diff format (or "No changes needed")
- Verdict: Final PASS/FAIL determination
