# Architecture Decision Economics

Use this reference when a change creates, replaces, decomposes, centralizes, distributes, or materially scales a persisted architecture boundary. Use the concepts as causal decision lenses, not as a mandatory financial worksheet.

## Contents

- [Marginal Cost](#marginal-cost)
- [Opportunity Cost](#opportunity-cost)
- [Incentives](#incentives)
- [Comparative Advantage](#comparative-advantage)
- [Supply And Demand](#supply-and-demand)
- [Decision Sequence](#decision-sequence)
- [Compact Decision Evidence](#compact-decision-evidence)
- [Planning Handoff](#planning-handoff)
- [Failure Modes](#failure-modes)
- [Short Examples](#short-examples)

## Marginal Cost

Evaluate the next architecture increment rather than comparing only completed end states.

Count marginal benefit such as the next reduction in latency, failure coupling, deployment contention, or operator toil. Compare it with the next increment of implementation, migration, coordination, cognitive, runtime, observability, verification, and rollback cost.

Prefer reversible staged investment when the first increment captures most of the benefit. Stop adding layers, services, caches, brokers, replicas, abstractions, or tests when the next unit costs more than the constraint it removes.

## Opportunity Cost

Treat architecture work as consuming scarce delivery, review, operational, and learning capacity. State which user outcome, reliability repair, debt reduction, or alternative experiment will be delayed by the chosen investment.

Always compare at least:

- `status quo`: preserve the existing boundary and accept its current constraint
- `smallest sufficient`: make the least expensive reversible change that meets the approved goal
- `structural investment`: buy a larger capability, independence, or future capacity now

Reject an option when its displaced work is more valuable than its incremental benefit, even when the option is technically elegant.

## Incentives

Identify who receives the benefit, who pays the implementation and operational cost, who controls the decision, and which behavior the architecture or workflow rewards.

Watch for incentive failures:

- a shared platform whose consumers request features while another owner absorbs on-call cost
- service autonomy that externalizes compatibility and incident cost to other teams
- feature flags, abstractions, or compatibility paths that are cheap to add but have no removal owner
- plan templates that reward field completion instead of decision quality
- executable oracles that can be weakened or gamed to make a change appear complete

Align authority, cost, and accountability. Give every durable boundary and temporary mechanism an owner, an observable outcome, and an exit or cleanup condition.

## Comparative Advantage

Assign a responsibility to the component, team, runtime, language, provider, or existing platform with the lowest relative opportunity cost, not necessarily the option with the highest abstract capability.

Prefer existing ownership and ecosystems when they materially reduce integration and maintenance risk. Preserve clear boundaries: Shell can own thin orchestration, a primary implementation owns validation and state, a provider SDK can own provider-specific behavior, and a shared service should exist only when central ownership is cheaper than repeated local ownership.

Record the hard constraint or ecosystem advantage when selecting an option that differs from the repository default.

## Supply And Demand

Describe demand with current or observed evidence: request rate, data volume, growth rate, latency objective, failure tolerance, deployment frequency, number of callers, number of independent owners, incident load, or operator toil.

Describe supply as the capacity available from compute, storage, network, deployment throughput, review bandwidth, operational attention, and team coordination. Find the constrained resource before adding architectural supply.

Provision enough headroom for the decision horizon and the lead time needed to add more. Do not buy distributed coordination, sharding, multi-region operation, or organizational independence merely because demand might appear someday. Record a measurable upgrade_trigger and preserve a migration path that can be exercised before the current supply is exhausted.

## Decision Sequence

1. State the protected boundary and current demand evidence.
2. Identify the scarce_resource or hard requirement controlling the decision.
3. Compare the status quo, the smallest sufficient option, and a structural investment.
4. Describe the marginal_tradeoff of the next architecture increment.
5. State the opportunity_cost and displaced work.
6. Identify owner_and_incentives, including shifted costs and cleanup responsibility.
7. Explain comparative_advantage for the chosen responsibility placement.
8. Select the option that meets the approved goal with the lowest justified lifecycle burden.
9. Record an observable upgrade_trigger, rollback boundary, and executable oracle.

## Compact Decision Evidence

Use only fields that materially affect the decision. Keep the record at design level rather than duplicating it on every plan task.

```yaml
architecture_economics:
  demand_evidence: <observed need, load, coordination pressure, or hard requirement>
  scarce_resource: <current bottleneck or constrained ownership capacity>
  options:
    - status quo: <fit and discard reason>
    - smallest sufficient: <fit and discard or selection reason>
    - structural investment: <fit and discard reason>
  marginal_tradeoff: <next benefit versus next lifecycle-cost increment>
  opportunity_cost: <valuable work delayed or capacity consumed>
  owner_and_incentives: <beneficiary, cost bearer, authority, cleanup owner>
  comparative_advantage: <why this boundary or owner has the lowest relative cost>
  chosen_option: <selected boundary and pattern set>
  upgrade_trigger: <observable condition for the next increment>
  rollback_and_oracle: <safe exit plus executable evidence>
```

Do not turn uncertain inputs into a weighted score. Avoid false precision because it hides assumptions and encourages agents or reviewers to optimize the score instead of the system outcome.

## Planning Handoff

Pass the approved decision to planning by reference. Break structural investment into reversible increments that buy information early, preserve an exit path, and delay irreversible cost until evidence requires it.

Plan tasks may implement, verify, or stage the choice. They must not silently rescore the approved tradeoff. Route changed demand, ownership, hard constraints, or upgrade triggers back to design.

## Failure Modes

- **Pattern shopping:** selecting patterns because they are available in the catalog rather than because they relieve a proven constraint.
- **Future-proofing without a trigger:** paying recurring complexity for an unbounded hypothetical future.
- **Cost externalization:** giving one caller or team local convenience while transferring coordination, incident, or migration cost to others.
- **Sunk-cost defense:** continuing an architecture because of prior investment when the next increment no longer pays.
- **Template gaming:** completing every field or adding every oracle to satisfy a process rather than protect an outcome.
- **Security tradeoff misuse:** treating mandatory security, compliance, or data-integrity constraints as optional benefits that can lose a cost comparison.
- **Demand fiction:** using an unsupported growth forecast instead of current evidence, lead time, and an observable upgrade trigger.

## Short Examples

### Service Split

Keep a modular monolith when deployment contention and independent scaling are hypothetical. Split a service when observed ownership or scaling pressure exceeds the cost of network contracts, independent deploys, tracing, incident coordination, and data consistency.

### Cache Or Replica

Optimize a query or local access path before adding shared cache invalidation or replica lag. Add the next supply increment when measured latency or database saturation crosses the recorded trigger and the application can tolerate the new consistency model.

### Event-Driven Coordination

Use a direct call or local transaction when the workflow is small and synchronous failure semantics are valuable. Add durable messaging when demand for decoupled availability, buffering, or independent ownership exceeds the cost of idempotency, ordering, retries, dead-letter handling, and observability.
