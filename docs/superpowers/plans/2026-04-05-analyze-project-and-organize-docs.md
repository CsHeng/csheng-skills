# Analyze Project And Organize Docs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a read-only `analyze-project` skill, add an `organize-docs` skill for documentation maintenance, and validate the design in this repository with an explicit docs truth-boundary example.

**Architecture:** Keep the first implementation lightweight and text-first. Introduce two new skill entry points, make `organize-docs` the sole doc-maintenance path, and add a small shell smoke check plus docs policy files so this repository demonstrates stable-truth vs stage-artifact boundaries in a way `analyze-project` can consume.

**Tech Stack:** Markdown skill files, repository docs (`README.md`, `AGENTS.md`, `docs/`), `rg`, `bash`, and a small shell smoke check

---

## Upstream Design

- design_ref: docs/superpowers/specs/2026-04-05-analyze-project-and-organize-docs-design.md
- design_version: 2026-04-05-docs-alignment-follow-up

## Implementation Scope

- scope_slice: First-phase repo-local delivery of the `analyze-project` and `organize-docs` split, including docs truth-boundary files and root inventory updates.
- impl_file_refs:
  - AGENTS.md
  - README.md
  - docs/.ignore
  - docs/AGENTS.md
  - docs/README.md
  - skills/analyze-project/SKILL.md
  - skills/analyze-project/references/doc-health-and-drift.md
  - skills/analyze-project/references/output-contract.md
  - skills/organize-docs/SKILL.md
  - skills/organize-docs/scripts/check-doc-boundaries.sh
- test_file_refs:
  - skills/organize-docs/scripts/check-doc-boundaries.sh
- verification_scope:
  - `bash -n skills/organize-docs/scripts/check-doc-boundaries.sh`
  - `bash skills/organize-docs/scripts/check-doc-boundaries.sh`
  - `rg -n "^name: analyze-project|^name: organize-docs" skills/analyze-project/SKILL.md skills/organize-docs/SKILL.md`
  - `rg -n "Project Summary|Truth Map|How To Operate|Current Status|stable truth|stage artifact|code reconstruction" skills/analyze-project/SKILL.md skills/analyze-project/references/output-contract.md skills/analyze-project/references/doc-health-and-drift.md skills/organize-docs/SKILL.md`
  - `rg -n "analyze-project|organize-docs" README.md AGENTS.md docs/AGENTS.md docs/README.md`
  - `rg -n "Analyze Project And Organize Docs Design" docs >/dev/null; test $? -eq 1`
  - `rg --no-ignore -n "Analyze Project And Organize Docs Design" docs/superpowers >/dev/null`
  - `git diff --check`
- out_of_scope:
  - review harness driver behavior under `skills/_review-libs/`
  - plugin manifest/version metadata under `.claude-plugin/`
  - repository-wide workflow changes unrelated to the project-analysis versus docs-organization split
- divergence_from_design: none

---

## File Structure

- `skills/analyze-project/SKILL.md`
  New read-only skill for project explanation, document-health judgment, truth-map output, and drift signaling.
- `skills/analyze-project/references/output-contract.md`
  Compact reference for required output sections, conclusion labels, and drift signal fields.
- `skills/analyze-project/references/doc-health-and-drift.md`
  Definitions for document health (`healthy`, `degraded`, `untrusted`) and when to use `documentation-led`, `mixed verification`, or `code reconstruction`.
- `skills/organize-docs/SKILL.md`
  New write/update skill that owns stable truth roots, stage artifact boundaries, and audience separation.
- `skills/organize-docs/scripts/check-doc-boundaries.sh`
  Lightweight smoke check for docs boundary files and default-search behavior.
- `README.md`
  Skill inventory and human-facing documentation notes for the new query/update split.
- `AGENTS.md`
  AI-facing repository notes describing the docs truth boundary for this repository.
- `docs/.ignore`
  Explicit docs-local search exclusions for stage artifacts such as `plans/` and `superpowers/`.
- `docs/AGENTS.md`
  AI-facing docs policy for stable truth, stage artifacts, and default search rules.
- `docs/README.md`
  Human-facing docs note explaining that default docs searches avoid stage artifacts and history requires explicit search.

### Task 1: Establish Docs Truth Boundary And Smoke Validation

**Files:**
- Create: `skills/organize-docs/scripts/check-doc-boundaries.sh`
- Create: `docs/.ignore`
- Create: `docs/AGENTS.md`
- Create: `docs/README.md`
- Test: `skills/organize-docs/scripts/check-doc-boundaries.sh`

- [ ] **Step 1: Write a failing shell smoke check for docs boundary policy**

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DOCS_DIR="$ROOT_DIR/docs"

[[ -f "$DOCS_DIR/.ignore" ]] || { echo "missing docs/.ignore" >&2; exit 1; }
rg -qx 'plans/' "$DOCS_DIR/.ignore"
rg -qx 'superpowers/' "$DOCS_DIR/.ignore"

[[ -f "$DOCS_DIR/AGENTS.md" ]] || { echo "missing docs/AGENTS.md" >&2; exit 1; }
[[ -f "$DOCS_DIR/README.md" ]] || { echo "missing docs/README.md" >&2; exit 1; }

rg -n "stable truth|stage artifact|--no-ignore|git add -f" \
  "$DOCS_DIR/AGENTS.md" \
  "$DOCS_DIR/README.md" >/dev/null

if rg -n "Analyze Project And Organize Docs Design" "$DOCS_DIR" >/dev/null; then
  echo "default docs search unexpectedly hit stage artifacts" >&2
  exit 1
fi

rg --no-ignore -n "Analyze Project And Organize Docs Design" "$DOCS_DIR/superpowers" >/dev/null
```

- [ ] **Step 2: Run the smoke check and verify it fails because the docs boundary files do not exist yet**

Run: `bash skills/organize-docs/scripts/check-doc-boundaries.sh`  
Expected: FAIL with `missing docs/.ignore`, `missing docs/AGENTS.md`, or `missing docs/README.md`

- [ ] **Step 3: Add docs-local ignore policy and docs-facing guidance**

```gitignore
# Stage artifacts stay in Git for history but should not pollute default docs search.
plans/
superpowers/
```

```markdown
# Docs Agent Notes

## Truth Boundary

- Treat `docs/` as the home of long-lived project truth unless a more specific local rule says otherwise.
- Treat `docs/plans/` and `docs/superpowers/` as stage artifacts and history, not default current-state truth.
- Default docs searches should target active truth docs first and avoid stage artifacts.

## Search Policy

- Default docs search: `rg -n "pattern" docs`
- Historical docs search: `rg --no-ignore -n "pattern" docs/plans docs/superpowers`
- If `grep` is required, use `grep -R --exclude-dir=plans --exclude-dir=superpowers "pattern" docs`

## Git Note

- Stage artifacts may still be intentionally versioned. If the repository keeps them ignored, use `git add -f <path>` when you intentionally want one tracked.
```

```markdown
# Docs

This directory mixes long-lived reference notes with stage artifacts kept for history.

## Search Defaults

- Default docs searches should avoid `docs/plans/` and `docs/superpowers/`.
- Search those directories only when you explicitly need history, evolution, or dispute resolution.
- Use `rg --no-ignore -n "pattern" docs/plans docs/superpowers` for historical search.
```

- [ ] **Step 4: Re-run the smoke check and verify docs search now respects the boundary contract**

Run: `bash skills/organize-docs/scripts/check-doc-boundaries.sh`  
Expected: PASS with no output

- [ ] **Step 5: Commit the docs boundary baseline**

```bash
git add \
  skills/organize-docs/scripts/check-doc-boundaries.sh \
  docs/.ignore \
  docs/AGENTS.md \
  docs/README.md
git commit -m "docs: define docs truth boundary"
```

### Task 2: Create The Analyze Project Query Skill

**Files:**
- Create: `skills/analyze-project/SKILL.md`
- Create: `skills/analyze-project/references/output-contract.md`
- Create: `skills/analyze-project/references/doc-health-and-drift.md`
- Test: `skills/analyze-project/SKILL.md`

- [ ] **Step 1: Add a failing grep check for the required analyze-project contract**

```bash
rg -n "Project Summary|Truth Map|Architecture Boundaries|How To Operate|Current Status|doc_code_mismatch|code reconstruction" \
  skills/analyze-project/SKILL.md \
  skills/analyze-project/references/output-contract.md \
  skills/analyze-project/references/doc-health-and-drift.md >/dev/null
```

- [ ] **Step 2: Run the grep check and verify it fails because analyze-project does not exist yet**

Run: `rg -n "Project Summary|Truth Map|Architecture Boundaries|How To Operate|Current Status|doc_code_mismatch|code reconstruction" skills/analyze-project/SKILL.md skills/analyze-project/references/output-contract.md skills/analyze-project/references/doc-health-and-drift.md >/dev/null`  
Expected: FAIL with exit code `2` or `1` because the files do not exist yet

- [ ] **Step 3: Create the analyze-project skill and its references**

```markdown
---
name: analyze-project
description: "Analyze a repository or subproject to explain what it does, what is implemented, where its boundaries live, how to operate it, and what gaps or drift signals remain. Activates for: analyze project, project state, repo state, 项目是干什么的, 当前完成了什么, 架构边界, 怎么用, 未完成项。"
---

# Analyze Project

Read stable project truth before answering recurring project-state questions.

## Use This Skill When

- the user asks what the project does
- the user asks what is implemented or still missing
- the user asks where architecture or concept boundaries live
- the user asks how to operate, use, or validate the project
- the user needs a current-state explanation before deciding whether docs should be updated

## Do Not Use This Skill When

- the user wants to reorganize or update docs directly
- the user is asking for a design, plan, or code review workflow
- the user only wants local git or worktree status

## Workflow

1. Determine the `project` scope before reading any files.
2. Load repository policy from `docs/AGENTS.md`, `AGENTS.md`, `README.md`, and docs-local ignore files.
3. Separate stable truth roots from stage artifact roots before searching.
4. Judge document health as `healthy`, `degraded`, or `untrusted`.
5. Pick one basis for the run: `documentation-led`, `mixed verification`, or `code reconstruction`.
6. Read stable truth docs first, then do targeted read-only verification from code, commands, tests, or repository structure.
7. Produce the required output sections from `references/output-contract.md`.
8. Emit drift signals from `references/doc-health-and-drift.md` when stable truth is weak, conflicting, incomplete, or stale.
9. Stop after reporting. Recommend `organize-docs` instead of mutating docs directly.

## References

- `references/output-contract.md`
- `references/doc-health-and-drift.md`
```

```markdown
# Output Contract

## Required Sections

- `Project Summary`
- `Truth Map`
- `Architecture Boundaries`
- `How To Operate`
- `Current Status`
- `Open Gaps / Drift Signals`

## Conclusion Labels

- `documented`
- `verified`
- `inferred`
- `uncertain`

## Current Status Categories

- `implemented`
- `in progress`
- `planned`
- `unverified`
- `not in scope`

## Drift Signal Fields

- `type`
- `severity`
- `summary`
- `stable_source_refs`
- `verification_refs`
- `recommended_action`
```

```markdown
# Document Health And Drift

## Document Health

- `healthy`: stable docs are largely consistent and cover the key questions
- `degraded`: stable docs are useful but have gaps, stale areas, or local conflicts
- `untrusted`: stable docs are too incomplete or conflicting to anchor the answer

## Basis Used For The Run

- `documentation-led`
- `mixed verification`
- `code reconstruction`

## Required Drift Types

- `doc_code_mismatch`
- `doc_doc_conflict`
- `truth_gap`
- `stage_artifact_pressure`
- `stale_operation`

## Allowed Recommended Actions

- `run-organize-docs`
- `ask-human`
- `search-stage-artifacts-explicitly`
```

- [ ] **Step 4: Re-run the grep check and verify the analyze-project contract is present**

Run: `rg -n "Project Summary|Truth Map|Architecture Boundaries|How To Operate|Current Status|doc_code_mismatch|code reconstruction" skills/analyze-project/SKILL.md skills/analyze-project/references/output-contract.md skills/analyze-project/references/doc-health-and-drift.md >/dev/null`  
Expected: PASS with exit code `0`

- [ ] **Step 5: Commit the analyze-project baseline**

```bash
git add \
  skills/analyze-project/SKILL.md \
  skills/analyze-project/references/output-contract.md \
  skills/analyze-project/references/doc-health-and-drift.md
git commit -m "feat: add analyze-project skill"
```

### Task 3: Create The Organize Docs Maintenance Skill

**Files:**
- Create: `skills/organize-docs/SKILL.md`
- Modify: `skills/organize-docs/scripts/check-doc-boundaries.sh`
- Test: `skills/organize-docs/SKILL.md`

- [ ] **Step 1: Add a failing grep check for organize-docs responsibilities**

```bash
rg -n "stable truth|stage artifact|docs/.ignore|CLAUDE.md|analyze-project|search-boundary" \
  skills/organize-docs/SKILL.md >/dev/null
```

- [ ] **Step 2: Run the grep check and verify it fails because organize-docs does not exist yet**

Run: `rg -n "stable truth|stage artifact|docs/.ignore|CLAUDE.md|analyze-project|search-boundary" skills/organize-docs/SKILL.md >/dev/null`  
Expected: FAIL with exit code `2` or `1`

- [ ] **Step 3: Create organize-docs as the write/update documentation skill**

```markdown
---
name: organize-docs
description: "Maintain project documentation structure, stable truth roots, search boundaries, and audience separation without taking over read-only project explanation. Activates for: organize docs, maintain docs, truth boundary, docs layout, README.md, AGENTS.md, CLAUDE.md, 文档整理, 文档结构, 文档边界。"
---

# Organize Docs

Maintain long-lived project truth after explicit user request or explicit drift follow-up from `analyze-project`.

## Core Rules

- `README.md` stays human-facing.
- `AGENTS.md` stays AI-facing.
- `CLAUDE.md` remains a symlink to `AGENTS.md`.
- Stable truth roots and stage artifact roots must be explicit.
- Default docs search should avoid stage artifacts when the repository needs that boundary.

## Workflow

1. Assess the current doc layout: `README.md`, `AGENTS.md`, `CLAUDE.md`, `docs/`, and any docs policy files.
2. Classify stable truth roots versus stage artifact roots.
3. Preserve or establish docs-local ignore/search policy such as `docs/.ignore` when history should stay out of default search.
4. Move AI-facing content into `AGENTS.md` and human-facing content into `README.md`.
5. Keep long-lived truth in stable docs domains and avoid treating plans/drafts/history as default truth.
6. Update stable docs only after explicit user approval or explicit drift follow-up from `analyze-project`.

## Do Not Use This Skill For

- routine project-state explanation
- replacing `analyze-project` as the default query entry point
- silently rewriting truth from implementation guesses alone

## Validation

- run `bash skills/organize-docs/scripts/check-doc-boundaries.sh` when docs truth boundaries are part of the change
```

- [ ] **Step 4: Re-run the grep check and verify organize-docs now captures the maintenance contract**

Run: `rg -n "stable truth|stage artifact|docs/.ignore|CLAUDE.md|analyze-project|search-boundary" skills/organize-docs/SKILL.md >/dev/null`  
Expected: PASS with exit code `0`

- [ ] **Step 5: Commit the organize-docs skill**

```bash
git add \
  skills/organize-docs/SKILL.md \
  skills/organize-docs/scripts/check-doc-boundaries.sh
git commit -m "feat: add organize-docs skill"
```

### Task 4: Refresh Repository Inventory For The New Split

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`
- Test: `README.md`
- Test: `AGENTS.md`

- [ ] **Step 1: Add a failing grep check for the new query/update split**

```bash
rg -n "analyze-project|organize-docs|docs truth boundary" \
  README.md \
  AGENTS.md >/dev/null
```

- [ ] **Step 2: Run the grep check and verify it fails before the inventory refresh**

Run: `rg -n "analyze-project|organize-docs|docs truth boundary" README.md AGENTS.md >/dev/null`
Expected: FAIL with exit code `1`

- [ ] **Step 3: Update the root README and AGENTS inventory**

```markdown
- use `analyze-project` for read-only project-state explanation
- use `organize-docs` for doc organization, truth-boundary maintenance, and audience separation
```

- [ ] **Step 4: Update the root README and AGENTS inventory**

```markdown
- `analyze-project`: Read-only project explanation and drift detection across stable docs, code verification, and explicit historical search when needed.
- `organize-docs`: Stable-doc maintenance, docs truth boundaries, audience separation, and docs search policy.
```

```markdown
## Documentation Truth Boundary

- Long-lived project truth lives in root reference files plus stable `docs/` domains.
- `docs/plans/` and `docs/superpowers/` are stage artifacts in this repository and should stay out of default docs searches.
- Use `docs/.ignore` and `docs/AGENTS.md` as the repository-local contract for docs search behavior.
```

- [ ] **Step 5: Re-run the grep check and verify the split is visible to both humans and agents**

Run: `rg -n "analyze-project|organize-docs|docs truth boundary" README.md AGENTS.md >/dev/null`
Expected: PASS with exit code `0`

- [ ] **Step 6: Commit the inventory refresh**

```bash
git add \
  README.md \
  AGENTS.md
git commit -m "docs: split project analysis from doc organization"
```

### Task 5: Run Final Validation And Leave The Repo Ready For Execution

**Files:**
- Test: `skills/organize-docs/scripts/check-doc-boundaries.sh`
- Test: `skills/analyze-project/SKILL.md`
- Test: `skills/organize-docs/SKILL.md`
- Test: `README.md`
- Test: `AGENTS.md`

- [ ] **Step 1: Validate the docs boundary smoke check and shell syntax**

Run: `bash -n skills/organize-docs/scripts/check-doc-boundaries.sh`  
Expected: PASS with no output

Run: `bash skills/organize-docs/scripts/check-doc-boundaries.sh`  
Expected: PASS with no output

- [ ] **Step 2: Validate the skill files expose the required names and contracts**

Run: `rg -n "^name: analyze-project|^name: organize-docs" skills/analyze-project/SKILL.md skills/organize-docs/SKILL.md`
Expected: PASS with one hit per expected skill

Run: `rg -n "Project Summary|Truth Map|How To Operate|Current Status|stable truth|stage artifact|code reconstruction" skills/analyze-project/SKILL.md skills/analyze-project/references/output-contract.md skills/analyze-project/references/doc-health-and-drift.md skills/organize-docs/SKILL.md`  
Expected: PASS with hits for the query contract and docs maintenance rules

- [ ] **Step 3: Validate repository docs and historical-search behavior**

Run: `rg -n "analyze-project|organize-docs" README.md AGENTS.md docs/AGENTS.md docs/README.md`
Expected: PASS with inventory and boundary notes in both root and docs-local files

Run: `rg -n "Analyze Project And Organize Docs Design" docs >/dev/null; test $? -eq 1`  
Expected: PASS because default docs search should skip stage artifacts

Run: `rg --no-ignore -n "Analyze Project And Organize Docs Design" docs/superpowers >/dev/null`  
Expected: PASS because explicit historical search should still find the spec

- [ ] **Step 4: Check for whitespace/merge issues**

Run: `git diff --check`  
Expected: PASS with no output

- [ ] **Step 5: Confirm the repository is clean after the task commits**

Run: `git status --short`  
Expected: PASS with no output because each task already committed its own slice

## Self-Review

- Spec coverage:
  - add `analyze-project` as the default query entry point: covered in Tasks 2 and 4
  - add `organize-docs` as the write/update successor: covered in Tasks 3 and 4
  - distinguish stable truth from stage artifacts: covered in Tasks 1, 3, and 4
  - exclude stage artifacts from default search: covered in Tasks 1 and 5
  - report document health and analysis basis: covered in Task 2
  - emit structured output sections and drift signals: covered in Task 2
  - avoid auto-updating docs from analyze-project: covered in Tasks 2 and 3
  - leave a clean path toward decision tree plus DAG: covered by the split in Tasks 2 through 4
- Placeholder scan:
  - no `TODO`, `TBD`, or deferred filler remains
  - every task names exact files, commands, and expected outputs
  - every code-writing step includes concrete file content snippets instead of generic directions
- Type consistency:
  - the query skill is named `analyze-project` everywhere
  - the write/update skill is named `organize-docs` everywhere
  - the health states stay `healthy`, `degraded`, and `untrusted`
  - the analysis bases stay `documentation-led`, `mixed verification`, and `code reconstruction`
