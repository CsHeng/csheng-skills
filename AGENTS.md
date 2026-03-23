# AGENTS.md

## Project

This repository is a local Claude Code plugin marketplace and plugin source for `coding@csheng`.

The plugin provides:
- language and tooling skills under `skills/`
- review agent wrappers under `agents/`
- helper commands under `commands/`
- plugin manifests under `.claude-plugin/`
- validation assets under `docs/` and `scripts/`

Current plugin identity:
- plugin name: `coding`
- marketplace name: `csheng`
- current version: `1.0.0`

## Repository Layout

- `.claude-plugin/plugin.json`: plugin manifest
- `.claude-plugin/marketplace.json`: local marketplace manifest
- `skills/`: plugin skills
- `agents/`: Claude agent wrappers for isolated review flows
- `commands/`: plugin command docs
- `docs/schemas/adversarial-reviewer-output.schema.json`: shared reviewer output schema
- `scripts/smoke-cross-model-review.sh`: direct cross-model smoke test harness
- `plans/`: design and implementation plans
- `install.sh`: registers the local marketplace in Claude settings

## Working Rules

- Keep skills thin and operational.
- Treat `skills/` as the source of truth for behavior; wrappers in `agents/` should stay thin.
- Prefer explicit validation and deterministic workflows over vague prompt guidance.
- When documenting shell examples, do not teach interpolation of untrusted input.
- For cross-model review flows, keep reviewer, judge, and fixer responsibilities separate.

## Review System

`review-design`, `review-plan`, and `review-code-impl` are cross-model review skills.

Key properties:
- opposite-driver review is the preferred path
- same-driver review is fallback only
- review is evidence-based
- repair mode is opt-in
- reviewer output uses the shared schema in `docs/schemas/adversarial-reviewer-output.schema.json`
- direct validation uses `scripts/smoke-cross-model-review.sh`
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
jq . docs/schemas/adversarial-reviewer-output.schema.json >/dev/null
bash -n scripts/smoke-cross-model-review.sh
scripts/smoke-cross-model-review.sh all --reviewer claude --timeout 1800
```

Useful targeted runs:

```bash
scripts/smoke-cross-model-review.sh plan --reviewer claude --timeout 1800
scripts/smoke-cross-model-review.sh code-impl --reviewer claude --timeout 1800
scripts/smoke-cross-model-review.sh all --reviewer codex --timeout 1800
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
