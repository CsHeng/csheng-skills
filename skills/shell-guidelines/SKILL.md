---
name: shell-guidelines
description: "Apply Shell-specific policy and standards to shell scripts, automation, ad hoc commands, or implementation reviews: Bash-first agent execution, explicit POSIX/zsh exceptions, strict mode, quoting, portability, cross-shell-safe variable names, ShellCheck, and macOS/Homebrew behavior. Use as a language/tooling overlay alongside the primary workflow; do not take lifecycle ownership."
---

# Shell Guidelines

## Purpose

Define the Shell policy overlay for safe, portable, auditable automation, including script development patterns and code review. The primary workflow owns the task lifecycle.

## Scope

In-scope:
- Agent-generated ad hoc shell commands
- Editing or creating shell scripts (`.sh`, bash/zsh scripts)
- CI and local automation scripts
- Code review and syntax audit for shell files

Out-of-scope:
- Language selection (see `language-decision-tree` skill)
- Tool selection and progressive search workflow (see `tool-decision-tree` skill)

## Progressive Disclosure

- Script development patterns: `references/script-patterns.md`
- Code review DEPTH workflow and checklist: `references/review-checklist.md`

## Deterministic Steps

1. Choose the shell explicitly for the command or target environment
   - Run a simple external command directly when it needs no shell variables, loops, functions, arrays, or multi-command control flow.
   - Default agent-generated ad hoc shell logic to Bash.
   - POSIX: `#!/bin/sh`
   - CI/Linux bash: `#!/usr/bin/env bash`
   - Use `#!/usr/bin/env zsh` only when the target explicitly requires zsh semantics, startup behavior, or configuration.
   - macOS: `/bin/bash` is typically 3.2; if you rely on Bash 4+ features (e.g. `mapfile/readarray`, associative arrays), ensure Homebrew Bash is used via `PATH` or use the host-appropriate absolute shebang (`/opt/homebrew/bin/bash` on Apple Silicon, `/usr/local/bin/bash` on Intel) for internal scripts.
2. Enable strict mode for shell entrypoints
   - Use `set -euo pipefail` for Bash and zsh entrypoints.
   - Use `set -eu` for POSIX `sh` entrypoints because `pipefail` is not portable.
   - For Bash entrypoints that install an `ERR` trap, use `set -Eeuo pipefail` so the trap is inherited by functions, command substitutions, and subshells.
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
REQUIRED: Use strict mode for Bash and zsh entrypoints: `set -euo pipefail`.
REQUIRED: Use strict mode for POSIX `sh` entrypoints: `set -eu`.
PREFERRED: Under `set -e`, avoid `((i++))`/`((i--))` when counters can start at 0 (exit status becomes 1); prefer `((i+=1))` / `((++i))` for counters.
PROHIBITED: Ignore return codes from external commands.
PREFERRED: For Bash entrypoints, add a minimal failure trap for debugging context and enable errtrace so it propagates: `set -E; trap 'echo "Error on line $LINENO" >&2' ERR`.
PREFERRED: Do not emulate this pattern in POSIX `sh`; it has no portable `ERR` trap or errtrace equivalent.

### Portability
REQUIRED: If the target is POSIX `sh`, use only POSIX syntax (`[ ]`, no `[[ ]]`, no arrays).
PREFERRED: Do not assume macOS `/bin/bash` supports modern bash features; if you use bash-4+ features (e.g. `mapfile/readarray`, associative arrays), require bash 4+ explicitly (shebang/runtime) or provide a compatibility fallback.
PROHIBITED: Use zsh-only features in scripts intended for bash/sh environments.

### Data Handling
REQUIRED: Quote variables to prevent word splitting and glob expansion.
PROHIBITED: Implement multi-step structured data parsing in shell when a higher-level language is required by correctness/testability constraints (see the `language-decision-tree` skill).

### Persisted Script Escalation
PREFERRED: Revisit the implementation language through `language-decision-tree` when a persisted Shell script accumulates multi-step structured parsing, persistent state, complex retry or rollback, concurrency, multi-host distribution, embedded languages, or runtime and dependency management.
PREFERRED: Prefer Go for long-lived operational tooling when a single binary, cross-platform delivery, stable CLI contract, or reduced runtime state is a material benefit. This is a preference, not a mandatory replacement language; repository and ecosystem constraints still control the decision.
PROHIBITED: Split one reusable business rule across Shell and another implementation language.

### Shell Selection
REQUIRED: Default agent-generated ad hoc shell logic to Bash unless the target explicitly requires POSIX `sh` or zsh.
PREFERRED: When the command runner exposes a shell or interpreter option, select Bash there instead of nesting the command inside `bash -lc`.
REQUIRED: When the runner cannot select an interpreter, invoke the resolved target shell explicitly: use `bash -c` for the default-Bash case and the matching `sh -c` or `zsh -c` only when that target is explicit; put multiline/reusable logic in a script for the resolved shell.
REQUIRED: Pass variable data through arguments or the environment instead of interpolating untrusted values into the command string.
REQUIRED: When passing positional data to `bash -c`, provide a `$0` placeholder before the data, for example `bash -c 'printf "%s\n" "$1"' -- "$candidate_value"`; the first argument after the command string becomes `$0`.
PREFERRED: Use `bash -lc` only when the command explicitly requires login-shell initialization.
PROHIBITED: Let the current login or interactive shell silently choose semantics for agent-generated shell logic.

### Reserved Shell Variable Names
PROHIBITED: Do not use names that are special or reserved in zsh in any shell code or ad hoc shell commands, regardless of the selected interpreter: `status`, `path`, `pipestatus`, `argv`, `commands`, `functions`, `options`, `parameters`.
PREFERRED: Use explicit non-reserved names instead: `rc`, `exit_code`, `status_label`, `notification_status`, `candidate_path`, `target_path`.

### File Naming
REQUIRED: Name shell script files using hyphen style (kebab-case): `my-script.sh`, not `my_script.sh`

## macOS / Homebrew Notes (Agents + Non-Interactive)

- `#!/usr/bin/env bash` resolves via `PATH`; on macOS the default is often `/bin/bash` (3.2). If you need Bash 4+ features, require Homebrew Bash on `PATH` or use the host-appropriate absolute shebang (`/opt/homebrew/bin/bash` on Apple Silicon, `/usr/local/bin/bash` on Intel) for internal scripts.
- macOS login `zsh` runs `path_helper` (via `/etc/zprofile`), which can override PATH changes from `.zshenv`. For tasks explicitly testing `zsh -lc`, put the final Homebrew PATH setup in `.zprofile` after `path_helper`, using the host's `brew shellenv`.
- Homebrew `curl` is commonly keg-only; prefer `export PATH="$(brew --prefix curl)/bin:$PATH"` when you need modern curl/TLS features.
- Non-interactive bash sources `$BASH_ENV`; set it to a file that exports the PATH you expect (including Homebrew) if your automation runs `bash` non-interactively.
- Homebrew `*/libexec/gnubin` directories can replace macOS/BSD command semantics even when the host is macOS. Run `scripts/audit-homebrew-command-shadowing.py` when an option behaves unexpectedly or a script depends on a specific command dialect.
- Debug quickly: `command -v bash; /usr/bin/env bash --version | head -n1; type -a bash; command -v curl; curl --version | head -n1`.

### Homebrew Command Shadow Audit

The audit is read-only and emits deterministic JSON containing effective providers, duplicate providers, macOS system shadows, and gnubin-only commands:

```bash
python3 /absolute/path/to/skills/shell-guidelines/scripts/audit-homebrew-command-shadowing.py
```

Use `--path` for a synthetic or remote PATH snapshot, repeat `--system-dir` to replace the default macOS system directories, and add `--compact` for JSONL-oriented tooling.


## Operational Checks (Examples)

```bash
# Syntax
bash -n path/to/script.sh

# Inline Bash syntax review (does not execute the command text)
printf '%s\n' "$command_text" | bash -n

# Lint
shellcheck path/to/script.sh

# Inline Bash lint
printf '%s\n' "$command_text" | shellcheck -s bash -f gcc -
```

## Checklist

- Shell script files named with hyphen style (kebab-case): `my-script.sh`
- Correct shebang for target environment
- Strict mode enabled for Bash/zsh (`set -euo pipefail`) or POSIX `sh` (`set -eu`) entrypoints
- No `eval`/unsafe execution of user input
- Variables quoted; inputs validated
- `shellcheck` clean (when available)

## Error Handling Examples

For generic error handling patterns (resilience, resource management, monitoring), see the `error-patterns` skill.

### Trap-Based Error Handler
```bash
#!/usr/bin/env bash
set -Eeuo pipefail

handle_error() {
    local exit_code=$?
    local line_number=$1
    echo "ERROR: Script failed on line $line_number with exit code $exit_code" >&2
    exit $exit_code
}

trap 'handle_error $LINENO' ERR
```

### Bash/zsh Input Validation Function
```bash
validate_input() {
    local input="$1"
    if [[ -z "$input" ]]; then
        echo "ERROR: Input parameter is required" >&2
        exit 1
    fi
}
```
