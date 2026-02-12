---
description: Review PowerShell script, detect violations, and propose auto-fix patches (project)
argument-hint: "[path/to/script.ps1]"
allowed-tools: ["Read", "Bash", "Bash(pwsh:*)"]
---

## Usage

```bash
/review-pwsh-syntax [path/to/script.ps1]
```

## Arguments

- path/to/script.ps1: PowerShell script file to review (required)

## DEPTH Workflow

### D - Decomposition

- Objective: Complete PowerShell script audit with auto-fix suggestions
- Scope: Guidelines compliance, PSScriptAnalyzer diagnostics, syntax validation
- Output: Structured report with diff-style patches for violations
- Reference: skill:powershell-guidelines

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

- Failure Case: Missing `#Requires`, no strict mode, aliases used → generate patch
- Success Case: Proper structure, strict mode, approved verbs → PASS status

### H - Heuristics

- Minimal Surface: Fix only necessary lines
- No Reformatting: Preserve original structure and logic
- Safe Output: Ensure patches produce valid PowerShell code
- Deterministic Order: #Requires → strict mode → error preference → naming → error handling

## Workflow

1. File Validation: Read script and verify file exists and is readable
2. Version Detection: Identify `#Requires -Version` statement or flag missing
3. Syntax Validation: Run PowerShell parser for syntax checking
   ```powershell
   pwsh -Command "
     \$errors = \$null
     [System.Management.Automation.Language.Parser]::ParseFile(
       'path/to/script.ps1',
       [ref]\$null,
       [ref]\$errors
     )
     if (\$errors) { \$errors | ForEach-Object { Write-Error \$_ }; exit 1 }
     Write-Output 'Syntax OK'
   "
   ```
4. Static Analysis: Execute PSScriptAnalyzer with Warning+ severity
   ```powershell
   pwsh -Command "Invoke-ScriptAnalyzer -Path 'path/to/script.ps1' -Severity Warning,Error"
   ```
5. Guidelines Compliance: Check against powershell-guidelines skill rules:
   - `#Requires -Version 7.0` present
   - `Set-StrictMode -Version Latest` enabled
   - `$ErrorActionPreference = 'Stop'` set
   - No cmdlet aliases (check PSAvoidUsingCmdletAliases)
   - No global variables (check PSAvoidGlobalVars)
   - Approved verbs used
   - Cross-platform paths via `Join-Path`
6. Parameter Style Validation: Check for single-character parameter aliases
7. Violation Analysis: Categorize findings by severity and type
8. Patch Generation: Create unified diff patches for identified violations
9. Report Compilation: Generate structured findings with actionable recommendations
10. Validation: Ensure patches produce valid and safe PowerShell code

## Parameter Style Validation

- Detection: Search for [Alias()] attributes with single-character aliases
- Violation Pattern: [Alias('x')] or [Alias("x")] where x is a single character
- Compliant Pattern: [Parameter()] with no single-character aliases
- Scope: Custom PowerShell scripts only; built-in cmdlet parameters are excluded
- Output: FAIL if single-character parameter aliases detected, PASS otherwise

## Output

- Summary: Pass/fail status with issue count
- Deviations: Line-by-line violations with guideline references
- PSScriptAnalyzer Output: Raw static analysis results
- Syntax Check: Parser validation results
- Parameter Style Check: PASS/FAIL with violation locations
- Auto-Fix Patch: Unified diff format (or "No changes needed")
- Verdict: Final PASS/FAIL determination
