---
name: language-decision-tree
description: "Use during design or planning when a new persisted project, tool, automation surface, service, or approved migration needs an implementation-language decision. Do not use for agent ad hoc command choice or ordinary edits whose language is already fixed."
---

# Language Decision Tree

## Purpose

Choose the implementation language for a new persisted code boundary before implementation begins. This is a planning policy overlay, not a lifecycle controller and not an ad hoc command-selection guide.

## Scope

Use this skill when design or planning introduces:

- a new project, persisted script, CLI, tool, service, or automation surface
- a temporary prototype that is being promoted into maintained repository code
- an approved migration or rewrite that may change implementation language

Do not use this skill for:

- agent ad hoc command composition; use `tool-decision-tree`
- ordinary changes to existing `.py`, `.sh`, `.go`, `.lua`, or other language-owned code
- choosing a search, parsing, formatting, or refactoring utility for the current session

## Step 1: Preserve Fixed Boundaries

When modifying an existing implementation, preserve its established language and tooling unless an approved design changes that boundary. A nearby file extension alone does not authorize a rewrite.

Treat recurring runtime or dependency incidents, multi-host or multi-architecture distribution cost, concurrency or performance constraints, and growth from thin orchestration into a maintained operational tool as migration signals. They are evidence for design, not automatic rewrite permission.

## Step 2: Classify The Persisted Implementation

Use Shell for:

- short, linear orchestration and glue
- environment discovery, bootstrap, or delegation to existing CLIs
- simple pipelines whose complete control flow remains easy to audit

Prefer Go for:

- long-lived operational CLIs and tools whose distribution benefits from a single binary
- API or network services, exporters, collectors, controllers, and concurrent agents
- cross-host or cross-platform tools where runtime and dependency state should stay small
- state-changing tools that need stable flags, exit codes, completion, tests, and release artifacts

Use Python when:

- an existing Python project or provider SDK owns the integration boundary
- data processing, scientific, media, or other Python ecosystems materially reduce implementation risk
- the work is a bounded batch, migration, audit, test, or configuration transformation with an explicit Python runtime contract

Use Lua when:

- extending an existing Lua codebase or Lua-based configuration ecosystem such as WezTerm, Hammerspoon, Rime, or Neovim
- PROHIBITED: introducing Lua as general-purpose automation when another established project language owns the boundary

These are preferences, not global mandates. Repository-local architecture and runtime contracts take precedence.

## Step 3: Define Hybrid Ownership

When a persisted implementation uses multiple languages:

- Shell owns environment discovery and orchestration only.
- The selected primary implementation owns validation, parsing, state, and business rules.
- Do not split one business rule across multiple languages.
- Keep language boundaries callable and testable without relying on generated command strings.

## Recording

For each new or migrated persisted implementation boundary, record:

- `implementation_archetype`
- `implementation_language`
- `language_rationale`

If a repository-preferred language is not selected, record the hard constraint or ecosystem advantage that controls the decision. Ordinary existing-language tasks do not need placeholder language metadata.
