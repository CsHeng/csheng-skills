# Invocation Contract

The skill invocation contract is defined in `contracts/skills.toml`.

See `workflow-orchestration.md` for the canonical maintenance view and generated PlantUML views of the implementation invocation DAG and repair loop.

## Categories

| Category | Purpose | Lifecycle Owner |
|---|---|---:|
| `workflow` | Top-level lifecycle authority | yes |
| `session` | Optional routing, session boundaries, and response style | no |
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
- A skill with `runtime_contract` must keep that contract inside its source directory so generated install surfaces carry it with the skill.
- Runtime invocation graphs must be acyclic, evaluators must not call lifecycle workflows, and an implementation repair graph must declare exactly one lifecycle-owning loop owner.

## Exposure

Public skill IDs are generated from `contracts/skills.toml` into flat target surfaces. Do not add machine-readable contract metadata to `SKILL.md` frontmatter. Repo-global exposure metadata remains in `contracts/skills.toml`; install-required runtime graph metadata lives in a directly linked skill-local `references/` file.

Native description matching is the default discovery mechanism, but it is not a deterministic lifecycle gate. A host that must guarantee controller entry may keep a thin intent-to-skill mapping in its user-level agent bootstrap, for example:

- approved plan/design implementation -> `implement-change`
- implementation/code review -> `review-implementation` plus matching policy overlays

The bootstrap must stop at public skill IDs. It must not duplicate workflow edges, repair states, round budgets, or exit rules; those travel with the installed controller under `implement-change/references/`.

## Output Composition

`output-styles` is the shared conversational rendering baseline. For every composed response, select one primary skill from the user's main intent to own the domain conclusion and concern order. Other matched skills contribute semantic overlays such as policy checks, evidence, risks, or stop states; they do not append independent report templates.

Fixed shapes remain valid for durable artifacts, machine-consumed schemas, and explicit user-requested formats. Internal analysis checklists do not automatically become response sections. For example, `analyze-project` evaluates truth roots, terminology, search boundaries, architecture, operations, status, and drift internally, but renders only relevant axes unless the user explicitly requests a full truth audit.

## Generated Architecture Views

`scripts/generate-workflow-diagrams.py` derives the implementation DAG and repair-loop PlantUML sources from the installed controller contract. The generated files under `docs/architecture/diagrams/` are review surfaces, not independent contract inputs.
