# Sovereign Harness Kernel V1 Design

## Status

Proposed and approved in interactive design discussion on 2026-04-06.

## Problem

The current repository already has strong lower-plane capabilities:

- truth-aware analysis through `analyze-project`
- truth maintenance through `organize-docs`
- cross-model evaluation through `review-design`, `review-plan`, `review-code-impl`, and `skills/_review-libs/`
- rich language, tooling, quality, security, and implementation policies

What it does not yet have is a single sovereign top-level harness authority.

Today, that gap creates four predictable problems:

1. Request routing is still too close to skill-trigger heuristics instead of explicit control-plane intent routing.
2. Design intensity is easy to misjudge. Small local changes can be over-designed, while truth-affecting changes can still drift into implementation-first behavior.
3. Review and verification are strong, but they are not yet unified into a single gate that can drive rollback depth.
4. The repository can explain and review work well, but it cannot yet own the whole change lifecycle from intake to close without borrowing an external workflow harness.

The result is that the repository behaves like a strong skill and evaluator substrate, but not yet like a full sovereign harness kernel.

## Goals

- Establish a single top-level harness authority for this repository's future workflow.
- Preserve the current strong truth plane and evaluator plane instead of replacing them.
- Introduce explicit top-level entries for defining, planning, executing, reviewing, syncing truth, and closing changes.
- Make design strength depend on truth impact and boundary impact instead of crude task size.
- Make rollback depth explicit and systematic.
- Keep V1 serial-first and human-sovereign.
- Prepare a future path for limited parallel-safe execution after dependency freeze, without making that a V1 requirement.

## Non-Goals

- Do not coexist with external top-level harnesses long term.
- Do not build a multi-role autonomous operator shell in V1.
- Do not enable unattended execution by default.
- Do not attempt a full policy-registry and auto-injection runtime in V1.
- Do not redesign the existing review runtime from scratch.
- Do not treat this design as a marketplace expansion exercise.

## Decision Summary

Build a sovereign harness kernel around seven top-level entries:

- `analyze-project`
- `design-change`
- `plan-change`
- `execute-change`
- `review-change`
- `sync-truth`
- `close-change`

The kernel owns six exclusive authorities:

- request routing
- phase transition
- rollback depth selection
- parallelization permission
- policy injection timing
- completion judgment

The current repository's future shape is:

- a truth plane anchored by `analyze-project` and `sync-truth`
- an evaluation plane anchored by `review-*` and `skills/_review-libs/`
- a policy plane composed from the current guideline and standards skills
- an execution-support plane composed from worktree, commit, fetch, and registry helpers
- a new control plane that classifies requests, routes them, drives phase transitions, resolves rollback depth, and decides when a change can close

This design explicitly rejects long-term top-level coexistence with external harnesses. External harnesses remain design references only.

## Top-Level Authority Model

### Sovereignty

At runtime there may be only one active top-level harness authority.

That authority must decide:

- what kind of request this is
- which top-level entry handles it
- what phase comes next
- whether a failure stays local or rolls back to plan or design
- whether parallel execution is allowed
- whether completion criteria are satisfied

### Human Authority

Human authority remains final for:

- goal definition
- boundary approval
- design approval
- plan approval
- parallel batch approval
- rollback escalation when tradeoffs exceed existing policy
- truth-sync approval
- close approval

### Agent Authority

The harness may delegate drafting, implementation, review invocation, verification, and truth-sync preparation to agents, but not final top-level control decisions.

## Top-Level Entries

### `analyze-project`

Purpose:

- query current project state
- explain stable truth, boundaries, operation, and gaps
- assess document health and analysis basis

### `design-change`

Purpose:

- decide whether the change is `no-design`, `design-lite`, or `design-full`
- define change boundaries, non-goals, truth impact, and boundary impact
- produce an approved design artifact when needed

### `plan-change`

Purpose:

- compile approved design into an implementation plan
- define task DAG, dependencies, write sets, verification commands, and rollback triggers
- determine whether any future parallel-safe batch even exists

### `execute-change`

Purpose:

- execute an approved plan
- default to serial implementation
- optionally execute explicitly approved parallel-safe batches in the future
- always return to converge, review, and verify

### `review-change`

Purpose:

- provide one top-level review entry
- route to design, plan, or code-implementation review
- normalize outputs into a shared verdict model

### `sync-truth`

Purpose:

- update stable truth only when `truth_impact = true`
- consume evidence from change execution rather than rediscovering the whole project from zero
- preserve the truth/history boundary

### `close-change`

Purpose:

- decide whether the change can merge, release, or clean up
- require review, verification, and truth-sync gates as applicable
- own final closure semantics

## Runtime Objects

The kernel should stabilize around six runtime objects:

- `request`
- `truth_snapshot`
- `classification_record`
- `phase_state`
- `evaluation_verdict`
- `failure_record`

These objects should be enough to route, evaluate, roll back, and close a change without relying on implicit conversational memory.

## Change Classification Model

### Change Classes

- `A`: `leaf-patch`
- `B`: `local-contract-change`
- `C`: `boundary-system-change`
- `D`: `truth-repair`

### Derived Decisions

Classification must also produce:

- `design_strength`
- `truth_impact`
- `boundary_impact`
- `truth_sync_required`
- `parallel_candidate`
- `recommended_next_phase`

### Classification Principle

The design trigger is not task size.

The real triggers are:

- truth impact
- boundary impact
- operational impact
- evaluation impact
- coupling impact

This is the main control-plane correction that prevents both overdesign and truth drift.

## Phase Model

Canonical phases:

1. `intake`
2. `truth-scan`
3. `clarify`
4. `design-lite`
5. `design-full`
6. `plan`
7. `dependency-freeze`
8. `implement-serial`
9. `implement-parallel`
10. `converge`
11. `review`
12. `verify`
13. `truth-sync`
14. `close`

The kernel is not a global DAG. It is a state machine with explicit rollback edges.

Key rules:

- `design-full` is not the default answer for every change
- `implement-parallel` is never the default
- repeated execution failure must roll back upward
- review and verify are separate gates
- truth-sync happens only when truth impact is real

## Kernel Components

V1 should stabilize these components:

- `artifact-registry`
- `policy-registry`
- `truth-engine`
- `change-classifier`
- `request-router`
- `phase-engine`
- `policy-injector`
- `execution-scheduler`
- `evaluation-gate`
- `rollback-resolver`

The smallest sovereignty-critical V1 subset is:

- `change-classifier`
- `request-router`
- `phase-engine`
- `evaluation-gate`
- `rollback-resolver`

## Plane Model

### Truth Plane

Current assets:

- `analyze-project`
- `organize-docs`
- docs truth/history boundary files

Future role:

- current-state analysis
- stable-truth maintenance
- truth drift detection

### Evaluation Plane

Current assets:

- `review-design`
- `review-plan`
- `review-code-impl`
- `skills/_review-libs`

Future role:

- structured review verdicts
- verifier integration
- evidence-backed close gates

### Policy Plane

Current assets:

- language guidelines
- decision-tree skills
- architecture/quality/security/testing standards

Future role:

- phase-bound policy injection
- no top-level authority of their own

### Execution-Support Plane

Current assets:

- `git-worktrees`
- `smart-commit`
- `smart-squash`
- `web-fetch`
- `context7-registry`

Future role:

- execution helpers only
- never control the phase path

### Control Plane

Current assets:

- not yet formalized

Future role:

- own all top-level authority

## Policy Model

V1 recognizes these policy classes:

- `constitutional`
- `truth`
- `architecture`
- `planning`
- `implementation`
- `evaluation`
- `mechanical`

In V1, policies do not need a full auto-injection registry yet, but their phase binding must already be explicit.

The most important shift is conceptual:

- low-level preferences stop being top-level skills
- they become policies injected by phase

This includes existing preferences such as CLI parameter style, dry-run semantics, error handling, testing expectations, and search/tooling rules.

## Evaluation and Rollback Model

### Evaluation

The unified verdict model should be:

- `pass`
- `needs-fixes`
- `needs-rollback`
- `manual-decision-required`

The evaluator plane should produce structured findings that classify problems as:

- in-scope implementation failures
- scope mismatches
- boundary mismatches
- truth mismatches
- adjacent debt

### Rollback

Rollback is phase rollback, not version-control reset.

The harness must resolve failures to a specific rollback target such as:

- `clarify`
- `truth-scan`
- `design-lite`
- `design-full`
- `plan`
- `dependency-freeze`
- `implement-serial`

Repeated local failures are not allowed to remain in the implementation layer forever.

## Execution Model

### V1

- serial-first
- human-led through definition
- supervised through execution and evaluation
- no unattended mode
- no default parallel-safe scheduling

### Future

Parallel execution may be added only after:

- dependency freeze is explicit
- interface freeze is explicit
- write sets are explicit
- each task has independent verification
- converge is mandatory after each batch

## Implementation Surface

- impl_file_refs:
  - AGENTS.md
  - README.md
  - skills/design-change/SKILL.md
  - skills/plan-change/SKILL.md
  - skills/execute-change/SKILL.md
  - skills/review-change/SKILL.md
  - skills/sync-truth/SKILL.md
  - skills/close-change/SKILL.md
  - skills/_harness-libs/contracts.sh
  - skills/_harness-libs/classifier.sh
  - skills/_harness-libs/router.sh
  - skills/_harness-libs/phase-engine.sh
  - skills/_harness-libs/evaluation-gate.sh
  - skills/_harness-libs/rollback.sh
  - skills/_harness-libs/smoke-test/test-kernel-contracts.sh
  - skills/_harness-libs/smoke-test/test-kernel-routing.sh
  - skills/_harness-libs/smoke-test/test-kernel-phase.sh
  - skills/_harness-libs/smoke-test/test-kernel-rollback.sh
- test_file_refs:
  - skills/_harness-libs/smoke-test/test-kernel-contracts.sh
  - skills/_harness-libs/smoke-test/test-kernel-routing.sh
  - skills/_harness-libs/smoke-test/test-kernel-phase.sh
  - skills/_harness-libs/smoke-test/test-kernel-rollback.sh
- out_of_scope_file_refs:
  - skills/_review-libs/drivers/
  - skills/_review-libs/eval/
  - .claude-plugin/plugin.json
  - docs/README.md
  - docs/AGENTS.md

## Risks

- The repository may slip back into a larger skill-marketplace mentality instead of a sovereign control-plane mentality.
- Design-trigger rules may stay too vague and continue to overdesign small leaf changes.
- Review may remain strong but disconnected from rollback depth selection.
- The truth plane may regress into after-the-fact docs repair instead of a first-class control concern.
- Parallel execution may be enabled too early and destabilize convergence.

## Acceptance Criteria

- The design defines a single sovereign top-level harness authority.
- The design fixes the canonical top-level entry set at seven entries.
- The design defines canonical phases, runtime objects, change classes, and verdicts.
- The design positions `analyze-project` and `organize-docs` inside a future truth plane.
- The design positions `review-*` and `skills/_review-libs` inside a future evaluation plane.
- The design explicitly demotes most existing guideline skills into the policy plane.
- The design makes V1 serial-first and human-sovereign.
- The design leaves no ambiguity about the fact that external harnesses are references, not runtime co-governors.

## Follow-Up Work

The next planning phase should define:

- exact V1 file responsibilities for `_harness-libs`
- the minimum shape of the classification record and phase state
- how `review-change` wraps the existing evaluator family
- how `sync-truth` wraps or absorbs `organize-docs`
- how to defer full policy-registry automation without losing explicit policy bindings
