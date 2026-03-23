Severity guide for design document review:

Critical — use when the design, if implemented as written, will:
- Create a security vulnerability at an architecture boundary (e.g., unauthenticated access to internal services)
- Have no stated goal or success criterion that can be verified
- Contradict a stated constraint in a way that makes the design unimplementable
- Miss an external system boundary that the design depends on but does not specify

Example: Design introduces a service-to-service call but specifies no authentication mechanism between them — any service in the network can impersonate any other.

Important — use when the design, if implemented as written, will:
- Produce a system that cannot be operated or monitored (no health signals, no alerting strategy)
- Have a component whose ownership or deployment boundary is undefined
- Include a rollout or migration path that has no reversibility for a breaking change
- Have a stated goal that the proposed architecture cannot satisfy

Example: Design requires sub-10ms p99 latency but introduces a synchronous cross-datacenter call in the critical path with no mitigation.

Minor — use for issues that should be resolved but will not prevent implementation:
- Ambiguous terminology that could be interpreted two ways
- Inconsistent naming across sections
- Missing but low-impact rationale for a decision

Example: Two sections use different names for the same component, but the design is otherwise consistent.
