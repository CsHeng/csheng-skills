---
name: executable-oracle-architecture-selector
description: "Select executable oracle strategy for architecture, planning, review, and agent-assisted implementation. Use when deciding between TDD, BDD/ATDD, contract tests, property/model-based tests, characterization/golden tests, mutation testing, runtime probes, canaries, chaos, or when a work package needs test/readiness gating before execution."
---

# Executable Oracle Architecture Selector

## Purpose

Choose the executable feedback strategy for a change before implementation.

Treat tests, contracts, properties, models, golden files, monitors, canaries, and synthetic probes as executable oracles: durable constraints that define what behavior must hold.

Core rule:

```text
intent / invariant -> executable oracle -> implementation -> observation -> oracle comparison -> regression guard
```

Do not rely on an agent's implicit understanding of the codebase as the maintenance boundary.

## Selection Questions

Answer these before choosing a method:

- What system boundary is being protected?
- Who owns the oracle?
- Is the behavior new, known, unstable, or legacy-current?
- Is the risk local, cross-service, stateful, security-sensitive, or production-only?
- Can the behavior be expressed as examples, contracts, properties, models, snapshots, or runtime SLOs?
- Is the agent allowed to change the oracle, or only the implementation?

Common boundaries:

- business behavior
- public API or service boundary
- core domain logic
- state machine or protocol
- legacy behavior
- test-suite quality
- runtime resilience
- security or permission boundary

## Method Selector

| Controlled behavior | Preferred method | Oracle type | Avoid when |
|---|---|---|---|
| Single function or module correctness | TDD | Example oracle | Interface is still volatile or code is trivial glue |
| Business acceptance behavior | BDD / ATDD | Scenario oracle | Testing low-level internals |
| Complex domain rules | Specification by Example + TDD | Example table + tests | No domain owner or rules are exploratory |
| Service-to-service compatibility | Contract testing | Contract oracle | Private unstable internal calls |
| Public API or schema compatibility | Contract / schema conformance | Contract oracle | Prototype schema is intentionally unstable |
| Large input space | Property-based testing / fuzzing | Property oracle | Invariant or generator is weak |
| Stateful workflow or protocol | Model-based tests + TDD | Model oracle | Model costs more than the system warrants |
| Legacy refactor safety | Characterization / golden / approval tests | Current-behavior oracle | Current behavior is known wrong and should change now |
| Test-suite strength | Mutation testing | Meta-oracle | Suite is slow, flaky, or low risk |
| Distributed resilience | Fault injection / chaos / synthetic probes | Runtime oracle | Rollback and blast-radius controls are weak |
| Production-only regression | Canary / monitoring / SLO alerts | Runtime oracle | Used as a substitute for pre-merge correctness |
| Security boundary | TDD + properties + fuzz/static analysis + review | Mixed oracle | Agent can silently weaken assertions |

## Phase Defaults

Exploration or prototype:

- use smoke tests, typecheck/lint, minimal happy-path acceptance tests, small golden samples, and minimal public interface contracts
- avoid broad brittle tests over unstable internals

Stabilizing core semantics:

- require a failing test, executable oracle, or narrow reproducer before implementation for non-trivial behavior changes
- focus on state transitions, permission decisions, error semantics, idempotency, compatibility, and persisted formats

Mature or agent-assisted maintenance:

- use TDD/component tests for local changes, BDD/ATDD for critical business workflows, contract/schema checks for boundaries, mutation testing on critical diffs, and canaries/SLO validation for production-only behavior
- do not delete, weaken, or bulk-update oracles without explicit review

Legacy or unknown behavior:

- pin current behavior first with characterization, golden, or approval tests
- refactor in small steps
- replace low-semantic snapshots with higher-semantic tests when stable seams emerge

Infrastructure or platform systems:

- prefer contract/conformance tests, model/state-machine tests, fault injection, narrow local TDD, and runtime synthetic probes
- define the oracle before running live probes; a probe observes behavior, an oracle says whether it is acceptable

## Work-Package Readiness

Use this gate before assigning a slice to a subagent, TDD loop, or execution runner.

A work package is ready only when it has:

- one milestone objective
- explicit non-goals and future-phase items
- a declared oracle strategy from this skill
- concrete acceptance oracles or substitute verification evidence
- maximum review budget
- rollback or stop condition
- subagent boundary: `subagent_ready: true|false`

If these are missing, do not expand the plan. Stop with one of:

- `needs_design_decision`
- `split_scope`
- `needs_oracle_strategy`
- `manual_checkpoint`

## Agent Oracle Policy

Classify oracle edits by risk:

| Diff type | Risk |
|---|---|
| implementation diff | normal |
| test addition | usually beneficial, review semantics |
| test deletion | high |
| assertion weakening | high |
| snapshot/golden update | high |
| contract/model change | very high |
| business scenario change | very high |
| security oracle change | critical |

Reject or require explicit review for:

- exact assertion changed to existence-only assertion
- specific error changed to any error
- exact status changed to broad range
- exact permission set changed to partial containment
- schema version relaxed without compatibility rationale
- negative or boundary tests removed
- snapshots bulk-updated without readable diff review
- sleeps or retries added to hide flakiness
- integration behavior mocked away to make CI pass

## Output Contract

Follow `output-styles` and preserve these semantic results:

- recommended oracle strategy and method mix
- protected boundary, behavior status, risk, and oracle owner
- selected methods, purpose, oracle level, and material discard reasons
- implementation order and concrete validation evidence
- oracle edits that require explicit review
- likely failure modes when they affect the decision

When this skill owns the response, lead with the decision and render only the fields needed to justify or execute it. When design, planning, review, or implementation owns the response, contribute these results as a semantic overlay instead of emitting an independent oracle report.

Keep the answer concrete. Avoid generic coverage advice and empty template sections.
