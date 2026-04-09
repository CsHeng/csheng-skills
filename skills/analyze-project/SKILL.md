---
name: analyze-project
description: "Analyze a repository or subproject to explain what it does, what is implemented, where its boundaries live, how to operate it, and what gaps or drift signals remain. Activates for: analyze project, project state, repo state, 项目是干什么的, 当前完成了什么, 架构边界, 怎么用, 未完成项。"
---

# Analyze Project

Read stable project truth before answering recurring project-state questions.

## Use This Skill When

- the user asks what the project does
- the user asks what is implemented, in progress, or still missing
- the user asks where architecture or concept boundaries live
- the user asks how to operate, use, or validate the project
- the user needs a current-state explanation before deciding whether docs should be updated by `organize-docs`

## Do Not Use This Skill When

- the user wants to reorganize or update docs directly
- the user is asking for a design, plan, or code review workflow
- the user only wants local git or worktree status

## Workflow

1. Determine the `project` scope before reading deeply.
2. Load repository policy for the selected `project` scope by reading the most specific project-scoped `docs/AGENTS.md`, `AGENTS.md`, `docs/README.md`, and `README.md` first, then fall back outward as needed, along with local ignore files.
3. Separate stable truth roots from stage artifact roots before searching.
4. Judge document health as `healthy`, `degraded`, or `untrusted`.
5. Pick one basis for the run: `documentation-led`, `mixed verification`, or `code reconstruction`.
6. Read stable truth first, then do targeted read-only verification from code, commands, tests, or repository structure.
7. Produce the required sections from `references/output-contract.md`.
8. Emit drift signals and `recommended_action` values from `references/doc-health-and-drift.md` when stable truth is weak, conflicting, incomplete, or stale.
9. Stop after reporting. Use only the current `recommended_action` values `run-organize-docs`, `ask-human`, or `search-stage-artifacts-explicitly` instead of mutating docs directly.

## Operating Rules

- Use `project`, not `workspace`, as the analysis unit.
- Keep stable truth separate from stage artifacts during default search.
- Use stage artifacts only when the user explicitly asks for history or when stable truth is insufficient.
- Render file references relative to the selected project root; do not emit absolute filesystem paths in the report unless the user explicitly asks for them.
- Prefer context-appropriate relative file paths and command examples over absolute paths in reports and guidance.
- For Git projects, when a repo root needs to be made explicit, prefer `cd "$(git rev-parse --show-toplevel)"` before relative commands.
- Report both document health and the basis used for the run.
- Label each major conclusion as `documented`, `verified`, `inferred`, or `uncertain`.
- Emit the compact conclusion once only and do not repeat section headings later in the same report.
- Format the report for scanability with Markdown bullets and nested bullets, not dense semicolon-packed lines.
- Keep each top-level finding to one short summary line, then move refs and supporting detail into nested bullets.
- Do not append inline `参考 ...` lists to summary sentences; render evidence under nested `refs`, `stable_source_refs`, or `verification_refs` bullets instead.
- In `Open Gaps / Drift Signals`, emit one drift signal per multi-line bullet block and put each field on its own line.
- Keep `stable_source_refs` and `verification_refs` as indented vertical lists with one context-appropriate relative `path:line` file reference per bullet.
- Keep the result read-only; do not rewrite stable docs from this skill.

## References

- `references/output-contract.md`
- `references/doc-health-and-drift.md`
