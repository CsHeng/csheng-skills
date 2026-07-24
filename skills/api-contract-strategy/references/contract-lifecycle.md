# Contract Lifecycle

## Contract Ownership

Default to a provider repository as the source of truth for the Wire Contract.

This keeps implementation, compatibility evidence, and contract review in one change and avoids a second synchronization lifecycle.

Use an independent contract repository only when evidence shows one or more of:

- multiple provider implementations share one contract
- contract ownership and release lifecycle are independent from one provider
- multiple teams require stable governance or access boundaries
- external consumers need a separately versioned contract product

Multiple clients alone are not an upgrade trigger.

## Repository Architecture

Let `architecture-patterns` decide monorepo versus multi-repository structure. This skill consumes that decision.

For sibling repositories, define an explicit workspace contract such as:

```text
PROJECT_BACKEND_DIR
PROJECT_WEB_DIR
PROJECT_ANDROID_DIR
PROJECT_IOS_DIR
PROJECT_API_SPEC
```

Do not infer `../backend` or other sibling paths. Workspace layout, CI checkouts, agent context, and multiple clones vary.

The workspace contract is a development input, not a production dependency.

## Authoring And Bundle Lifecycle

Keep maintained OpenAPI source with its provider owner by default. Use one root and domain-grouped fragments when the contract is too large or contentious for one file.

Treat the resolved bundle as generated output. Commit it when portability, reviewability, or agent context matters and fail stale-output checks; otherwise generate it into an ignored build root. In either case, pin the tool and expose one deterministic project-owned lint and bundle command.

## Development Generation

Optimize for fast feedback:

```text
provider contract -> deterministic bundle -> local generation -> consumer types or client
```

Choose committed generated output when reviewability and agent context matter. Choose ignored generated output when regeneration is cheap and every build reliably owns it. In both cases, pin the generator and provide one project-owned command.

Small first-party teams should prefer simple local generation over a registry service.

## Release Generation

Optimize for reproducibility when consumers release independently:

```text
contract version -> pinned generator -> versioned artifact -> pinned consumer dependency
```

Record contract version, generator version, and generation metadata. Possible artifacts include npm, Maven, Swift Package, or an internal versioned Git artifact.

Do not publish an SDK artifact until a consumer needs an independent dependency lifecycle.

## Generated Client Scope

Select the smallest useful projection:

- schema/type projection
- request/response model projection
- full runtime client
- packaged SDK

Preserve mature consumer adapters when they own cookies, authentication, retries, offline behavior, error mapping, or platform transport. A type projection can remove DTO drift without replacing runtime policy.

## Upgrade Triggers

- Move to an independent contract repository after contract ownership demonstrably separates from the provider.
- Move from local generation to versioned artifacts when consumer releases require reproducible pinning.
- Move from types to a full client when repeated adapter churn exceeds integration and generator-upgrade cost.
- Add stronger governance when incompatible changes repeatedly escape existing deterministic gates.
