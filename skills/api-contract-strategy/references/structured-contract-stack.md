# Structured Contract Stack

## Truth Roles

Keep one maintained source for each truth kind:

| Truth kind | Maintained source | Derived or executable surface |
| --- | --- | --- |
| HTTP operation and wire shape | OpenAPI root plus referenced fragments | Deterministic bundle, provider models, consumer types, fixtures, and generated HTML |
| Cross-operation outcome | Arazzo referencing stable OpenAPI operation IDs | Respect or another conforming CLI runner |
| Environment lifecycle | Existing project-owned lifecycle glue | Process, database, fixture, restart, readiness, and cleanup orchestration |
| Non-HTTP domain behavior | Owning code and stable domain docs | Focused tests and links |

Keep these roles non-overlapping. Arazzo may define sequencing, value chaining, runtime inputs, and success criteria, but it must not restate OpenAPI request or response schemas.

## Authoring Source

Prefer OpenAPI-first when several provider or consumer languages, repositories, or agents need shared structured wire truth, compatibility must be reviewed before code drift, and generated provider boundary models are practical.

Prefer typed declarative code-first when one provider framework can export the complete OpenAPI contract deterministically from typed declarations. Reject the choice when manual repair is required or stale output cannot fail mechanically.

Use annotation- or comment-first generation only when annotations cover every operation and schema, the output is complete and deterministic, and missing or stale output fails a project-owned check.

For a legacy API, characterize registered routes and real protocol behavior, identify stable semantic truth, and adjudicate conflicts. Do not silently assume that either handwritten documentation or current implementation is correct.

## Source Layout And Bundle

Keep one file for a genuinely small contract. When operation count, schema count, ownership, or merge contention makes that hostile to review, keep one thin root and split maintained source by stable API domain rather than by arbitrary file size.

Provide one pinned project-owned command that resolves references, lints, and creates a deterministic bundle. Treat the bundle as generated:

- commit it with stale-output protection when portability, review, or agent context requires it
- otherwise write it to an ignored build root and regenerate it in every owning workflow

Do not maintain both fragments and a hand-edited bundle.

## Generated Projections

Generate only the provider and consumer wire boundary needed to remove duplication. Prefer models or types before a full runtime client when consumer adapters own authentication, cookies, retries, offline behavior, error mapping, or platform transport policy.

Do not generate domain models, persistence types, retry policy, UI state, or other non-wire behavior by default.

Generate human reference documentation from OpenAPI. Do not maintain an endpoint-by-endpoint Markdown API catalog as a coequal contract source.

## Workflows, Runner, And Lifecycle Glue

Use Arazzo for a small number of outcomes that require multiple operations, chained values, or state transitions. Keep workflow count proportional to business journeys, reference stable OpenAPI operation IDs, pass secrets as masked runtime inputs, and use synthetic examples.

Select a CLI/CI runner that follows OpenAPI references and verifies response status, schema, content type, success criteria, server overrides, and deterministic exit status. Prefer Redocly Respect when those capabilities, its supported Arazzo revision, and the repository runtime fit. Pin the executable revision; do not require Redocly hosted services.

Retain Python or Shell only as lifecycle glue when it owns dynamic process, database, fixture, restart, readiness, or cleanup orchestration. After runner equivalence is proven, remove duplicated business HTTP steps from that glue.

## Human, Ad Hoc, And GUI Interaction

Use generated HTML for human review or external reference when a publication owner and audience exist. Agents do not require a hosted documentation site.

Use Restish, curl, or a disposable single-operation Arazzo workflow for ad hoc exploration. Do not commit a second operation catalog for this use.

Add Bruno, Postman, Yaak, or another GUI collection only when a named GUI collaboration requirement justifies a generated or synchronized projection. Keep OpenAPI and Arazzo upstream; never treat the GUI collection as contract truth.
