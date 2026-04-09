# AGENTS.md

For human-facing project overview and skill inventory, see `README.md`.

## Project

This repository is a local Claude Code plugin marketplace and plugin source for `coding@csheng`.

The plugin provides:
- sovereign harness kernel entries under `skills/`
- lower-plane language and tooling skills under `skills/`
- helper commands under `commands/`
- plugin manifests under `.claude-plugin/`
- review system infrastructure under `skills/_review-libs/`

Current plugin identity:
- plugin name: `coding`
- marketplace name: `csheng`
- current version: `1.1.0`

## Repository Layout

- `.claude-plugin/plugin.json`: plugin manifest
- `.claude-plugin/marketplace.json`: local marketplace manifest
- `skills/`: plugin skills covering the sovereign harness kernel, truth-plane docs skills, evaluation-plane review skills, policy/guideline skills, git workflow, infrastructure, and documentation
- `skills/_review-libs/`: shared review system infrastructure
  - `schemas/`: reviewer output schemas
  - `eval/`: evaluation framework with golden test cases
  - `smoke-test/`: smoke test harness and fixtures
  - `drivers/`: cross-CLI drivers (claude, codex, gemini)
- `commands/`: plugin command docs
- `hooks/`: post-edit validation hooks
- `install.sh`: registers the local marketplace in Claude settings

## Sovereign Harness Kernel

Top-level harness authority in this repository is:

- `analyze-project`
- `design-change`
- `plan-change`
- `execute-change`
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
- `review-change` and `execute-change` must return deterministic machine-checkable stop states instead of vague optional continuation
- `execute-change` treats an approved plan as one execution unit and should not stop mid-plan merely because one task completed
- `execute-change` should default to a one-time worktree preflight reminder before first implementation when still in the current checkout

Lower-plane skills support the kernel:
- truth plane: `analyze-project`, `organize-docs`
- evaluation plane: `review-design`, `review-plan`, `review-code-impl`, `skills/_review-libs/`
- policy plane: guideline, standards, security, and testing skills
- execution-support plane: git/worktree/fetch/registry helpers

Plugin command surface mirrors the seven top-level harness entries:

- `/analyze-project`
- `/design-change`
- `/plan-change`
- `/execute-change`
- `/review-change`
- `/sync-truth`
- `/close-change`

These commands are Claude Code plugin entry points only. Do not treat them as permission to modify user-global Codex state.

## Working Rules

- Keep the sovereign harness kernel as the only top-level authority.
- Keep skills thin and operational.
- Treat `skills/` as the source of truth for behavior; wrappers in `agents/` should stay thin.
- Prefer explicit validation and deterministic workflows over vague prompt guidance.
- When documenting shell examples, do not teach interpolation of untrusted input.
- For cross-model review flows, keep reviewer, judge, and fixer responsibilities separate.
- Route review through `review-change` at the harness layer; treat `review-*` skills as lower-plane evaluators.
- Keep execution serial-first unless a plan defines a dependency-frozen batch with explicit human approval.
- Do not assume unattended execution.
- Treat task-ledger execution as lower-plane execution support under `execute-change`, not as a second top-level authority.

## Documentation Skills

- Use `analyze-project` for read-only project explanation and drift detection.
- Use `sync-truth` when a verified change has real truth impact and stable truth must be updated.
- Use `organize-docs` as lower-plane stable-doc maintenance when truth sync changes docs boundaries or truth roots.

## Documentation Truth Boundary

- This repository uses a docs truth boundary.
- Long-lived project truth lives in root reference files plus stable `docs/` domains.
- `docs/superpowers/` and `docs/plans/` are stage artifacts in this repository and should stay out of default docs searches.
- Use `docs/.ignore` and `docs/AGENTS.md` as the repository-local contract for docs search behavior.
- Use `rg --no-ignore` only when the user explicitly needs historical context from stage artifacts.

## Review System

`review-design`, `review-plan`, and `review-code-impl` are lower-plane cross-model review skills used by the top-level `review-change` gate.

Key properties:
- opposite-driver review is the preferred path
- same-driver review is fallback only
- review is evidence-based
- repair mode is opt-in
- `repair-review` is an optional bounded helper for the main execution loop, not the primary lifecycle owner of a change
- reviewer output uses the shared schema in `skills/_review-libs/schemas/adversarial-reviewer-output.schema.json`
- direct validation uses `skills/_review-libs/smoke-test/smoke-cross-model-review.sh`
- default reviewer models are:
  - `codex`: `gpt-5.4`
  - `claude`: `claude-opus-4-6`
  - `gemini`: `gemini-3.1-pro-preview`
- reviewer execution modes are:
  - `codex`: read-only sandbox
  - `claude`: plan/read-only permission mode
  - `gemini`: `--approval-mode yolo`, constrained by isolated workspace and review-only prompt
- default review timeout is `1800` seconds per reviewer invocation

## Prerequisites

Required tools for validation and plugin management:
- `jq` (JSON linting)
- `bash` (syntax check via `bash -n`)
- `claude` CLI with plugin support

## Validation

Before considering review-system changes done, run as appropriate:

```bash
jq . skills/_review-libs/schemas/adversarial-reviewer-output.schema.json >/dev/null
bash -n skills/_review-libs/smoke-test/smoke-cross-model-review.sh
skills/_review-libs/smoke-test/smoke-cross-model-review.sh all --reviewer claude --timeout 1800
```

For sovereign harness command-surface changes, also run:

```bash
bash skills/_harness-libs/smoke-test/test-sovereign-command-surface.sh
bash skills/_harness-libs/smoke-test/test-design-runner.sh
bash skills/_harness-libs/smoke-test/test-plan-runner.sh
bash skills/_harness-libs/smoke-test/test-design-plan-command-control.sh
bash skills/_harness-libs/smoke-test/test-review-runner.sh
bash skills/_harness-libs/smoke-test/test-execute-runner.sh
bash skills/_harness-libs/smoke-test/test-review-execute-command-control.sh
```

Useful targeted runs:

```bash
skills/_review-libs/smoke-test/smoke-cross-model-review.sh plan --reviewer claude --timeout 1800
skills/_review-libs/smoke-test/smoke-cross-model-review.sh code-impl --reviewer claude --timeout 1800
skills/_review-libs/smoke-test/smoke-cross-model-review.sh all --reviewer codex --timeout 1800
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

Version bump procedure:

1. Update `.claude-plugin/plugin.json` `version`
2. Update `.claude-plugin/marketplace.json` plugin `version`
3. Validate the plugin after the change
4. Update the installed local plugin in Claude

## Local Update Guide

This project is installed from a local directory marketplace, not a remote registry.

That means:
- the source of truth is this repo
- version bumps are metadata and install/update markers
- Claude does not fetch a remote package for this plugin
- after updating the installed plugin, Claude Code must be restarted to apply changes

Marketplace registration:

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

## Notes

The repository may also contain user-local `.claude/` state. Do not treat that as plugin source of truth.
