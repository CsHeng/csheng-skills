# Invocation Contract

The skill invocation contract is defined in `contracts/skills.toml`.

## Categories

| Category | Purpose | Lifecycle Owner |
|---|---|---:|
| `workflow` | Top-level lifecycle authority | yes |
| `session` | Session bootstrap and response style | no |
| `discipline` | Reusable engineering method | no |
| `policy` | Language, security, quality, and logging rules | no |
| `tool` | Narrow tool adapter or operational helper | no |
| `manual-tool` | Explicit user action only | no |
| `review-component` | Lower-plane review evaluator | no |
| `internal` | Runtime support library | no |

## Hard Rules

- Only workflow skills may set `lifecycle_owner = true`.
- Manual tools must set `implicit_invocation = false`.
- Mutation-capable skills must set either `requires_explicit_user_request = true` or `requires_approved_plan = true`.
- Internal skills are excluded from external generated targets.
- Root-flat internal runtime support is allowed only when `runtime_support = true`.

## Exposure

Public skill IDs are generated from `contracts/skills.toml` into flat target surfaces. Do not add machine-readable contract metadata to individual `SKILL.md` files.
