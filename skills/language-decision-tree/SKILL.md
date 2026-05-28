---
name: language-decision-tree
description: "Use when choosing an implementation language for new scripts, tools, automation, or services where no project default is fixed."
---

# Language Decision Tree

## Purpose

Canonical language selection logic for new code. Use when the target language is not already dictated by existing files or interfaces.

## Step 1: Is the language already fixed?

If modifying existing code, choose the language already used:
- `.py` / Python project tooling present -> Python
- `.sh` / `.bash` / `.zsh` -> Shell
- `.go` / `go.mod` present -> Go
- `.lua` -> Lua

Follow the project's dominant language/tooling unless there is a documented exception.

## Step 2: New code / new automation

Select the simplest language that satisfies correctness, maintainability, and testability.

Use Shell for:
- Short, linear orchestration and glue (paths, env setup, delegating to other CLIs)
- Simple pipelines where auditability on one screen matters

Use Python for:
- Branching/stateful workflows, validation, structured data, non-trivial parsing
- Reusable CLIs, automation that should be testable as importable modules

Use Go for:
- Long-lived services, performance-critical or highly-concurrent workloads
- CLIs where a static binary is valuable (distribution, startup time, dependency-free)

Use Lua for:
- Editing or extending existing Lua codebases and Lua-based configuration ecosystems
  (WezTerm, Hammerspoon, Rime, Neovim tooling)
- PROHIBITED: Introduce Lua as a general-purpose automation language when Python/Shell/Go is the established stack

## Step 3: Hybrid (Shell + Python/Go) boundaries

When multiple languages are used, enforce strict ownership:
- Shell owns environment discovery and orchestration only.
- Python/Go owns validation, parsing, and business logic.

PROHIBITED: Inline Python in shell (no `python -c` and no here-doc Python blocks).
REQUIRED: Call Python via `python -m package.module ...` (or an approved uv-managed entrypoint).
REQUIRED: Keep business rules in the primary language module so they can be tested directly.
PROHIBITED: Split the same business rule across multiple languages.

## Recording

REQUIRED: Record the chosen language in the implementation plan/output whenever new code is introduced.
REQUIRED: If selecting a non-preferred language due to hard constraints, document the constraint and rationale.
