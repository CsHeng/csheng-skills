---
name: shell-guidelines
description: "Shell scripting guidelines (bash/zsh/sh): strict mode, quoting, portability, ShellCheck. Activates for: shell script best practices, bash strict mode, quoting, shellcheck, CI scripts. 中文触发：Shell 脚本规范、bash 严格模式、变量引用/quote、shellcheck、CI 脚本。"
---

# Shell Guidelines

## Purpose

Define Shell scripting standards for safe, portable, auditable automation.

## Scope

In-scope:
- Editing or creating shell scripts (`.sh`, bash/zsh scripts)
- CI and local automation scripts (language-level guidance only)

Out-of-scope:
- Language selection (see `rules/15-language-decision-tree.md`)
- Tool selection and progressive search workflow (see `rules/20-tool-decision-tree.md`)

## Deterministic Steps

1. Choose the correct shell and shebang for the target environment
   - POSIX: `#!/bin/sh`
   - CI/Linux bash: `#!/usr/bin/env bash`
   - Local dev scripts that rely on zsh features: `#!/usr/bin/env zsh`
   - macOS: `/bin/bash` is typically 3.2; if you rely on bash 4+ features (e.g. `mapfile/readarray`, associative arrays), ensure Homebrew bash is used (via `PATH`) or use an absolute shebang like `#!/opt/homebrew/bin/bash` for internal scripts.
2. Enable strict mode (bash)
   - Use `set -euo pipefail` for bash entrypoints.
   - Add a minimal `trap` for context on failure when appropriate.
3. Quote and validate inputs
   - Quote all variable expansions unless intentionally relying on splitting/globbing.
   - Validate arguments count and basic shape before performing work.
   - Avoid `eval` and executing untrusted input.
4. Prefer simple, readable structure
   - Keep scripts small and linear where possible.
   - Put functions above the main execution flow.
   - Return early to reduce nesting.
5. Use linting and syntax checks
   - Run `shellcheck` for bash/sh where available.
   - Run interpreter syntax checks: `bash -n`, `sh -n`, `zsh -n`.

## Rules (Hard Constraints)

### Security
PROHIBITED: Use `eval` or `exec` with untrusted user input.
PROHIBITED: Hardcode secrets or credentials in shell scripts.
REQUIRED: Validate inputs before processing; reject unexpected values early.

### Error Handling
REQUIRED: Use strict mode for bash entrypoints: `set -euo pipefail`.
PREFERRED: Under `set -e`, avoid `((i++))`/`((i--))` when counters can start at 0 (exit status becomes 1); prefer `((i+=1))` / `((++i))` for counters.
PROHIBITED: Ignore return codes from external commands.
PREFERRED: Add a minimal failure trap for debugging context: `trap 'echo "Error on line $LINENO" >&2' ERR`.

### Portability
REQUIRED: If the target is POSIX `sh`, use only POSIX syntax (`[ ]`, no `[[ ]]`, no arrays).
PREFERRED: Do not assume macOS `/bin/bash` supports modern bash features; if you use bash-4+ features (e.g. `mapfile/readarray`, associative arrays), require bash 4+ explicitly (shebang/runtime) or provide a compatibility fallback.
PROHIBITED: Use zsh-only features in scripts intended for bash/sh environments.

### Data Handling
REQUIRED: Quote variables to prevent word splitting and glob expansion.
PROHIBITED: Implement multi-step structured data parsing in shell when a higher-level language is required by correctness/testability constraints (see `rules/15-language-decision-tree.md`).

### File Naming
REQUIRED: Name shell script files using hyphen style (kebab-case): `my-script.sh`, not `my_script.sh`

## macOS / Homebrew Notes (Agents + Non-Interactive)

- `#!/usr/bin/env bash` resolves via `PATH`; on macOS the default is often `/bin/bash` (3.2). If you need bash 4+ features, either require Homebrew bash (PATH) or use an absolute shebang (`#!/opt/homebrew/bin/bash`) for internal scripts.
- macOS login `zsh` runs `path_helper` (via `/etc/zprofile`), which can override PATH changes from `.zshenv`. For agent/CI runs that use `zsh -lc`, put the final Homebrew PATH setup in `.zprofile` (after `path_helper`), e.g. re-run `eval "$(/opt/homebrew/bin/brew shellenv)"`.
- Homebrew `curl` is commonly keg-only; prefer `export PATH="/opt/homebrew/opt/curl/bin:$PATH"` when you need modern curl/TLS features.
- Non-interactive bash sources `$BASH_ENV`; set it to a file that exports the PATH you expect (including Homebrew) if your automation runs `bash` non-interactively.
- Debug quickly: `command -v bash; /usr/bin/env bash --version | head -n1; type -a bash; command -v curl; curl --version | head -n1`.


## Operational Checks (Examples)

```bash
# Syntax
bash -n path/to/script.sh

# Lint
shellcheck path/to/script.sh
```

## Checklist

- Shell script files named with hyphen style (kebab-case): `my-script.sh`
- Correct shebang for target environment
- Strict mode enabled for bash
- No `eval`/unsafe execution of user input
- Variables quoted; inputs validated
- `shellcheck` clean (when available)

## Error Handling Examples

For generic error handling patterns (resilience, resource management, monitoring), see `error-patterns` skill.

### Trap-Based Error Handler
```bash
#!/usr/bin/env bash
set -euo pipefail

handle_error() {
    local exit_code=$?
    local line_number=$1
    echo "ERROR: Script failed on line $line_number with exit code $exit_code" >&2
    exit $exit_code
}

trap 'handle_error $LINENO' ERR
```

### Input Validation Function
```bash
validate_input() {
    local input="$1"
    if [[ -z "$input" ]]; then
        echo "ERROR: Input parameter is required" >&2
        exit 1
    fi
}
```
