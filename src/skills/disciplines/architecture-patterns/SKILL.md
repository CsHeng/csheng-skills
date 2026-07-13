---
name: architecture-patterns
description: "Use for architecture design decisions: service boundaries, monolith vs microservices, layering, dependency injection, module contracts, and integration patterns."
---

# Architecture Pattern Selection

Choose the smallest sufficient architecture justified by current demand, a constrained resource, ownership, and an observable upgrade trigger. Treat patterns as options with lifecycle costs, not defaults to accumulate.

## Selection Workflow

1. Preserve established repository, runtime, data, and ownership boundaries unless the approved design authorizes changing them.
2. State the protected behavior, current demand evidence, constrained resource, hard requirements, and decision horizon.
3. For a new or materially changed persisted architecture boundary, read `references/architecture-decision-economics.md` and compare the status quo, the smallest sufficient option, and a structural investment.
4. Read `references/architecture-pattern-catalog.md` only for pattern families relevant to the proven constraint.
5. Define dependency direction, state and data ownership, caller contracts, failure containment, operability, rollout, rollback, and executable evidence for the selected option.
6. Record the chosen option, material rejected alternatives, lifecycle-cost owner, and observable upgrade trigger.

## Selection Rules

- Prefer an existing boundary or a reversible local extension when it satisfies the approved goal.
- Require demand or constraint evidence before adding distribution, asynchronous coordination, new infrastructure, speculative seams, or independent operational surfaces.
- Compare the next unit of benefit with its implementation, migration, coordination, cognitive, runtime, verification, and rollback costs.
- Assign operational cost and decision authority to an explicit owner; call out costs shifted to callers, operators, or future maintainers.
- Place responsibility where the repository, team, runtime, language, or provider ecosystem has the lowest relative opportunity cost while preserving clear ownership.
- Treat security, compliance, data-loss, and externally mandated reliability requirements as hard constraints rather than optional benefits in a scorecard.
- Avoid numeric scoring when the inputs do not support it. Prefer causal evidence, explicit discard reasons, and measurable triggers over false precision.
- Defer a larger pattern until its trigger is observed when delay preserves a safe migration path.

## Interface And Domain Boundaries

When shaping module interfaces, test seams, domain terminology, or caller contracts, read `references/interface-and-domain-language.md`.

Keep interfaces small and behavior-bearing. Create seams for proven variation or caller-visible test contracts, not for hypothetical substitution.

## Decision Result

When this skill owns an architecture decision, lead with the selected option and render only the evidence needed to show:

- why it fits current demand and the constrained resource
- why simpler and more structural alternatives were rejected or deferred
- who owns state, failure handling, lifecycle cost, and future evolution
- which executable oracle protects the boundary
- what observable trigger justifies the next architecture increment

When `design-change`, `plan-change`, or a domain skill owns the response, contribute these semantics as an overlay rather than emitting a second report template.
