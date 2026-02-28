---
description: Review Python script, detect violations, and propose auto-fix patches (project)
argument-hint: "[path/to/script.py]"
allowed-tools: ["Read", "Edit", "Bash", "Bash(PYTHONDONTWRITEBYTECODE=1 python3*:*)", "Bash(python*:*)", "Bash(python3*:*)", "Bash(ruff*:*)", "Bash(uv run ruff*:*)", "Bash(uv run ty*:*)", "Bash(uvx*:*)", "Bash(ty*:*)"]
---

## Usage

```bash
/review-python-syntax [path/to/script.py]
```

## Arguments

- path/to/script.py: Python script file to review (required)

## DEPTH Workflow

### D - Decomposition

- Objective: Complete Python script audit with auto-fix suggestions
- Scope: Guidelines compliance, Ruff diagnostics, ty type checking, syntax validation
- Output: Structured report with diff-style patches for violations
- Reference: skill:python-guidelines

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

- Failure Case: Syntax errors, type errors, missing type hints, unused imports → generate patch
- Success Case: Proper structure, type hints, clean imports → PASS status

### H - Heuristics

- Minimal Surface: Fix only necessary lines
- No Reformatting: Preserve original structure and logic
- Safe Output: Ensure patches produce valid Python code
- Deterministic Order: Imports → type hints → syntax → types → style → unused code

## Workflow

1. File Validation: Read script and verify file exists and is readable
2. Python Version Detection: Identify Python version requirements
3. Syntax Validation: Run `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile <file>` or `ast.parse`
4. Static Analysis: Execute ruff check with structured output
5. Type Checking: Execute `ty` with structured output using manifest-backed dependencies (nearest `pyproject.toml` / `requirements*.txt`). Prefer `uv run ty check <target>` for `pyproject.toml` projects (including script projects with `[tool.uv] package = false`), and `uvx --with-requirements <requirements.txt> ty check <target>` for requirements-based projects; avoid hardcoded one-off `uvx --with <single-package>` fixes
6. Guidelines Compliance: Check against Python scripting best practices
7. Parameter Style Validation: Check for short parameter aliases in argparse definitions
8. Violation Analysis: Categorize findings by severity and type
9. Patch Generation: Create unified diff patches for identified violations
10. Report Compilation: Generate structured findings with actionable recommendations
11. Validation: Ensure patches produce valid and safe Python code

## Type-Check Dependency Resolution (Required)

- Detect nearest dependency manifest(s): `pyproject.toml` first, then `requirements*.txt`.
- `pyproject.toml` project (preferred): run `uv run ty check <target>`. This includes script projects; adding a minimal `pyproject.toml` with `[tool.uv] package = false` is valid and preferred over ad-hoc package flags.
- `requirements*.txt` project: run manifest-backed `uvx`: `uvx --with-requirements <requirements.txt> ty check <target>`.
- If imports still fail, verify the manifest actually contains the missing dependency before suggesting code changes.
- Only use explicit one-off `uvx --with <pkg>` as a last-resort fallback, and report that it was a fallback.

## Parameter Style Validation

- Detection: Search for argparse.add_argument() calls with short parameter aliases or missing add_help=False
- Violation Pattern: add_argument("-x", "--xxx") or add_argument("-x") where x is a single letter
- Violation Pattern: ArgumentParser() without add_help=False (allows automatic -h)
- Compliant Pattern: ArgumentParser(add_help=False) with manual add_argument("--help", action="help")
- Scope: Custom CLI scripts only; third-party tool invocations are excluded
- Output: FAIL if short parameter aliases detected or add_help not disabled, PASS otherwise

## Output

- Summary: Pass/fail status with issue count
- Deviations: Line-by-line violations with guideline references
- Ruff Output: Raw static analysis results
- Syntax Check: Python validation results
- Type Check: ty diagnostics results
- Parameter Style Check: PASS/FAIL with violation locations
- Auto-Fix Patch: Unified diff format (or "No changes needed")
- Verdict: Final PASS/FAIL determination
