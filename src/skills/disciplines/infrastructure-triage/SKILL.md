---
name: infrastructure-triage
description: "Use for infrastructure, network, proxy, tunnel, container, GitOps, IaC, Secrets, Auth, and automation troubleshooting or design; analyze data path, control boundary, state owner, permissions, drift, rollback, and observability."
---

# Infrastructure Triage

Diagnose and design operational systems by separating desired state, actual state, traffic path, control path, and ownership boundaries.

## Workflow

1. Identify the target surface: host, repo, runtime, cluster, container, router, service, cloud control plane, or automation runner.
2. Separate desired state from actual state.
3. Trace the data path and control path.
4. Identify state owner, permission principal, trust boundary, and rollback surface.
5. Collect evidence at boundaries before changing configuration.
6. Return the fix, verification point, observability point, and fallback.

## Analysis Axes

- Network: DNS, TLS, NAT, route, proxy, tunnel, firewall, listener, client-side proxy state.
- Containers: image digest, bind mounts, env injection, network namespace, published ports, health checks, in-container state.
- GitOps and IaC: declared state, live state, drift, state backend, apply identity, apply order, rollback.
- Secrets and Auth: credential source, storage boundary, token audience, principal, scope, rotation, audit trail.
- Automation: trigger identity, idempotence, concurrency, retry behavior, partial failure, rollback, audit evidence.

## Output

- Lead with the most likely boundary or state mismatch.
- Distinguish verified facts from inferred causes.
- Name the exact observation point for each claim.
- Include rollback or fallback when a change affects access, routing, secrets, production state, or remote execution.
- Prefer live runtime evidence when hardware, services, routers, or containers are available.
