# Skill Authoring

Use this reference when maintaining local skill inventories, descriptions, routers, or agent-agnostic workflow surfaces.

## Invocation Surface

- Model-invoked skills spend prompt context through their name and description every session. Use them only when the agent should route to the skill without the user naming it.
- User-invoked skills reduce prompt competition but require the user or a router skill to remember them.
- Keep third-party workflow libraries out of the default discovery surface unless their descriptions are curated and their lifecycle authority is subordinate to the local harness.
- Prefer a small router or wrapper for session defaults instead of exposing many broad workflow descriptions.

## Description Quality

- Put trigger conditions in the description, not only in the body.
- Keep descriptions specific enough to route but narrow enough not to steal unrelated tasks.
- Avoid duplicate synonyms that describe the same trigger branch.
- Mark retired, experimental, or user-only workflows so they do not compete with active model-routed skills.

## Progressive Disclosure

- Keep `SKILL.md` procedural and short.
- Move details into directly linked `references/`, deterministic code into `scripts/`, and reusable output assets into `assets/`.
- Do not duplicate the same rule across AGENTS files, command wrappers, and skill bodies; pick one durable owner and point to it.
