# Bounded Agent-Native Review Design

## Status

- proposal_date: 2026-07-11
- design_version: 2026-07-11-approved-boundary
- approval_status: approved
- approval_basis: the user approved bounded review briefs, finding causality, main-agent adjudication, prompt recalibration, and later round/DAG simplification; the user also required retirement of external Bash/model review orchestration in favor of agent-native review that prefers a subagent but remains usable when the current agent reviews directly
- supersedes_review_runtime_from: docs/plans/harness-kernel/2026-07-10-native-skill-composition-and-repair-orchestration-design.md

## Problem

The current review system treats semantic review as an external runner workflow. `run-review.sh` builds prompts, creates an isolated workspace, selects a model-specific driver, invokes another CLI, validates a reviewer schema, and converts every Critical or Important finding into control-plane state. Review skills and command wrappers therefore describe same-driver, reviewer CLI, reviewer model, provider-specific invocation, schemas, and runner-managed rounds instead of describing the review judgment a coding agent should perform.

This mechanism is now unnecessary because the active operating model uses the same coding-agent capability for implementation and review. The current coding agent can either delegate a bounded review to a subagent, which is preferred for non-trivial work, or perform the review itself when delegation is unavailable or disproportionate. Skills should express that portable agent behavior without naming or selecting Codex, Claude, Gemini, or any other review tool/provider.

The deeper defect is semantic rather than transport-related. The current implementation-review prompt encourages exhaustive discovery, asks the reviewer to report uncertain concerns, and treats all Critical or Important findings as blockers. It does not require a causal connection between a finding and the current task-slice diff. As a result, moved legacy code, unchanged neighboring code, future plan phases, and repo-wide pre-existing debt can enter the review context and become automatically accepted repair work. The controller then expands the approved plan instead of judging whether each candidate finding is attributable, material, and worth fixing now.

## Goals

- Replace external Bash/model review orchestration with an agent-native review contract that prefers a reviewer subagent and permits direct main-agent review.
- Keep review skills portable across coding agents by describing roles and interaction without provider names, model names, CLI commands, adversarial framing, or cross-tool arbitration.
- Require the main agent to construct a bounded review brief before review begins.
- Limit default reviewer context to the approved task slice, its actual diff, task tests, declared acceptance criteria, and explicitly justified supporting files.
- Require every candidate blocker to identify its causal relationship to the current change and the exact approved requirement or oracle it violates.
- Make reviewer output advisory evidence; only the main agent may accept, reject, defer, or escalate findings and authorize repair.
- Prevent pre-existing, unrelated, future-phase, general-hardening, and merely adjacent concerns from becoming automatic repair work.
- Preserve deterministic artifact-DAG validation needed by design, plan, execution, and truth-sync workflows while moving that support out of the retired semantic review runner package.
- Simplify review rounds and legacy smoke coverage after the review-input and adjudication boundaries are correct.

## Non-Goals

- Do not remove ordinary repository tests, linters, static checks, diff checks, schema checks owned by product code, or other executable oracles.
- Do not remove design-to-plan-to-implementation linkage or approved touch-set enforcement.
- Do not require every review to spawn a subagent; small or mechanical changes may be reviewed directly by the main agent.
- Do not create provider-specific fallback instructions or retain dormant multi-model drivers for hypothetical future use.
- Do not turn reviewers into fixers, lifecycle controllers, or final scope authorities.
- Do not make repo-wide security audits, hardening reviews, or archaeology impossible; those remain explicit review modes only when requested or approved as their own scope.
- Do not rewrite historical files under `docs/plans/` to remove old review terminology.
- Do not implement this design in the planning phase.

## Change Classification

- request_kind: workflow-boundary-change
- change_class: C
- design_strength: design-lite
- truth_impact: high
- boundary_impact: high
- recommended_next_phase: plan

## Boundaries

### D1. The coding agent owns review orchestration

The active coding agent decides how to execute a review:

```text
main agent
  -> construct bounded review brief
  -> prefer reviewer subagent for non-trivial review
  -> otherwise review directly
  -> adjudicate candidate findings
  -> repair only accepted findings
```

The skill contract describes roles rather than a specific tool call. When the host exposes subagents, delegation is preferred because it gives the main agent an independent review interaction. When subagents are unavailable, disallowed, or unnecessary for a small mechanical change, the main agent applies the same bounded review contract directly. A delegated reviewer never delegates recursively.

Public review entry skills may declare subagent capability because the current main agent must be able to choose delegation. The runtime brief must also declare whether the current actor is the main agent or an already delegated reviewer; only the main-agent role may create the reviewer subagent.

### D2. The bounded review brief is the default context boundary

Before review, the main agent supplies:

- the approved task-slice objective
- relevant goals and explicit non-goals
- acceptance criteria and executable oracles
- the exact changed files and diff for the task slice
- task-scoped tests and verification evidence
- a small allowlist of supporting files, each with a reason it is needed

The reviewer must not perform a repo-wide search by default. It may read an unchanged file only when that file is a direct dependency of changed behavior and is necessary to determine whether the current diff is correct. Following references recursively, reviewing future plan tasks, auditing moved-but-unchanged code, or adding general production-hardening requirements is outside the default contract.

Incidental observations outside the brief do not block the current change. A critical security or data-loss issue may be reported as an explicit out-of-scope escalation, but it still does not authorize unplanned repair.

### D3. Candidate findings require change causality

Every candidate blocker declares one causal class:

- `introduced_by_change`: the current diff directly creates the defect
- `regressed_by_change`: the current diff breaks behavior that was previously correct
- `activated_by_change`: the current diff newly places pre-existing behavior on an approved active execution path
- `pre_existing`: the defect existed and the current diff does not worsen or activate it
- `unrelated`: the observation is not caused by the current task slice

Only `introduced_by_change`, `regressed_by_change`, and narrowly proven `activated_by_change` findings are eligible for current-scope repair. Moving, renaming, reformatting, archiving, or changing ownership labels does not by itself count as activation. Activation requires evidence that the approved change newly executes, exposes, or relies on the affected behavior.

### D4. Blocking status requires an approved-contract violation

A candidate may block only when all of these are true:

- it is inside the bounded review surface
- it has a qualifying causal class
- it cites the changed line or behavior that causes the defect
- it cites the approved requirement, acceptance criterion, invariant, or oracle that is violated
- it has a concrete material consequence rather than speculative hardening value
- it has sufficient evidence and confidence
- its smallest valid fix stays inside the approved task slice and touch set

Severity alone never determines repair eligibility. Low-confidence concerns never trigger automatic repair. Pre-existing, unrelated, future-phase, adjacent-debt, and plan-expanding concerns are non-blocking for the current task and should normally be omitted; when material, they may be returned as deferred evidence or a typed manual escalation.

### D5. The main agent adjudicates reviewer candidates

Reviewer output is evidence, not lifecycle authority. The main agent assigns one disposition to each candidate:

- `accepted`
- `rejected_no_causal_link`
- `rejected_pre_existing`
- `rejected_out_of_scope`
- `rejected_insufficient_evidence`
- `deferred_followup`
- `needs_plan_change`

Only `accepted` findings enter the repair batch. The reviewer may recommend a disposition but cannot declare its own finding automatically repairable. The main agent records a concise reason when accepting a finding or when rejecting a material candidate.

### D6. Review prompts optimize for plan correctness, not exhaustive hardening

Active review instructions must say that the review asks whether the supplied change correctly implements the approved task slice. They must prefer PASS when declared acceptance criteria and oracles are satisfied, prohibit repo-wide auditing by default, and prohibit turning uncertain or adjacent concerns into blockers.

Active instructions must remove adversarial framing and directives equivalent to:

- surface every possible Critical or Important issue
- report uncertain concerns just in case
- err toward more findings
- make one round exhaustive across all discoverable code
- use a different model, provider, or external CLI for independence

Explicit security audits or broad hardening requests may define a wider review brief, but the widened surface must come from user-approved scope rather than reviewer initiative.

### D7. External semantic review runners and provider drivers are retired

`run-review.sh`, its model/provider drivers, prompt builder, isolated reviewer workspace builder, review-output schemas, runner-specific health/eval code, and runner-specific smoke harness are removed from the active source and generated surfaces. Review skills, commands, and architecture docs no longer direct agents to external reviewer CLIs or describe same-driver/cross-driver behavior.

Deterministic support that remains useful outside semantic reviewer invocation must be preserved under its owning harness boundary. In particular, artifact-DAG parsing and allowed-touch-set validation move from `_review-libs` into `_harness-libs`; plan, execute, and truth-sync runners continue using it without retaining the retired review orchestrator.

### D8. Review passes become secondary convergence guards

Pass policy is simplified only after D2-D5 are enforced. A normal implementation review consists of one initial bounded review and, when accepted findings are repaired, one focused verification review of those findings and repair-introduced regressions. The focused verification is not a fresh exhaustive review and must not reopen repo-wide discovery or introduce unrelated requirements.

One additional repair attempt is allowed only when the focused verification proves that the accepted repair itself is incomplete or introduced a regression inside the same bounded slice. Repeated findings after that, a required plan/design change, or a finding outside the approved touch set produce a typed stop instead of more defensive edits. The previous expected-five/hard-ten review contract is removed; a numeric budget must never be interpreted as reviewer permission to search for additional work.

### D9. Source, generated, command, and truth surfaces move together

`src/skills/` and `contracts/skills.toml` remain source of truth. Generated `skills/`, indexes, architecture diagrams, manifests, command wrappers, and smoke tests are refreshed from source. Public review entry skills declare subagent capability so the main agent can choose the preferred path, while their runtime instructions prohibit delegated-review recursion and keep the main agent responsible for adjudication.

Historical stage artifacts retain their original terminology. Stable active docs must describe the new agent-native review boundary and must not present retired runner commands as supported operation.

## Human Gate

- approval_required: true
- approval_status: approved
- approval_basis: the user explicitly accepted D2-D6 and D8, required retirement of adversarial and multi-tool review invocation, and requested an implementation plan
- next_entry: plan-change

## Implementation Surface

- impl_file_refs:
  - contracts
  - src/skills/workflows
  - src/skills/review-components
  - src/skills/_internal/_harness-libs
  - src/skills/_internal/_review-libs
  - commands
  - scripts
  - AGENTS.md
  - README.md
  - docs/architecture
- test_file_refs:
  - tests
  - src/skills/_internal/_harness-libs/smoke-test
  - src/skills/_internal/_review-libs/smoke-test
  - docs/plans/review-system/2026-07-11-bounded-agent-native-review-plan.md

## Validation Strategy

- Contract oracles: active review skills define bounded review briefs, causal classes, candidate-only reviewer output, main-agent adjudication, preferred subagent review, direct-review fallback, and recursion prevention.
- Negative contract oracles: active review surfaces contain no external reviewer CLI invocation, model/provider selection, same-driver/cross-driver policy, adversarial framing, or automatic acceptance of severity-only findings.
- Artifact-DAG oracles: design linkage, plan linkage, allowed touch sets, and task-slice validation continue to pass after deterministic parsing moves under `_harness-libs`.
- Characterization oracles: a mechanical move/rename fixture does not turn pre-existing defects into blockers, a changed-behavior fixture reports a causally linked acceptance violation, and an out-of-scope critical observation stops for explicit authority without authorizing repair.
- Agent-behavior probes: a fresh agent prefers a reviewer subagent for a non-trivial bounded diff when delegation exists, reviews a trivial mechanical diff directly, and produces main-agent dispositions rather than blindly applying reviewer candidates.
- Generation oracles: source and root-flat/target install surfaces remain synchronized.

## Rollback

- Restore the previous review skills and command wording only as one coherent source/generated set; do not restore individual provider drivers without the full previous contract.
- Restore artifact-DAG support to its prior location if relocation breaks plan, execute, or truth-sync validation.
- Do not reintroduce external semantic review invocation as a fallback without a new explicit design decision.
- rollback_entry: design-change
