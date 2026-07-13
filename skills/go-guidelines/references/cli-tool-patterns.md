# Go CLI Tool Patterns

## Purpose

Build maintained command-line tools with an explicit operator contract, reviewable state changes, testable core behavior, and predictable binary delivery.

## Parser Selection

Use the standard library `flag` package for a single command with a small stable option set and no meaningful command tree.

Prefer Cobra for a formal internal or external CLI when one or more of these are expected:

- multiple or nested commands
- shell completion as a first-class operator feature
- command and flag deprecation, aliases, groups, or generated documentation
- a command tree likely to grow across multiple maintainers or agents
- dynamic argument or flag completion

Kong or another parser may be selected when an approved project explicitly values its typed declaration model and does not need Cobra's broader command ecosystem. Do not add a framework to a small command merely to follow a template.

## Project Shape

A growing CLI should keep framework code at the adapter boundary:

```text
cmd/tool/main.go        process setup and exit status
internal/cli            flag or Cobra adapters and rendering
internal/app            use cases and typed requests
internal/config         explicit configuration loading
internal/client         external API adapters
internal/output         JSON, YAML, and table renderers
```

Use command constructors instead of package-global command values and `init()` registration. Inject dependencies through constructors. A Cobra `RunE` adapter should validate CLI inputs, construct a typed request, call an application use case, and return its error; it should not own the business workflow.

Small commands do not need this complete directory tree. Preserve the same separation through functions and injected IO without manufacturing packages.

## IO And Exit Contract

- Write machine-consumable results to stdout.
- Write logs, progress, warnings, and diagnostics to stderr.
- Keep core logic independent from `os.Args`, process-global standard streams, and direct `os.Exit` calls.
- Centralize final error formatting and exit-code mapping at the process boundary.
- Offer explicit output modes such as `--output=json`, `--output=yaml`, or `--output=table` when automation consumes results.
- Do not silently change state-changing semantics merely because a TTY is present.

Use `log/slog` for structured diagnostic logging unless the existing project owns another logger. Avoid writing the same error as both a log entry and a returned error at multiple layers.

## Configuration And Credentials

Prefer an explicit precedence contract such as defaults, optional config file, environment, then CLI flags. Validate the final typed configuration once. Add a configuration framework only when the number of providers and merge rules justify it.

Keep secrets out of command arguments when shell history would expose them. Prefer environment variables, standard input, credential helpers, keychains, or project-owned secret providers. Never render a complete configuration object without redaction.

## Completion

For Cobra tools, expose generated completion for the shells the project supports. Reuse the same typed data source for execution and dynamic completion so command behavior and suggestions do not drift. Completion must be bounded, side-effect free, and fast enough for interactive use.

## State-Changing Safety

- Give destructive or high-impact commands an explicit dry-run or plan mode when the operation can be previewed.
- Make confirmation behavior explicit with flags such as `--yes`; do not hide a blocking prompt behind automatic TTY detection.
- Validate the complete target set before the first mutation.
- Preserve idempotency where the domain allows it.
- Define partial-failure, rollback, retry, and exit-code behavior before adding concurrency.
- Use `context.Context` for cancellation of network, filesystem, and subprocess work.
- When calling external programs, use `os/exec` with argument slices rather than constructing a Shell command string.

## Testing

Test core use cases directly with typed requests and injected dependencies. Test CLI adapters through explicit argument slices and injected stdin, stdout, and stderr rather than mutating global process state.

Use golden tests only for stable text such as help, completion, or generated configuration, and normalize colors, timestamps, paths, and other volatile values. Use a subprocess or testscript-style integration test only when process behavior, environment, exit status, or multi-command filesystem effects are the contract under test.

## Build And Delivery

- Use `go build` with an explicit `-o` path for main packages so validation does not leave binaries in the repository root.
- Write local artifacts to an ignored `dist/`, `bin/`, or repo-external temporary directory according to project policy.
- Use `-trimpath` when reproducible path-independent build metadata matters.
- Inject version, commit, and build date through project-owned build flags when operators need provenance.
- Deploy prebuilt binaries to production; do not make production depend on `go run`, module downloads, or a source checkout.
- Add GoReleaser only when release archives, checksums, multiple GOOS/GOARCH targets, package-manager publishing, SBOMs, or signing justify its configuration surface.

## Checklist

- parser choice matches command complexity
- framework types stop at the CLI adapter boundary
- stdout, stderr, exit codes, and output formats are explicit
- completion is side-effect free and uses shared data sources
- state-changing commands define preview, confirmation, partial failure, and rollback behavior
- tests cover core behavior and the material process contract
- `go build` writes to an explicit artifact path
