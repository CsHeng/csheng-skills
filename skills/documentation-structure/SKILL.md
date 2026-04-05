---
name: documentation-structure
description: "Deprecated compatibility alias for older `documentation-structure` naming. Prefer `organize-docs` for doc maintenance and `analyze-project` for read-only project explanation. Activates for: documentation structure, legacy AGENTS.md/CLAUDE.md/README.md relationship requests, 文档结构。"
---

# Documentation Structure (legacy alias)

This skill remains available only as a deprecated compatibility bridge for older naming. Prefer the newer split directly:

- use `analyze-project` for read-only project-state explanation
- use `organize-docs` for doc organization, docs truth boundary maintenance, and audience separation

## Compatibility Rules

- `README.md` stays human-facing.
- `AGENTS.md` stays AI-facing.
- `CLAUDE.md` stays a symlink to `AGENTS.md`.
- Stable truth roots stay separate from stage artifacts.
- Default docs searches should respect the repository-local docs truth boundary.

## Handoff

- Route project-state questions to `analyze-project`.
- Route doc updates, structure cleanup, and stable-doc maintenance to `organize-docs`.
- Do not recreate a second full-size doc workflow here; this file is a legacy alias only.
