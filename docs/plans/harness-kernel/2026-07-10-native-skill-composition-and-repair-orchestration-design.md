# Native Skill Composition And Repair Orchestration Design

## Status

- proposal_date: 2026-07-10
- approval_status: approved
- basis: interactive design discussion that accepted a controller-owned repair loop, requested clearer public names, required install-visible workflow contracts, preferred native skill discovery over mandatory bootstrap, and authorized planning plus execution
- related_design:
  - docs/plans/2026-07-07-csheng-skills-restructure.md
  - docs/plans/harness-kernel/2026-04-09-execute-change-v2-task-ledger-design.md

## Problem

The repository already separates workflow owners, review components, policies, generated install surfaces, and repo-global contracts. Three remaining mismatches make the runtime harder to understand and less portable than the documented architecture.

First, `execute-change` is an end-to-end lifecycle controller, but its name reads like a peer implementation step. `review-code-impl` is a lower-plane evaluator, but its name does not expose that relationship and uses an abbreviation that weakens the user-facing model.

Second, stable documentation says the execution workflow owns convergence while `repair-review` is only a helper, but the detailed repair mechanics still live mainly in the review component and review runner. The final execute command stops on review failure instead of keeping an in-scope repair cycle inside the lifecycle controller.

Third, the repo-global contracts describe categories and lifecycle authority, but an installed controller skill does not receive those root contracts. `execute-change` currently installs with only `SKILL.md` and `agents/openai.yaml`, so a coding agent cannot inspect the invocation DAG or repair-loop contract from the installed skill directory.

The user-global `/Users/csheng/.codex/AGENTS.md` also requires `coding:use-coding-skills` at every session start while the Codex skill system already discovers skills from descriptions. This duplicates the native discovery layer and prevents a clean test of workflow-plus-policy composition.

## Goals

- Rename the lifecycle controller to `implement-change` and the implementation evaluator to `review-implementation`.
- Make `implement-change` the only owner of implementation repair state, progress, rollback escalation, and loop exit decisions.
- Keep the cross-skill invocation graph acyclic while representing repair as a bounded internal state transition of the controller.
- Install a machine-readable workflow contract and human-readable repair-loop contract inside the controller skill directory.
- Keep `agents/openai.yaml` limited to supported product metadata and keep detailed workflow rules in directly linked `references/`.
- Use five review-repair rounds as the expected convergence budget and ten rounds as the hard safety limit.
- Batch all current in-scope findings in each repair round, rerun declared verification, then run a fresh complete review.
- Make workflow skills and language/domain policies compose through native description matching without a mandatory session router; allow a thin host intent mapping where deterministic lifecycle entry is required.
- Narrow `use-coding-skills` to optional routing/session-boundary work and remove its unconditional load from `/Users/csheng/.codex/AGENTS.md`.
- Prove behavior in fresh isolated repositories using prompts that do not name the expected skills.

## Non-Goals

- Do not introduce a second lifecycle authority or a new external orchestration service.
- Do not move runtime DAG truth solely into repo-root documentation that disappears when a skill is installed independently.
- Do not add custom fields to `SKILL.md` frontmatter or overload `agents/openai.yaml` with unsupported workflow metadata.
- Do not make every orchestrator user-invoked-only or require slash commands for ordinary natural-language requests.
- Do not remove `use-coding-skills`; keep it available for explicit routing, session defaults, and ambiguous multi-stage workflow selection.
- Do not change the same-driver review policy.
- Do not rewrite historical plan artifacts to use the new public names.
- Do not modify or absorb the existing uncommitted `design-change` work.
- Do not commit or push unless separately requested.

## Change Classification

- request_kind: change-definition
- change_class: C
- design_strength: design-full
- truth_impact: high
- boundary_impact: high
- recommended_next_phase: plan

## Boundaries

### D1. Public naming expresses hierarchy

- `execute-change` becomes `implement-change` because it owns the approved-plan lifecycle, task ledger, convergence, review, verification, rollback, truth sync routing, and close routing.
- `review-code-impl` becomes `review-implementation` because it evaluates an implementation artifact and returns evidence-backed findings without owning lifecycle repair.
- `review-change` remains the public review facade and dispatches implementation artifacts to `review-implementation`.
- Internal review mode identifiers such as `code-impl` may remain internal where renaming would add no user-facing clarity, but public skill, command, contract, and documentation names must be consistent.

### D2. Invocation DAG stays acyclic

The public call graph is:

```text
plan-change
  -> implement-change
       -> review-change
            -> review-implementation
       -> sync-truth
       -> close-change
```

No lower-plane reviewer may invoke `implement-change`, `review-change`, or itself. A direct user review request may enter through `review-change`; an already typed implementation artifact inside `implement-change` still uses the top-level review gate so verdict normalization stays centralized.

### D3. Repair is an internal controller state machine

Repair is not represented as a reverse edge between skills. `implement-change` owns these states:

```text
implement -> verify -> review -> classify
                              -> pass -> sync/close
                              -> local-repair -> diagnose/repair -> verify
                              -> replan -> stop
                              -> redesign -> stop
                              -> needs-authority -> stop
                              -> rollback -> stop
```

Each round consumes a complete review finding set, fixes all accepted `in_scope_blocking` findings inside the approved touch set, reruns the affected and declared verification scope, and then requests a fresh complete review. Review components produce evidence and suggested next state; the controller decides and records the transition.

### D4. Convergence budget is confidence-oriented, not prematurely defensive

- expected convergence rounds: `5`
- hard safety limit: `10`
- reaching round five does not stop a converging repair loop
- reaching round ten without a pass stops with a typed non-convergence state
- a repeated finding triggers root-cause diagnosis inside the loop rather than immediate abandonment
- plan, design, authority, rollback, or approved-scope boundary changes stop the current implementation loop immediately
- finding severity, count, or oracle evidence must show progress; non-monotonic expansion triggers reclassification before more edits

### D5. Runtime contract travels with the controller

`implement-change` owns:

```text
implement-change/
├── SKILL.md
├── agents/openai.yaml
└── references/
    ├── workflow.toml
    └── repair-loop.md
```

`workflow.toml` is the machine-readable installed contract. It declares role, loop ownership, callable skills, forbidden reverse calls, expected rounds, hard limit, and typed exits. `repair-loop.md` explains state semantics and classification. `SKILL.md` remains concise and directly instructs the agent when to read both references.

Repo-global contracts and architecture docs remain maintenance and validation surfaces. They point to and validate the skill-local contract; they do not replace it. The root composite view may be regenerated or audited from installed contracts later.

### D6. Native composition uses orthogonal trigger axes

- Workflow/intent skills own the primary action: analyze, review, design, plan, or implement.
- Language/domain policy skills overlay standards: Go, Shell, Python, security, infrastructure, and similar domains.
- Oracle/gate skills provide verification strategy or evaluation without taking lifecycle ownership.

For `检查这个 Go 服务，只分析问题`, the intended composition is `review-implementation` plus `go-guidelines`. For a Shell bug fix, `shell-guidelines` overlays the relevant change workflow. A request with a directly matched workflow does not need `use-coding-skills` first.

### D7. `use-coding-skills` becomes optional

Remove unconditional session-start wording from its description and body. Keep it for explicit skill routing, session-default selection, ambiguous multi-stage work, memory-boundary guidance, and compact handoff contracts. Remove the mandatory bootstrap line from `/Users/csheng/.codex/AGENTS.md` while keeping durable global ownership and safety rules there.

Fresh-process controls showed that description matching correctly composes implementation review with language policy and leaves non-coding work untouched, but it does not deterministically load a lifecycle controller for every small approved-plan implementation. The host bootstrap therefore keeps only two thin intent mappings: approved-plan implementation -> `implement-change`, and implementation review -> `review-implementation` plus policy overlays. The bootstrap must not copy the DAG, repair states, budgets, or exit rules; those remain install-local under `implement-change/references/`.

External evidence supports this direction: Superpowers removed its Codex SessionStart hook because Codex native discovery was reliable and the bootstrap worsened UX, while Matt Pocock's skills separate explicit orchestration from model-invoked reusable disciplines and keep local dependencies visible inside installed skills.

### D8. Source and generated surfaces remain deterministic

Edit `src/skills/` and `contracts/skills.toml` as source of truth. Regenerate `skills/`, `.dist/claude/`, `.dist/codex/`, and `skills.index.json`. Update commands, internal runners, smoke tests, stable documentation, and source maps through the existing generation workflow. Preserve the unrelated dirty `design-change` files.

### D9. Forward tests use fresh roots and no answer leakage

Create independent Git repositories under `/Users/csheng/tmp/market-csheng-skill-eval/` without repo-local AGENTS files. Use a fresh `fork_turns: none` agent for each natural-language prompt and require only a final `Skills used:` observation line. Expected routing stays in the evaluator, not in prompts or fixtures.

The matrix covers:

- read-only Go implementation review with a real race reproducer
- read-only architecture analysis
- design/plan/orchestrate lifecycle implementation
- Shell quoting repair and verification
- non-coding summarization with no coding workflow bootstrap

Because the parent thread's skill catalog may be snapshotted, rename discovery must also be checked with a fresh top-level Codex process or new thread when child-agent metadata remains stale. To separate native description matching from `/Users/csheng/.codex/AGENTS.md` routing hints, run a second fresh-process control with a temporary neutral `CODEX_HOME` that exposes the candidate generated skills but has no bootstrap AGENTS file. Reuse authentication/configuration only through local symlinks without printing their contents, capture JSONL tool events, and compare actual `SKILL.md` reads with the normal-home run.

## Human Gate

- approval_required: true
- approval_status: approved
- approval_basis: user accepted the repair-loop design, required rename and install-local contracts, approved removing the mandatory bootstrap for validation, and explicitly requested plan creation followed by execution and fresh-subagent tests
- next_entry: plan-change

## Implementation Surface

- impl_file_refs:
  - contracts
  - src/skills/workflows
  - src/skills/review-components
  - src/skills/session
  - src/skills/policies
  - src/skills/_internal/_harness-libs
  - src/skills/_internal/_review-libs
  - commands
  - scripts
  - AGENTS.md
  - README.md
  - docs/architecture
  - docs/changelog
  - /Users/csheng/.codex/AGENTS.md
- test_file_refs:
  - tests
  - src/skills/_internal/_harness-libs/smoke-test
  - src/skills/_internal/_review-libs/smoke-test
  - docs/plans/harness-kernel/2026-07-10-native-skill-composition-and-repair-orchestration-plan.md
  - /Users/csheng/tmp/market-csheng-skill-eval

## Validation Strategy

- Contract/static oracles: validate skill names, source directories, public IDs, installed local workflow contract, allowed calls, forbidden reverse calls, unique repair-loop owner, and acyclic cross-skill graph.
- Generation oracles: `skills.index.json`, root-flat, Claude, and Codex install surfaces match source contracts.
- Harness oracles: renamed kernel routing and phase transitions pass existing targeted smoke tests.
- Repair-loop oracles: expected convergence equals five, default and hard `max_rounds` equal ten, needs-fixes routes back to controller repair, and boundary exits remain typed.
- Progressive-disclosure oracles: fresh agents directly combine workflow and policy skills without mandatory `use-coding-skills`; non-coding work does not load the coding bootstrap.
- Compatibility oracle: existing unrelated `design-change` changes remain untouched.

## Rollback

- Restore the two old public names, directories, contracts, command names, and generated surfaces together; do not leave aliases that compete in discovery.
- Restore the old review limit only if the new controller loop cannot preserve typed scope exits or reviewer isolation.
- Restore the `/Users/csheng/.codex/AGENTS.md` bootstrap line only if fresh top-level tests demonstrate a material native-discovery regression that cannot be fixed by tightening skill descriptions.
- rollback_entry: design-change
