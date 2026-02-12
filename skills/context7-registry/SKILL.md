---
name: context7-registry
description: "Context7 (ctx7) skills registry CLI for discovering and installing external library documentation and AI coding skills. Activates for: ctx7, context7, library docs, external skills, ctx7 registry, context7 registry. 中文触发：ctx7、context7、库文档、外部技能。"
---

# Context7 Registry

## Purpose

Discover and install external AI coding skills and library documentation from the Context7 registry using the `ctx7` CLI.

## Scope

In-scope:
- Searching for library documentation skills
- Installing skills from Context7 registry
- Managing installed external skills

Out-of-scope:
- Local skill development (see plugin-dev skills)
- MCP server configuration

## Deterministic Steps

1. Search for skills
   - `npx ctx7 skills search {keyword}`
   - Example: `npx ctx7 skills search react`, `npx ctx7 skills search typescript`

2. View skill info before installing
   - `npx ctx7 skills info /org/project`

3. Install skills
   - Claude Code: `npx ctx7 skills install /org/project skill-name --claude`
   - Global: `npx ctx7 skills install /org/project skill-name --global`

4. List installed skills
   - `npx ctx7 skills list --claude`

5. Remove unused skills
   - `npx ctx7 skills remove skill-name --claude`

## Operational Commands (Examples)

```bash
# Search for React documentation
npx ctx7 skills search react

# View skill details
npx ctx7 skills info /vercel/next.js

# Install for Claude Code
npx ctx7 skills install /vercel/next.js nextjs-docs --claude

# List installed skills
npx ctx7 skills list --claude

# Remove a skill
npx ctx7 skills remove nextjs-docs --claude
```

## Shortcuts

- `ctx7 ss` = `ctx7 skills search`
- `ctx7 si` = `ctx7 skills install`

## When to Use

Use ctx7 when:
- Need documentation for a library not covered by local skills
- Want to discover community-maintained coding skills
- Looking for framework-specific guidance (React, Vue, Next.js, etc.)

Prefer local skills when:
- Skill already exists in development-skills plugin
- Need project-specific customization

## Checklist

- Search before installing to find best match
- Review skill info before installation
- Use `--claude` flag for Claude Code integration
- Remove unused skills to keep context clean
