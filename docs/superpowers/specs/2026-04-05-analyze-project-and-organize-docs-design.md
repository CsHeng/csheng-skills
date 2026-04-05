# Analyze Project And Organize Docs Design

## Status

Proposed and approved in interactive brainstorming on 2026-04-05.

## Problem

The current skill set is strong on implementation guidance, review, and document structure, but it does not yet provide a stable cross-repository harness for answering a recurring class of questions:

- what is this project for
- what is already implemented
- where are the architecture and concept boundaries
- how do I operate or use it
- what is still missing

Today those answers are vulnerable to drift for two reasons:

1. Query and update responsibilities are mixed together. A structure-oriented documentation skill is not the right default entry point for read-only project explanation.
2. Repositories often retain stage-specific artifacts in Git, such as plans, drafts, design notes, and implementation notes. Those artifacts are useful history, but they should not pollute default search and explanation flows.

The result is predictable:

- agents over-read temporary planning artifacts when answering current-state questions
- stable documentation and implementation can drift without a clear read-path for detection
- users must repeatedly re-explain which files count as durable truth and which files are only historical context
- skill behavior becomes less composable because read/query workflows and write/update workflows are not explicitly separated

## Goals

- Add a reusable `analyze-project` skill as the default query entry point for project explanation.
- Separate read/query behavior from write/update behavior.
- Preserve long-lived project truth in stable `docs/` domains while keeping stage artifacts in Git.
- Make default search behavior exclude stage artifacts unless history is explicitly requested.
- Support dynamic evidence weighting based on documentation health rather than a rigid "docs first no matter what" rule.
- Keep the first version lightweight and cross-repository, without introducing a central metadata registry.
- Prepare the skill system to evolve toward an explicit `decision tree + artifact DAG` harness.

## Non-Goals

- Do not auto-update stable docs from `analyze-project`.
- Do not treat code as the automatic new source of truth when docs are weak or conflicting.
- Do not hardcode one universal docs directory taxonomy for every repository.
- Do not overload this design with worktree, git-dirty-state, or general workspace-status concerns.
- Do not replace design/plan/code review flows with project-state analysis.

## Decision Summary

Introduce two distinct skills with a fixed cooperation boundary:

- `analyze-project`: read-only project explanation and drift detection
- `organize-docs`: document structure, truth-boundary, and stable-doc maintenance

The stable project truth model is:

- long-lived truth lives in stable `docs/` domains plus root reference files such as `README.md`, `AGENTS.md`, and `docs/AGENTS.md`
- stage artifacts remain in Git but are excluded from default search and explanation flows
- stage artifacts may be used only as explicit historical evidence or when stable truth is insufficient

`analyze-project` does not always use the same evidence order. It first judges documentation health, then chooses one of three analysis modes:

- documentation-led
- mixed verification
- code reconstruction

Even in code-reconstruction mode, the skill does not rewrite stable truth automatically. It only produces evidence-backed drift signals and recommended next actions.

## Naming Decisions

### Query Skill

Use `analyze-project` as the primary read/query skill name.

Reasons:

- the verb signals read-only analysis rather than mutation
- `project` matches the intended unit better than `workspace`
- the name scales across single-repo, monorepo, and subproject contexts

### Update Skill

Use `organize-docs` as the primary write/update skill name.

Reasons:

- it describes document structure and long-lived truth maintenance directly
- it is a better counterpart to `analyze-project` than `documentation-structure`
- it keeps read and write entry points visibly separate

Migration note:

- the existing `documentation-structure` skill should evolve into or be replaced by `organize-docs`
- a compatibility bridge is acceptable during migration, but the long-term name should be `organize-docs`

## Project Scope Model

The harness should use `project` as the unit of analysis and stop using `workspace` as the top-level concept for this problem.

`project` may mean:

- the repository root
- a declared subproject inside a monorepo
- a nested product or service boundary with its own docs and code surface

`analyze-project` must declare which project scope it analyzed before summarizing anything else.

## Stable Truth And Stage Artifact Model

### Stable Truth

Stable truth consists of long-lived documents that are intended to describe the project as it exists or should continue to exist.

Typical examples:

- `docs/architecture/`
- `docs/design/`
- `docs/guides/`
- `docs/troubleshooting/`
- `docs/debug/`
- `README.md`
- `AGENTS.md`
- `docs/AGENTS.md`

These are examples, not a universal fixed taxonomy. Repository-local policy is allowed to redefine the stable set.

### Stage Artifacts

Stage artifacts are intermediate or historical documents that remain useful for audit and history but should not shape default current-state explanations.

Typical examples:

- `docs/plans/`
- `docs/superpowers/`
- `docs/drafts/`
- dated files like `YYYY-MM-DD-<topic>-plan.md`
- dated files like `YYYY-MM-DD-<topic>-design.md`
- dated files like `YYYY-MM-DD-<topic>-impl.md`
- review-only or batch-specific task artifacts

The harness must not assume that every file containing `design` is a stage artifact. A stable `docs/design/` area may exist and remain part of long-lived truth.

### Classification Priority

When deciding whether a document is stable truth or a stage artifact, use this order:

1. repository-explicit policy
2. directory role
3. filename pattern
4. content hints

Repository-explicit policy has highest priority. If a repository says a path is stable or historical, that instruction wins.

## Search Policy

Default search behavior must avoid stage artifacts.

The repository should express this through local ignore policy when possible, for example:

- `docs/.ignore`
- `.ignore`
- `.rgignore`
- `.fdignore`

The analysis harness should treat those ignore rules as part of the project's truth-boundary contract.

Default behavior:

- search stable truth first
- do not read stage artifacts by default
- only enter stage artifacts when the user explicitly asks for history, evolution, or dispute resolution
- if explicit historical search is required, use commands such as `rg --no-ignore`

This makes the difference between "current truth" and "historical context" operational instead of implicit.

## Analyze Project Workflow

### Purpose

`analyze-project` is the default read-only skill for answering:

- what the project does
- what is implemented
- where the boundaries are
- how to use or operate it
- what remains unclear, missing, or drifting

### Workflow

1. Determine the `project` scope.
2. Load repository policy that defines stable truth roots and stage artifact roots.
3. Read root references such as `README.md`, `AGENTS.md`, and `docs/AGENTS.md`.
4. Assess documentation health.
5. Choose the analysis basis for this run:
   - documentation-led
   - mixed verification
   - code reconstruction
6. Read stable truth docs using default ignore-aware search.
7. Perform targeted read-only verification from code, commands, tests, or repository structure.
8. Produce structured project explanation.
9. Emit drift signals when stable truth appears weak, conflicting, incomplete, or stale.
10. Stop. Do not update documentation automatically.

## Documentation Health

Before weighting evidence, `analyze-project` must judge documentation health as one of:

- `healthy`
- `degraded`
- `untrusted`

Interpretation:

- `healthy`: stable docs are largely consistent, key questions are covered, and operation guidance appears usable
- `degraded`: stable docs still provide useful direction, but there are gaps, local conflicts, or stale areas
- `untrusted`: stable docs are too incomplete, conflicting, or stale to anchor explanation reliably

The skill must report both:

- document health
- the basis used for this run

The basis should be expressed directly, not through abstract jargon:

- `documentation-led`
- `mixed verification`
- `code reconstruction`

## Analyze Project Output Contract

`analyze-project` should produce a compact conclusion first, then a structured report.

Required output sections:

- `Project Summary`
- `Truth Map`
- `Architecture Boundaries`
- `How To Operate`
- `Current Status`
- `Open Gaps / Drift Signals`

Each major conclusion should be labeled as:

- `documented`
- `verified`
- `inferred`
- `uncertain`

This keeps the output readable for humans while preserving evidence quality for later harness integration.

### Truth Map

`Truth Map` should explicitly declare:

- analyzed `project scope`
- stable truth roots
- stage artifact roots
- root reference files
- search policy used for this run

### Current Status

Avoid vague maturity percentages. Use explicit engineering slices:

- `implemented`
- `in progress`
- `planned`
- `unverified`
- `not in scope`

## Drift Signals

Drift signals do not mean "the docs are definitely wrong". They mean stable truth needs human review.

Required drift signal types:

- `doc_code_mismatch`
- `doc_doc_conflict`
- `truth_gap`
- `phase_artifact_pressure`
- `stale_operation`

Each drift signal should minimally include:

- `type`
- `severity`
- `summary`
- `stable_source_refs`
- `verification_refs`
- `recommended_action`

Allowed `recommended_action` values:

- `review-docs`
- `run-organize-docs`
- `ask-human`
- `search-phase-artifacts-explicitly`

## Organize Docs Workflow

### Purpose

`organize-docs` maintains the stable truth layer and the structure around it.

Responsibilities:

- organize `README.md`, `AGENTS.md`, `CLAUDE.md`, and `docs/`
- define or preserve stable truth roots
- define or preserve stage artifact roots
- maintain ignore and search-boundary behavior
- move or summarize content into the correct long-lived domains
- update stable docs after explicit user approval or explicit drift follow-up

### Non-Responsibilities

`organize-docs` should not become the default skill for explaining project state.

It should not:

- answer current-state questions as its main job
- silently replace `analyze-project`
- treat every doc update request as permission to redefine project truth from scratch

## Cooperation Contract

The fixed chain is:

`analyze-project -> detect drift -> optional organize-docs`

Rules:

- `analyze-project` is the normal query entry point
- `organize-docs` is entered only when requested explicitly or when drift follow-up is needed
- `analyze-project` may recommend doc work, but it must not perform it automatically
- `organize-docs` should consume the drift evidence rather than rediscovering the entire problem from zero

## Relation To Existing Review Harness

This design does not replace the current review harness. It complements it.

Current strong path:

`design -> plan -> code review`

New complementary path:

`truth docs -> analyze-project output -> drift signals -> organize-docs -> truth docs`

The two paths should remain distinct but compatible.

## Decision Tree Direction

Long term, the skill system should evolve from a flat list of skills toward an explicit decision tree.

At minimum, the tree should route:

- project explanation questions -> `analyze-project`
- documentation maintenance questions -> `organize-docs`
- historical evolution questions -> `analyze-project` with explicit stage-artifact search
- design/plan/code review questions -> existing review skills

The decision tree answers: which skill should run now.

## Artifact DAG Direction

Long term, the skill system should also evolve toward a light artifact DAG.

Initial edges should be:

- `truth docs -> analyze-project output`
- `analyze-project drift signals -> organize-docs input`
- `organize-docs update -> truth docs`
- `truth docs + design -> plan -> code review`

Rules:

- stage artifacts may support analysis as evidence, but they do not become stable truth automatically
- code-reconstruction mode can explain a project when truth is weak, but it does not mutate truth by itself
- stable truth updates remain explicit and reviewable

## Risks

- repositories may not declare stable truth roots clearly enough
- ignore policy may be inconsistent across `rg`, `fd`, and human expectations
- some repos may blur stable design docs and stage design docs in the same area
- users may over-trust code-reconstruction output and skip the doc-maintenance step
- a compatibility period between `documentation-structure` and `organize-docs` may create temporary naming ambiguity

## Files

First-phase implementation should create or update:

- `skills/analyze-project/SKILL.md`
- `skills/organize-docs/SKILL.md`
- compatibility handling for `skills/documentation-structure/` if migration is incremental
- repository documentation that explains stable truth roots and stage artifact search boundaries

## Acceptance Criteria

- A read-only skill named `analyze-project` exists and is the default entry for project-state explanation.
- A write/update skill named `organize-docs` exists or is clearly defined as the successor to `documentation-structure`.
- The design explicitly distinguishes stable truth from stage artifacts.
- Default search behavior excludes stage artifacts unless historical search is explicitly requested.
- `analyze-project` reports document health and the basis used for the current analysis run.
- `analyze-project` outputs the required project-state sections and drift signals.
- `analyze-project` does not auto-update docs.
- `organize-docs` is positioned as the drift follow-up and truth-maintenance path rather than the default explanation path.
- The design leaves a clean path toward a future `decision tree + artifact DAG` harness without requiring a central registry now.

## Follow-Up Work

The next planning phase should define:

- exact trigger wording and frontmatter for `analyze-project`
- how `organize-docs` migrates from or wraps `documentation-structure`
- a lightweight validator for stable truth roots and stage artifact search boundaries
- whether review harness prompts should eventually load truth docs as additional context in some modes
