# Shell Script Development Patterns

## Purpose

Write safe, portable orchestration scripts that stay small and delegate complexity to a stronger language when needed.

## Scope

- Shell choice (zsh vs bash vs sh) and portability pitfalls
- Strict mode, quoting, error handling, and basic logging

Out-of-scope:
- Complex parsing or business logic (delegate to Python)

## Deterministic Rules

1. Choose shell by target:
   - zsh: local dev on macOS
   - bash: CI and Linux servers
   - sh: POSIX/minimal containers (Alpine)
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
- Shebang matches target environment
- Strict mode set (best-effort for sh)
- All variables quoted unless intentional word splitting
- `shellcheck` clean when available
- Complex parsing delegated to Python
