# Go-Preferred Persisted Tooling Skill Boundary Design

## Status

- proposal_date: 2026-07-13
- design_version: 2026-07-13-approved-boundary
- approval_status: approved
- approval_basis: the user approved separating plan-time implementation-language selection from agent ad hoc tool composition, approved a non-mandatory Go preference for persisted operational tooling, approved distinct Go CLI-tool and API-service references, requested minimal change to Python maintenance guidance, and refined nested `bash -c` plus `python -c` from a blanket prohibition to avoid-by-default semantics

## Problem

The current skill boundaries mix two different decisions. `language-decision-tree` chooses implementation languages for new code but is broad enough to overlap agent ad hoc commands, while `tool-decision-tree` recommends inline Python fallbacks that are difficult to review and prone to multi-layer quoting failures. `shell-guidelines` still names Python as the fixed escape hatch for complex scripts, which prevents a durable preference for Go without making Go mandatory. `go-guidelines` combines CLI and service concerns under one thin baseline, requires golangci-lint too broadly, and lacks purpose-specific architecture and library-selection references.

The resulting guidance can make planning choose Python for reusable operator tools even when a Go binary would reduce runtime and wrapper state, while ad hoc execution can still produce nested Shell and Python command strings whose failure surface is disproportionate to the task. Existing Python projects nevertheless have valid runtime, cache, test, and dependency contracts that should remain stable.

## Goals

- Limit `language-decision-tree` to design and plan decisions for new persisted code boundaries, new projects, new tools, services, and approved migrations.
- Make `plan-change` explicitly route new persisted implementation work through `language-decision-tree` and record the chosen archetype, language, and rationale without making language selection a second lifecycle authority.
- Make `tool-decision-tree` the owner of agent ad hoc command and tool composition, favoring direct tools and single-layer commands over inline multi-language nesting.
- Express nested `bash -c` and `python -c`, Shell heredoc Python, and generated code strings as avoid-by-default patterns rather than universal prohibitions, while retaining hard safety boundaries for uncontrolled input and irreversible mutations.
- Keep `shell-guidelines` language-neutral at the escalation boundary while preferring Go, not requiring it, for long-lived operational tooling when its runtime and distribution model fit.
- Split Go guidance into shared language policy plus purpose-specific `cli-tool-patterns.md` and `api-service-patterns.md` references.
- Preserve existing Python project maintenance, dependency, cache, lint, type-check, and test contracts with only narrow boundary and example corrections.
- Add executable contract tests so source and generated skill surfaces preserve these ownership boundaries.

## Non-Goals

- Do not migrate or rewrite any tool in `../homelab-config`.
- Do not ban ad hoc Python, Shell, `python -c`, heredocs, or nested interpreters in every circumstance.
- Do not make Go mandatory for all new automation or replace project-local language contracts.
- Do not change existing Python projects from uv, Ruff, ty, pytest, or their cache-isolation rules.
- Do not introduce a fixed Go framework stack into every CLI or API service.
- Do not change the sovereign harness phase graph, approval gates, task-ledger authority, plugin identity, or skill exposure contract.
- Do not add runtime services, external dependencies, plugin installation, commit, push, or deployment work.

## Change Classification

- request_kind: workflow-policy-boundary-change
- change_class: B
- design_strength: design-lite
- truth_impact: medium
- boundary_impact: medium
- recommended_next_phase: plan

## Boundaries

### D1. Plan-time implementation language selection

`language-decision-tree` applies when design or planning introduces a new persisted code boundary, project, tool, service, or approved migration. It does not own ad hoc command composition and does not need to run for ordinary edits where the implementation language is already fixed. `plan-change` conditionally invokes the language decision and records `implementation_archetype`, `implementation_language`, and `language_rationale` when a task creates or replaces a persisted implementation boundary.

### D2. Agent ad hoc command composition

`tool-decision-tree` owns temporary search, inspection, transformation, and repair command composition. Its preference order is direct purpose-built tools, structured CLI tools, simple single-layer Shell, and then an external scratch script when procedural logic is needed. Nested Shell and Python command strings are `AVOID` because they are harder to audit, easier to quote incorrectly, and more likely to turn a command failure into an unexpected mutation. They remain available when the agent judges them necessary and the operation is bounded.

Hard prohibitions remain limited to executing uncontrolled input as code, interpolating untrusted values into command strings, and using opaque nested code for irreversible or insufficiently previewed mutation. Read-only or tightly bounded fallback use is allowed when the agent can still show and validate the exact command.

### D3. Persisted Shell escalation

`shell-guidelines` owns safe Shell after Shell has been selected. It detects capability-based escalation signals such as structured multi-step parsing, persistent state, retry and rollback logic, concurrency, multi-host distribution, embedded languages, or wrappers that increasingly manage runtimes and dependency graphs. When those signals appear, it routes back to `language-decision-tree` without requiring a specific replacement language. It may state a Go preference for long-lived operational tools when a static binary and reduced runtime state are material benefits.

### D4. Go purpose profiles

`go-guidelines` keeps one shared baseline for modules, formatting, compilation, vetting, error wrapping, context, testing, and dependency hygiene. Progressive disclosure selects one or both purpose profiles:

- `references/cli-tool-patterns.md` owns standard-library `flag` versus Cobra selection, command construction, completion, stdout and stderr, exit codes, configuration, credentials, state-changing safety, tests, build output, and distribution.
- `references/api-service-patterns.md` owns `net/http` versus existing router frameworks, transport and application boundaries, timeouts, graceful shutdown, middleware, health, observability, secrets, tests, and container or binary delivery.

The shared baseline no longer requires golangci-lint for every project and no longer requires a custom error type unless callers need programmatic classification through `errors.Is` or `errors.As`.

### D5. Existing Python stability

`python-guidelines` remains the maintenance contract for existing Python code and approved Python implementations. Its uv, project ownership, Ruff, ty, pytest, cache isolation, dependency preflight, typing, error handling, and security guidance stay intact. Only wording that implies Python owns language selection or examples that encourage hard-to-review nested inline code may change.

### D6. Source and generated truth

Source changes belong under `src/skills/`; root-flat `skills/` is regenerated rather than edited. Stable routing summaries in `AGENTS.md`, `README.md`, session routing, and workflow architecture are updated only enough to reflect the plan-time versus ad hoc boundary. Historical plans and unrelated policy skills remain unchanged.

## Human Gate

- approval_required: true
- approval_status: approved
- approval_basis: the user accepted the design direction, corrected nested interpreter handling to avoid rather than forbid, and requested an implementation plan before execution
- next_entry: plan-change

## Implementation Surface

- impl_file_refs:
  - AGENTS.md
  - README.md
  - docs/architecture
  - src/skills/disciplines/language-decision-tree
  - src/skills/disciplines/tool-decision-tree
  - src/skills/policies/go-guidelines
  - src/skills/policies/python-guidelines
  - src/skills/policies/shell-guidelines
  - src/skills/session/use-coding-skills
  - src/skills/workflows/plan-change
  - skills
- test_file_refs:
  - tests
  - docs/plans/language-tooling/2026-07-13-go-preferred-persisted-tooling-design.md
  - docs/plans/language-tooling/2026-07-13-go-preferred-persisted-tooling-plan.md

## Validation Strategy

- Contract tests verify that plan-time language selection, ad hoc tool composition, persisted Shell escalation, Go purpose profiles, and existing Python maintenance remain separate owners.
- Negative contract tests reject mandatory Go wording, blanket bans on nested interpreters, Python-only Shell escalation, and inline Python examples that conflict with ad hoc composition guidance.
- Plan contract tests verify that `plan-change` conditionally records implementation archetype, language, and rationale for new persisted boundaries without changing the lifecycle graph.
- Source-to-generated checks prove the root-flat skill surface contains the same references and wording as `src/skills/`.
- Aggregate validation and focused harness smoke tests prove the policy change does not regress skill exposure, artifact validation, review boundaries, or command control.
