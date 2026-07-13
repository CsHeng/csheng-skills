# AGENTS.md

For human-facing project overview and skill inventory, see `README.md`.

## Project

This repository is a local Claude Code and Codex plugin marketplace and plugin source for `coding@csheng`.

The plugin provides:
- sovereign harness kernel entries under `src/skills/`
- optional session routing, session-boundary, and output-style skills under `src/skills/`
- lower-plane language and tooling skills under `src/skills/`
- helper commands under `commands/`
- plugin manifests under `.claude-plugin/` and `.codex-plugin/`
- deterministic lifecycle and artifact-DAG support under `src/skills/_internal/_harness-libs/`, generated into `skills/_harness-libs/`

Current plugin identity:
- plugin name: `coding`
- marketplace name: `csheng`
- current version: `1.1.0`

## Repository Layout

- `.claude-plugin/plugin.json`: Claude plugin manifest
- `.claude-plugin/marketplace.json`: Claude local marketplace manifest
- `.codex-plugin/plugin.json`: Codex plugin manifest; keep Claude-only fields such as `hooks` out of this file
- `.codex-marketplace/.agents/plugins/marketplace.json`: Codex local marketplace manifest
- `.codex-marketplace/plugins/coding`: symlink back to this repository root so Codex can consume the expected `./plugins/coding` marketplace source shape without moving the repository
- `src/skills/`: source-of-truth skill tree grouped by workflow/session/discipline/policy/tool/git/review/internal category
- `contracts/skills.toml`: source-of-truth skill exposure and invocation contract
- `skills/`: tracked generated root-flat compatibility surface used by current plugin manifests, command wrappers, and local symlink exposure
- `.dist/claude/`, `.dist/codex/`: ignored, reproducible target-specific flat skill surfaces generated only when needed
- `skills/_harness-libs/`: generated root-flat deterministic lifecycle and artifact-DAG runtime support; do not route user workflows directly to it
- `src/skills/_internal/_harness-libs/artifact-dag.sh`: design/plan linkage, implementation-surface, and allowed-touch-set enforcement shared by plan, execution, and truth-sync runners
- `commands/`: plugin command docs
- `docs/architecture/workflow-orchestration.md`: canonical maintenance view of lifecycle routing, the installed implementation DAG, and controller-owned repair
- `docs/architecture/diagrams/`: generated PlantUML views of the controller-local workflow contract; do not edit by hand
- `hooks/`: post-edit validation hooks
- `install.sh`: registers the local marketplace in Claude settings
- `install-codex.sh`: registers this repository as a Codex local marketplace and installs `coding@csheng`

## Sovereign Harness Kernel

Top-level harness authority in this repository is:

- `analyze-project`
- `design-change`
- `plan-change`
- `implement-change`
- `review-change`
- `sync-truth`
- `close-change`

This control plane owns request routing, phase transition, rollback depth, parallelization permission, policy injection timing, and completion judgment.

Kernel defaults:
- serial-first execution
- human-sovereign approvals at design, plan, truth-sync, and close
- no unattended execution by default
- `design-change` and `plan-change` do not complete on artifact write alone; they require validation and mandatory review before the human gate
- artifact handoff is gated by explicit `approval_status`, not by prose reminders alone
- `review-change` and `implement-change` must return deterministic machine-checkable stop states instead of vague optional continuation
- `implement-change` treats an approved plan as one execution unit and should not stop mid-plan merely because one task completed
- `implement-change` should default to a one-time worktree preflight reminder before first implementation when still in the current checkout

Lower-plane skills support the kernel:
- session plane: `use-coding-skills`, `output-styles`
- truth plane: `analyze-project`, `organize-docs`
- evaluation plane: `review-design`, `review-plan`, and `review-implementation`, coordinated by the coding agent through `review-change`
- policy plane: guideline, standards, security, executable-oracle, and testing skills
- execution-support plane: git/worktree/fetch/registry helpers

Planning and ad hoc tooling stay separate: `plan-change` composes `language-decision-tree` only when a task introduces or replaces a persisted implementation boundary, while `tool-decision-tree` owns agent ad hoc command choice and composition. Language guideline skills apply after the implementation language is fixed; `go-guidelines` then selects its CLI-tool or API-service profile as appropriate.

Plugin command surface mirrors the seven top-level harness entries:

- `/analyze-project`
- `/design-change`
- `/plan-change`
- `/implement-change`
- `/review-change`
- `/sync-truth`
- `/close-change`

These commands are Claude Code plugin entry points only. Codex can consume the generated root `skills/` inventory through `.codex-plugin/plugin.json` when installed. Local environments may also expose the same generated `skills/` tree through agent-specific skill paths such as `~/.agents/skills/coding`. Do not treat Claude command docs as permission to modify user-global Codex state.

## Working Rules

- Keep the sovereign harness kernel as the only top-level authority.
- External workflow skills, including retired or third-party agent harnesses, may provide lower-plane technique guidance only; they must not override this repository's phase routing, approval gates, artifact locations, review defaults, or close judgment.
- Keep reusable behavior agent-agnostic by default. Skills should describe portable workflow contracts, not Codex-only, Claude-only, or UI-only prompt mechanics, unless the file is explicitly scoped to that agent surface.
- Prefer `src/skills/` plus direct references for reusable behavior. Keep agent-specific wrappers, commands, hooks, and install notes thin.
- Treat `use-coding-skills` as an optional router for ambiguous multi-stage work and session-boundary guidance; directly matched workflow and policy skills do not require it first.
- Keep skills thin and operational.
- Treat `src/skills/` and `contracts/skills.toml` as the source of truth for behavior and exposure; generated `skills/` should be refreshed, not edited by hand.
- Prefer explicit validation and deterministic workflows over vague prompt guidance.
- Use `output-styles` as the shared conversational rendering baseline. Select one primary skill to own domain order and treat other matched skills as semantic overlays rather than independent report generators.
- Keep fixed output schemas inside the skill that owns a durable artifact or machine-consumed result; ordinary conversational skills should render only decision-relevant parts of their internal checklist.
- When documenting shell examples, do not teach interpolation of untrusted input.
- For review flows, keep reviewer, main-agent judge, and controller-owned fixer responsibilities separate.
- Review is agent-native: prefer a reviewer subagent for non-trivial bounded review, allow direct main-agent review for small mechanical work, and never delegate recursively.
- Give reviewers a bounded brief containing the approved task slice, exact diff, oracles, touch set, and justified supporting files; do not invite repository-wide discovery.
- Treat reviewer findings as candidates. Only main-agent `accepted` dispositions may enter repair, and every accepted candidate must have qualifying change causality plus an approved-contract violation.
- Route review through `review-change` at the harness layer; treat `review-*` skills as lower-plane evaluators.
- Keep execution serial-first unless a plan defines a dependency-frozen batch with explicit human approval.
- Do not assume unattended execution.
- Treat task-ledger execution as lower-plane execution support under `implement-change`, not as a second top-level authority.
- Treat decision discovery as a bounded design-phase clarification loop, not as a new top-level workflow.
- New metadata-based plans should declare work-package readiness, executable oracle strategy, review budget, and subagent readiness before review.
- Design and plan review remain bounded by their human gates. Implementation repair belongs to `implement-change` and normally uses one initial bounded review plus one focused verification review, with at most one additional same-slice repair attempt.

## Documentation Skills

- Use `analyze-project` for read-only project explanation and drift detection.
- Use `sync-truth` when a verified change has real truth impact and stable truth must be updated.
- Use `organize-docs` as lower-plane stable-doc maintenance when truth sync changes docs boundaries or truth roots.

## Documentation Truth Boundary

- This repository uses a docs truth boundary.
- Long-lived project truth lives in root reference files plus stable `docs/` domains.
- `docs/plans/` is the single stage-artifact root in this repository and should stay out of default docs searches.
- Stable workflow truth belongs in `docs/architecture/workflow-orchestration.md`; generated diagrams remain subordinate to machine contracts.
- Use `docs/.ignore` and `docs/AGENTS.md` as the repository-local contract for docs search behavior.
- Use `rg --no-ignore` only when the user explicitly needs historical context from stage artifacts.

## Review System

`review-design`, `review-plan`, and `review-implementation` are lower-plane review skills used by the top-level `review-change` gate.

Key properties:
- the main coding agent chooses preferred subagent review or direct main-agent review without selecting an external reviewer tool
- a delegated reviewer receives only a bounded review brief and cannot delegate recursively
- review is evidence-based and causality-bound to the current artifact diff or task slice
- reviewers return candidate findings; the main agent adjudicates them before any repair
- `review-implementation` is a read-only evaluator; `implement-change` alone owns implementation repair, mutation, continuation, and typed exits
- `review-design` and `review-plan` default to boundary-focused review: architecture/surface/DAG/oracle/ownership/rollback blockers only
- `review-implementation` reviews only the exact task diff, task tests, declared oracles, and justified direct dependencies
- moving or renaming unchanged code does not activate pre-existing defects
- low-confidence, pre-existing, unrelated, future-phase, and plan-expanding observations cannot become automatic repair
- focused verification checks accepted repairs and repair-introduced regressions without reopening repository-wide discovery

## Prerequisites

Required tools for validation and plugin management:
- `jq` (JSON linting)
- GNU-compatible `realpath` with `--relative-to` support (coreutils on macOS)
- GNU/Homebrew Bash 4 or newer (runtime namerefs, associative arrays, `mapfile`, and syntax checks)
- `claude` CLI with plugin support
- `codex` CLI with plugin support

## Validation

After editing source skills, contracts, scripts, or architecture docs, regenerate and run the aggregate check:

```bash
python3 scripts/generate-skills-index.py
python3 scripts/flatten-skills.py --target root-flat
python3 scripts/generate-workflow-diagrams.py
bash scripts/check.sh
```

The aggregate check generates and validates Claude and Codex install surfaces in a temporary directory. Generate `.dist/` explicitly only when a local external surface is needed.

Before considering review-system changes done, run:

```bash
bash skills/_harness-libs/smoke-test/test-agent-native-review.sh
bash skills/_harness-libs/smoke-test/test-artifact-dag.sh
```

For Codex plugin metadata changes, also run:

```bash
uvx --with pyyaml python "$HOME/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py" .
```

For sovereign harness command-surface changes, also run:

```bash
bash skills/_harness-libs/smoke-test/test-sovereign-command-surface.sh
bash skills/_harness-libs/smoke-test/test-design-runner.sh
bash skills/_harness-libs/smoke-test/test-plan-runner.sh
bash skills/_harness-libs/smoke-test/test-design-plan-command-control.sh
bash skills/_harness-libs/smoke-test/test-agent-native-review.sh
bash skills/_harness-libs/smoke-test/test-artifact-dag.sh
bash skills/_harness-libs/smoke-test/test-execute-runner.sh
bash skills/_harness-libs/smoke-test/test-review-execute-command-control.sh
```

## Versioning

### Development Workflow (Pre-Release)

During active development before external release:

1. Make code/doc changes
2. Run validation
3. Uninstall and reinstall plugin:

```bash
claude plugin uninstall coding@csheng
claude plugin install coding@csheng
```

4. Restart Claude Code to apply changes

No version bump needed - changes are picked up from the local directory.

### Release Workflow (External Distribution)

When preparing for external release, keep these versions in sync:
- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`
- `.codex-plugin/plugin.json`

Version bump procedure:

1. Update `.claude-plugin/plugin.json` `version`
2. Update `.claude-plugin/marketplace.json` plugin `version`
3. Update `.codex-plugin/plugin.json` `version`
4. Validate the plugin after the change
5. Update the installed local plugin in Claude and Codex

## Local Update Guide

This project is installed from a local directory marketplace, not a remote registry.

That means:
- the source of truth is this repo
- version bumps are metadata and install/update markers
- Claude does not fetch a remote package for this plugin
- after updating the installed plugin, Claude Code must be restarted to apply changes

Claude marketplace registration:

```bash
./install.sh
```

Plugin install:

```bash
claude plugin install coding@csheng
```

Plugin update after local changes:

```bash
claude plugin marketplace update csheng
claude plugin update coding@csheng
```

Verification:

```bash
claude plugin list
```

Expected result:
- `coding@csheng`
- desired version shown
- `Status: enabled`

After update:
- restart Claude Code to apply changes

Codex marketplace registration:

```bash
./install-codex.sh
```

Codex plugin update after local changes when the plugin install surface is in use:

```bash
uvx --with pyyaml python "$HOME/.codex/skills/.system/plugin-creator/scripts/update_plugin_cachebuster.py" .
codex plugin add coding@csheng
```

After update:
- start a new Codex thread to pick up refreshed plugin skills and metadata

Symlink exposure is also supported on workstations that manage shared skills through `~/.agents/skills/coding`. In that mode, update this repository and start a new agent session; do not require Codex plugin registration for the skills to be usable.

## Notes

The repository may also contain user-local `.claude/` state. Do not treat that as plugin source of truth.
