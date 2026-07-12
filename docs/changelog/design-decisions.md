# Design Decisions

## 2026-07-07 - Structured Source Tree And Generated Install Surfaces

### Failure Mode

The flat skill directory made source ownership, install compatibility, and runtime support look like one undifferentiated surface.

### Change

Skill source moved under `src/skills/`, while the tracked runtime compatibility surface is generated into `skills/` and external install surfaces can be generated into `.dist/claude/` and `.dist/codex/`.

### Operational Impact

- Edit `src/skills/**`, not generated `skills/**`.
- Regenerate the tracked surface with `python3 scripts/flatten-skills.py --target root-flat`.
- Validate with `bash scripts/check.sh`.

## 2026-07-10 - Keep External Install Surfaces Reproducible

### Failure Mode

Tracking `.dist/` duplicated the structured source and root-flat runtime surface, expanded ordinary diffs, and made validation depend on committed packaging output that no current manifest or install path consumes.

### Change

Keep `skills/` as the tracked generated runtime compatibility surface. Ignore `.dist/` and generate Claude and Codex external surfaces only on demand. Aggregate validation now generates those external targets in a temporary directory.

### Operational Impact

- A fresh clone can validate external install surfaces without a pre-existing `.dist/` tree.
- `bash scripts/check.sh` rejects tracked `.dist/` files.
- Packaging or inspection may still run `python3 scripts/flatten-skills.py --target claude` or `--target codex` explicitly.

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

## 2026-07-10 - Native Skill Composition And Controller-Owned Repair

### Failure Mode

An unconditional session router duplicated Codex native discovery, public names obscured controller/evaluator hierarchy, and installed controller skills could not see the repo-global invocation contract. Detailed repair mechanics also remained in the review component even though the execution workflow was documented as lifecycle owner.

### Change

- Rename `execute-change` to `implement-change` and `review-code-impl` to `review-implementation`.
- Keep `review-implementation` read-only and move implementation repair ownership into `implement-change`.
- Install `references/workflow.toml` and `references/repair-loop.md` with the controller.
- Make `use-coding-skills` optional so workflow and policy skills compose through native description matching.

### Operational Impact

- Contract validation checks installed workflow nodes, edges, cycles, evaluator direction, and unique repair ownership.
- Implementation repair expects convergence within five rounds and stops at ten.
- `agents/openai.yaml` remains product metadata; runtime graph contracts live under directly linked `references/`.
- `docs/architecture/workflow-orchestration.md` is the stable maintenance view of lifecycle, DAG, and repair semantics.
- PlantUML views are generated from the installed controller contract and checked for drift by the aggregate validation path.

## 2026-07-10 - Shared Rendering Baseline And Semantic Output Deltas

### Failure Mode

Domain skills could duplicate generic response-shape rules and expose every internal analysis axis as a mandatory section. In practice, `analyze-project` loaded alongside `output-styles` still produced a low-density eight-section report for a narrow operational question.

### Change

- Make `output-styles` the shared conversational rendering baseline.
- Select one primary skill to own the response's domain order and conclusion.
- Treat other matched skills as semantic overlays rather than independent report generators.
- Make `analyze-project` selectively terse by default and move its comprehensive audit shape into a conditionally loaded reference.

### Operational Impact

- Narrow project-state answers render only relevant facts, boundaries, risks, and actions.
- Full truth maps remain available for explicit comprehensive audit requests.
- Durable artifacts and machine-consumed schemas keep their specialized output contracts.
- Installed skill surfaces carry the same ownership and rendering rules after regeneration.

## 2026-07-11 - Bounded Agent-Native Review

### Failure Mode

External semantic review runners selected a reviewer process, built exhaustive prompts, normalized severity into blocking state, and encouraged repeated repository-wide discovery. Findings did not require a causal link to the current task diff, so moved legacy code and pre-existing adjacent debt could expand an approved implementation plan.

### Change

- Retire external semantic review runners, provider adapters, reviewer schemas, and runner-specific eval/smoke infrastructure.
- Let the current coding agent prefer one reviewer subagent for non-trivial bounded review or review directly for small mechanical work.
- Require a bounded review brief with the approved task slice, exact diff, oracles, touch set, and justified supporting files.
- Require change causality and an approved-contract violation for blocker eligibility.
- Keep final finding disposition and repair authority with the main agent.
- Move deterministic artifact-DAG support under `_harness-libs`.

### Operational Impact

- Review skills remain portable because they describe agent roles without selecting a model, provider, or external reviewer command.
- Moving or renaming unchanged code does not activate pre-existing defects.
- Only main-agent `accepted` findings enter controller-owned repair.
- Normal implementation review uses one initial bounded review and one focused verification review, with at most one additional same-slice repair attempt.
- `test-agent-native-review.sh` and `test-artifact-dag.sh` replace external reviewer-runner smoke coverage.
