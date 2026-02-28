---
name: powershell-guidelines
description: "PowerShell 7 scripting guidelines: strict mode, #Requires, PSScriptAnalyzer, naming, cross-platform. Activates for: PowerShell best practices, PowerShell strict mode, PSScriptAnalyzer, pwsh script, PS1 conventions. 中文触发：PowerShell 规范、PowerShell 严格模式、PSScriptAnalyzer、pwsh 脚本、PS1 规范。"
---

# PowerShell Guidelines

## Purpose

Define PowerShell 7 scripting standards for safe, portable, auditable automation targeting Windows environments from macOS.

## Scope

In-scope:
- Editing or creating PowerShell scripts (`.ps1`, `.psm1`, `.psd1`)
- Cross-platform scripts authored on macOS for Windows execution
- Module manifests and script modules

Out-of-scope:
- Language selection (see `rules/15-language-decision-tree.md`)
- Tool selection and progressive search workflow (see `rules/20-tool-decision-tree.md`)
- Windows-only legacy PowerShell 5.1 patterns

## Deterministic Steps

1. Declare version requirement
   - Add `#Requires -Version 7.0` at the top of every script.
   - Add module requirements via `#Requires -Modules` when depending on external modules.
2. Enable strict mode and error preference
   - Use `Set-StrictMode -Version Latest` in script body.
   - Set `$ErrorActionPreference = 'Stop'` for fail-fast behavior.
3. Use approved verbs and PascalCase naming
   - Functions: `Verb-Noun` with approved verbs (`Get-Verb` to list).
   - Variables: `$PascalCase` for script-scoped, `$camelCase` for local.
   - Parameters: PascalCase with `[Parameter()]` attributes.
4. Use cross-platform path handling
   - Use `Join-Path` instead of string concatenation with `\` or `/`.
   - Use `$PSScriptRoot` for script-relative paths.
   - Use `[System.IO.Path]::Combine()` for complex path assembly.
5. Validate inputs and handle errors
   - Use `[CmdletBinding()]` and `[Parameter(Mandatory)]` for input validation.
   - Use `try/catch/finally` for structured error handling.
   - Prefer `$PSCmdlet.ThrowTerminatingError()` over `throw` in advanced functions.
6. Use linting and syntax checks
   - Run `pwsh -Command "[System.Management.Automation.Language.Parser]::ParseFile()"` for syntax validation.
   - Run `Invoke-ScriptAnalyzer` with default rules.

## Rules (Hard Constraints)

### Security
PROHIBITED: Use `Invoke-Expression` with untrusted input.
PROHIBITED: Hardcode secrets, credentials, or API keys in scripts.
PROHIBITED: Use plain-text passwords in parameters (use `[SecureString]` or credential objects).
REQUIRED: Validate inputs before processing; reject unexpected values early.
REQUIRED: Use `[ValidateSet()]`, `[ValidatePattern()]`, `[ValidateRange()]` for parameter validation.

### Strict Mode
REQUIRED: Include `#Requires -Version 7.0` at script top.
REQUIRED: Enable `Set-StrictMode -Version Latest` in script body.
REQUIRED: Set `$ErrorActionPreference = 'Stop'` for fail-fast behavior.
PROHIBITED: Use `$ErrorActionPreference = 'SilentlyContinue'` except in explicitly documented exception-handling blocks.

### Cross-Platform
REQUIRED: Use `Join-Path` for all path construction.
REQUIRED: Use `$PSScriptRoot` for script-relative paths.
PROHIBITED: Hardcode Windows-style paths (`C:\...`) without platform guards.
PROHIBITED: Use backslash `\` as path separator in string literals; use `Join-Path` or `[IO.Path]::Combine()`.
PREFERRED: Test scripts with `pwsh` on macOS before deploying to Windows.

### Naming
REQUIRED: Use approved verbs for function names (`Get-Verb` to validate).
REQUIRED: Use PascalCase for function names, parameters, and script-scoped variables.
REQUIRED: Use `Verb-Noun` naming pattern for all functions.
REQUIRED: Name script files using PascalCase: `Get-UserReport.ps1`, not `get_user_report.ps1`.
PROHIBITED: Use cmdlet aliases in scripts (`ls`, `cat`, `%`, `?`); use full cmdlet names.
PROHIBITED: Use global variables (`$global:*`); pass data via parameters and return values.

### Error Handling
REQUIRED: Use `try/catch/finally` for operations that may fail.
REQUIRED: Include context in error messages (variable values, operation attempted).
PROHIBITED: Ignore errors from external commands; check `$LASTEXITCODE` after native commands.
PREFERRED: Use `$PSCmdlet.ThrowTerminatingError()` in advanced functions for proper error record creation.

## macOS + Cross-Platform Notes

- PowerShell 7 on macOS: installed via Homebrew (`brew install powershell`), invoked as `pwsh`.
- File system is case-sensitive on macOS (APFS default); Windows is case-insensitive. Test path handling accordingly.
- Line endings: macOS uses LF; Windows expects CRLF for some tools. Use `.gitattributes` with `*.ps1 text eol=crlf` when targeting Windows.
- Environment variables: `$env:HOME` on macOS vs `$env:USERPROFILE` on Windows. Use `$HOME` (PowerShell automatic variable) for portability.
- Native commands: `grep`, `sed`, `awk` are available on macOS but not Windows. Use PowerShell cmdlets (`Select-String`, `-replace`, `ForEach-Object`) for portable scripts.
- Module paths differ: use `$env:PSModulePath` and `Join-Path` for portable module references.

## Operational Checks (Examples)

```powershell
# Syntax validation (PowerShell parser)
pwsh -Command "
  \$errors = \$null
  [System.Management.Automation.Language.Parser]::ParseFile(
    'path/to/script.ps1',
    [ref]\$null,
    [ref]\$errors
  )
  if (\$errors) { \$errors | ForEach-Object { Write-Error \$_ } }
  else { Write-Output 'Syntax OK' }
"

# PSScriptAnalyzer
pwsh -Command "Invoke-ScriptAnalyzer -Path 'path/to/script.ps1' -Severity Warning,Error"

# Check approved verbs
pwsh -Command "Get-Verb | Sort-Object Verb"
```

## Checklist

- `#Requires -Version 7.0` present at script top
- `Set-StrictMode -Version Latest` enabled
- `$ErrorActionPreference = 'Stop'` set
- No cmdlet aliases used; full cmdlet names only
- No global variables; data passed via parameters
- Approved verbs used for all functions
- PascalCase naming for functions, parameters, script-scoped variables
- Cross-platform paths via `Join-Path` / `$PSScriptRoot`
- No hardcoded secrets or plain-text passwords
- PSScriptAnalyzer clean (Warning+ severity)
- `try/catch` for fallible operations; `$LASTEXITCODE` checked after native commands

## Error Handling Examples

For generic error handling patterns (resilience, resource management, monitoring), see `error-patterns` skill.

### Strict Mode + Error Preference Setup
```powershell
#Requires -Version 7.0

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
```

### Advanced Function with Proper Error Handling
```powershell
function Get-ConfigValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ConfigPath,

        [Parameter(Mandatory)]
        [string]$Key
    )

    try {
        if (-not (Test-Path -Path $ConfigPath)) {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.IO.FileNotFoundException]::new("Config file not found: $ConfigPath"),
                    'ConfigFileNotFound',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $ConfigPath
                )
            )
        }
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        return $config.$Key
    }
    catch {
        Write-Error "ERROR: Failed to read key '$Key' from '$ConfigPath': $_"
        throw
    }
}
```

### Native Command Exit Code Check
```powershell
& git status
if ($LASTEXITCODE -ne 0) {
    throw "ERROR: git status failed with exit code $LASTEXITCODE"
}
```
