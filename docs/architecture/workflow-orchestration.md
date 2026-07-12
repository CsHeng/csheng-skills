# Workflow Orchestration

This document is the canonical maintenance view of workflow routing, lifecycle ownership, the installed implementation invocation DAG, and the controller-owned repair loop. It explains the contracts but does not replace them.

## Truth Precedence

When prose, diagrams, and runtime behavior disagree, resolve drift in this order:

1. `contracts/workflow-modes.toml` defines mode requirements and phase shape.
2. `contracts/lifecycle.toml` defines kernel membership and repository-wide defaults.
3. `contracts/skills.toml` defines skill exposure, roles, permissions, and the installed runtime-contract pointer.
4. `src/skills/workflows/implement-change/references/workflow.toml` defines the invocation subgraph and repair metadata that must travel with the installed controller.
5. `src/skills/workflows/implement-change/references/repair-loop.md` explains the controller's repair semantics.
6. The PlantUML files in `diagrams/` are generated views for humans and must not be edited by hand.

`docs/plans/` records design and implementation history. It is useful for rationale and dispute resolution but is not current runtime truth.

## Lifecycle Shape

Workflow mode selection precedes phase implementation. The selected mode determines which design, plan, review, truth-sync, rollback, and evidence requirements apply.

- Read-only work routes to analysis without repository mutation.
- Micro changes use a bounded plan, execution, verification, and close path.
- Standard changes add design, review, and truth sync.
- Regulated changes require the full design, review, plan, implementation, truth-sync, and close gates plus rollback and fresh evidence.
- Emergency work minimizes up-front ceremony but requires verification, post-hoc review, truth sync, and close.

Workflow skills own lifecycle transitions. Discipline, policy, tool, and review-component skills contribute methods or evidence without advancing lifecycle state.

## Implementation Invocation DAG

The [implementation invocation DAG](diagrams/implementation-invocation-dag.puml) is generated from the controller-local runtime contract.

The installed subgraph has one lifecycle controller:

- `implement-change` owns plan-bound execution, verification, repair convergence, truth-sync routing, and close routing.
- `review-change` is the agent-native review gate: it constructs a bounded brief, chooses preferred subagent or direct main-agent review, and adjudicates candidate evidence.
- `review-implementation` is a read-only evaluator and returns candidate evidence only.
- `sync-truth` and `close-change` remain explicit downstream gates.

Reverse calls from evaluators or gates into `implement-change` are forbidden. This keeps the public invocation graph acyclic while allowing the controller to own an internal repair state machine.

## Repair Loop

The [implementation repair loop](diagrams/implementation-repair-loop.puml) is also generated from the installed controller contract.

The normal transition is:

```text
implement -> verify -> review -> classify -> diagnose -> repair -> verify
```

The main agent gives the reviewer only the approved task slice, exact diff, task tests, declared oracles, touch set, and justified supporting files. Findings require change causality and an explicit approved-contract violation. Severity or reviewer scope labels do not authorize repair.

The normal path is one initial bounded review, one batched repair of main-agent accepted findings, declared verification, and one focused verification review. Focused verification checks accepted findings and repair-introduced regressions; it does not reopen repository-wide discovery. At most one additional same-slice repair attempt is allowed for a proven incomplete or regressive repair.

`classify` produces one typed exit:

- `pass`: verification and review pass.
- `replan`: the approved plan or work-package order is insufficient.
- `redesign`: the architecture or boundary decision must change.
- `needs-authority`: completion requires new user authority or expanded scope.
- `rollback`: the verified safe path is to restore the declared rollback target.
- `non-convergent`: focused same-slice repair did not converge.

Only `implement-change` mutates implementation state inside this loop. `review-implementation` never repairs, invokes a lifecycle workflow, delegates recursively, or decides continuation.

## Discovery And Bootstrap

Native skill-description matching is the default discovery mechanism. It can compose a primary workflow with matching policy overlays, such as `review-implementation` plus `go-guidelines` for a Go implementation review.

Native matching is probabilistic, so a host that requires deterministic lifecycle entry may keep a thin intent-to-public-skill mapping. The host bootstrap must not duplicate DAG edges, repair states, budgets, or exits; those constraints belong to the installed controller package.

## Maintenance

Regenerate the diagrams after changing the controller-local workflow contract:

```bash
python3 scripts/generate-workflow-diagrams.py
```

Validate that diagrams are current and syntactically valid:

```bash
python3 scripts/generate-workflow-diagrams.py --check
plantuml --check-syntax docs/architecture/diagrams
bash scripts/check.sh
```
