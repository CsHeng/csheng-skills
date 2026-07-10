# Shell Script Development Patterns

## Purpose

Write safe, portable command snippets and orchestration scripts that stay small and delegate complexity to a stronger language when needed.

## Scope

- Shell choice for agent-generated ad hoc logic and scripts, including portability pitfalls
- Strict mode, quoting, error handling, and basic logging

Out-of-scope:
- Complex parsing or business logic (delegate to Python)

## Deterministic Rules

1. Choose shell by target:
   - bash: default for agent-generated ad hoc shell logic, local automation, CI, and Linux servers
   - zsh: only for zsh semantics, startup behavior, and configuration
   - sh: POSIX/minimal containers (Alpine)
   - current executor: simple external commands that need no shell logic
2. Use strict mode when supported:
   - bash/zsh: `set -euo pipefail`
   - sh: `set -eu` (no pipefail on many sh)
3. Quote variables by default: `"${var}"`
4. Prefer `rg` over `grep` when available; prefer `fd` over `find` when available.
5. Keep core logic small (roughly under ~30 lines). If it grows, move logic into Python and keep Shell as a wrapper.
6. Name shell script files using hyphen style (kebab-case): `my-script.sh`, not `my_script.sh`

## Minimal Logging Contract

- Functions: `log_info`, `log_warn`, `log_error`
- Include timestamp and key=value pairs

## Checklist

- Shell script files named with hyphen style (kebab-case): `my-script.sh`
- Agent-generated ad hoc shell logic uses Bash unless the target requires POSIX `sh` or zsh
- Shebang matches target environment
- Strict mode set: `set -euo pipefail` for Bash/zsh entrypoints and `set -eu` for POSIX `sh` entrypoints
- All variables quoted unless intentional word splitting
- `shellcheck` clean when available
- Complex parsing delegated to Python
