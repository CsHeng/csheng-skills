# Design Decisions

## 2026-07-07 - Structured Source Tree And Generated Install Surfaces

### Failure Mode

The flat skill directory made source ownership, install compatibility, and runtime support look like one undifferentiated surface.

### Change

Skill source moved under `src/skills/`, while flat install surfaces are generated into `skills/`, `.dist/claude/`, and `.dist/codex/`.

### Operational Impact

- Edit `src/skills/**`, not generated `skills/**`.
- Regenerate surfaces with `python3 scripts/flatten-skills.py --target all`.
- Validate with `bash scripts/check.sh`.

## 2026-07-07 - External Skill Contracts

### Failure Mode

Putting invocation and exposure rules in prompt text would mix machine-readable governance with model-facing instruction content.

### Change

`contracts/skills.toml` now owns skill source paths, public IDs, categories, lifecycle ownership, install exposure, and mutation guards.

### Operational Impact

- `SKILL.md` files stay prompt content.
- Contract drift is checked by `scripts/check-contracts.py`.
- `skills.index.json` is generated from the contract.

## 2026-07-07 - Remove Provider-Switching Review From Skill Layer

### Failure Mode

Provider-switching review expanded the harness failure surface and could create false confidence from mismatched external reviewer behavior.

### Change

Review is now same-driver by design. Provider switching is out of scope for the skills layer and belongs to a separate router or agent if it is reintroduced later.

### Operational Impact

- Review runners report `review_mode = same-driver`.
- External review reports may be attached as passive evidence.
- Active docs, commands, and skills must not advertise provider-switching review.

## 2026-07-07 - Workflow Modes Before Phase Implementation

### Failure Mode

The design-strength split carried too much routing responsibility.

### Change

`contracts/workflow-modes.toml` defines `read_only`, `micro`, `standard`, `regulated`, and `emergency` modes before phase implementation.

### Operational Impact

- `design-change` remains a phase implementation.
- Workflow mode selection decides whether design, plan, review, rollback, and fresh evidence gates apply.
