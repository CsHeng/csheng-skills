# Harness State Machine

Workflow mode selection happens before phase implementation. `design-change` is a phase implementation, not the global router.

See `workflow-orchestration.md` for the canonical maintenance view of lifecycle composition, the installed implementation invocation DAG, and the controller-owned repair loop.

## Modes

The canonical mode data lives in `contracts/workflow-modes.toml`.

| Mode | Use | Mutation | Design | Plan | Review |
|---|---|---:|---:|---:|---:|
| `read_only` | Explanation, triage, audit, inventory, fact gathering | no | no | no | no |
| `micro` | Small bounded low-risk edit | yes | no | yes | optional |
| `standard` | Ordinary feature, fix, or refactor | yes | yes | yes | yes |
| `regulated` | Infra, network, secrets, auth, security, deployment, public API, data migration | yes | yes | yes | yes |
| `emergency` | Break/fix or urgent recovery | yes | posthoc | minimal | posthoc |

## Routing Defaults

- Read-only questions route to `read_only`.
- Typo, local docs, or narrow low-risk changes route to `micro`.
- Ordinary implementation work routes to `standard`.
- Infra, network, GitOps, IaC, secrets, auth, security, deploy, public API, and data migration work routes to `regulated`.
- Outage, urgent revert, or broken local workflow recovery routes to `emergency`.

## Composition Rule

Workflow skills own lifecycle state. Lower-plane skills may be composed into a workflow, but they do not advance approval, execution, review, truth sync, or close state by themselves.

Allowed composition example:

```text
regulated workflow -> infrastructure-triage -> security-guardrails -> design-change -> review-design -> plan-change -> review-plan -> implement-change -> review-change -> review-implementation -> sync-truth -> close-change
```

Not allowed:

```text
infrastructure-triage -> execute repo mutation -> close change
```

The cross-skill invocation graph stays acyclic. `implement-change` owns an internal `repair -> verify -> review` state transition; lower-plane reviewers return evidence and never call back into the controller. The generated diagrams and their source precedence are documented in `workflow-orchestration.md`.
