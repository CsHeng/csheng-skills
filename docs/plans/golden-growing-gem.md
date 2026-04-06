# Review System & Plugin Improvement Plan

## Context

Three external articles converge on one thesis: harness quality dominates model quality in agentic systems. Our review-{plan,design,code-impl} skills have solid mechanics (workspace isolation, cross-model drivers, repair loops, schema validation) but lack the cybernetic feedback loop to calibrate and improve review quality. Key gaps identified:

1. No eval system — impossible to measure whether reviews catch real issues or produce noise
2. Thin prompts — 15-line reviewer prompts with zero domain knowledge, no calibration examples, no severity guidance
3. No deterministic evidence — relies entirely on LLM judgment; no static analysis integration
4. Known bugs — verdict/blocking inconsistency, broken agents, missing smoke test coverage
5. Monolithic skills — 200+ line SKILL.md files consuming persistent context budget

Sources: harness engineering cybernetics (@odysseus0z), agent evaluation Pass@k/Pass^k (@HiTw93 Ch.8), progressive skill disclosure & context engineering (@HiTw93 Claude Code deep dive).

---

## Phase A: Bug Fixes (immediate, no dependencies)

### A.1 — Fix verdict vs blocking_findings inconsistency

File: `skills/_review-libs/run-review.sh`, function `build_run_output()` (line ~611)

Current: if reviewer returns FAIL with only Minor findings, `blocking_findings=[]` but `status="needs_fixes"` — inconsistent. Also: if reviewer returns PASS but Critical findings exist, it passes through unchallenged.

Fix: add deterministic reconciliation after extracting blocking findings:
- FAIL + empty blocking → override to PASS with `reconciliation_note`
- PASS + Critical present → override to FAIL with `reconciliation_note`

This is harness-level enforcement (Watt's governor pattern), not LLM judgment.

### A.2 — Claude driver effort level

File: `skills/_review-libs/drivers/claude.sh` (line 48)

Change `--effort low` to remove it entirely (default = high) or make it configurable via `--effort` flag. Reviews require deep analysis; low effort is a false economy. The codex driver already uses `medium`.

### A.3 — Add design mode to smoke test

File: `scripts/smoke-cross-model-review.sh`

Current: only tests `plan` and `code-impl`. Add `design` mode with a fixture doc.

New file: `scripts/fixtures/sample-design.md` (minimal design doc for smoke testing)

### A.4 — Clean up broken syntax review agents

Files: `agents/review-{golang,pwsh,python,shell}-syntax.md`

These reference deleted SKILL.md files. Either remove the agents or recreate minimal skill stubs. Removal is preferred since the agents are not part of the cross-model review system.

### Verification

```bash
bash -n skills/_review-libs/run-review.sh
bash -n skills/_review-libs/drivers/claude.sh
scripts/smoke-cross-model-review.sh all --reviewer claude --timeout 1800
```

---

## Phase B: Eval System (harness engineering core)

Rationale: "Fix the eval system before adjusting the Agent." Without measurement, every subsequent change is blind.

### B.1 — Golden dataset

New directory: `eval/golden/`

Per review mode, create 2 cases each (6 total):
- Seeded defect case: artifact with known issues, expected FAIL + specific findings
- Clean case: artifact that should PASS (false-positive calibration)

Each case is a JSON manifest + input file:
```json
{
  "id": "plan-001-missing-rollback",
  "mode": "plan",
  "input_file": "plan-001-input.md",
  "expected_verdict": "FAIL",
  "expected_findings": [
    { "severity": "Critical", "match_pattern": "rollback|revert" }
  ],
  "false_positive_categories": ["style", "naming"]
}
```

### B.2 — Eval runner

New file: `eval/run-eval.sh`

Interface:
```bash
eval/run-eval.sh --mode plan --reviewer claude --runs 3 --timeout 1800
eval/run-eval.sh --mode all --reviewer codex --runs 1
```

Metrics computed:
| Metric | Formula |
|---|---|
| Detection rate (Pass@k) | expected findings found / total expected |
| False positive rate | unexpected Critical/Important / total findings |
| Verdict accuracy | correct PASS/FAIL / total cases |
| Consistency (Pass^3) | same verdict across 3 runs of same case |

Output: structured JSON per `eval/schema/eval-result.schema.json`.

### B.3 — Integrate into smoke test

File: `scripts/smoke-cross-model-review.sh`

Add `eval` mode: runs golden dataset, gate on minimum detection rate (start at 60%).

### Verification

```bash
bash -n eval/run-eval.sh
eval/run-eval.sh --mode plan --reviewer claude --runs 1 --timeout 1800
```

---

## Phase C: Prompt Calibration (highest leverage after eval)

Rationale: "The agent is failing because the knowledge it needs is locked inside your head, and you haven't externalized it."

### C.1 — Calibration reference files

New files per skill (9 total, 3 per review mode):
- `skills/review-{plan,design,code-impl}/references/good-finding-example.md` — well-formed finding with evidence
- `skills/review-{plan,design,code-impl}/references/bad-finding-example.md` — vague anti-pattern
- `skills/review-{plan,design,code-impl}/references/severity-guide.md` — when to use Critical/Important/Minor with domain examples

### C.2 — Restructure prompt generation

File: `skills/_review-libs/run-review.sh`, functions `make_{design,plan,code_impl}_prompt()`

Current prompts (~15 lines): role + file reference + dimension list + schema shape + exhaustiveness.

Target structure (~40 lines + injected references):
```
## Role
Adversarial reviewer for {mode} documents.

## Concern Lenses (evaluate ALL)
1. {lens} — {focus}
2. {lens} — {focus}
3. {lens} — {focus}

## Severity Calibration
{injected from severity-guide.md}

## Example: Well-Formed Finding
{injected from good-finding-example.md}

## Anti-Pattern: Vague Finding (DO NOT produce)
{injected from bad-finding-example.md}

## Evidence Standard
- location: specific file:line or section heading, never "various"
- evidence: quoted text, never paraphrase without anchor
- fix: actionable change, never "consider improving"

## Prior Context
{structured summary from --prior-findings, not raw JSON dump}

## Output
{schema}
```

The prompt builder reads reference files from the skill's `references/` directory based on the current mode. This is progressive disclosure at the harness level.

### C.3 — Multi-lens coverage tracking

Current: reviewer returns single `lens` string. The schema only has one `lens` field but skills specify 3 concern areas.

Option A (schema change): add `lenses_evaluated` array + per-finding `lens` field.
Option B (prompt-only): instruct reviewer to set `lens` to comma-joined list, validate coverage in `validate_reviewer_output()`.

Recommend Option B first (no schema break), upgrade to A later if eval shows lens coverage gaps.

### C.4 — Structured prior-findings injection

File: `skills/_review-libs/run-review.sh`, function `emit_prior_findings_context()`

Current: `$(cat "$PRIOR_FINDINGS_PATH")` raw JSON dump into heredoc. At scale this is fragile and wastes context.

Fix: extract a structured summary via jq before injection:
```bash
jq -r '.[] | "- [\(.severity)] \(.location): \(.evidence | .[0:120])"' "$PRIOR_FINDINGS_PATH"
```

This produces human-readable bullet points instead of raw JSON.

### Verification

```bash
# Eval before/after
eval/run-eval.sh --mode all --reviewer claude --runs 3
# Detection rate must increase or hold
# False positive rate must not increase
```

---

## Phase D: Deterministic Augmentation (code-impl focus)

Rationale: "Basic feedback loops (tests, CI) are table stakes." The reviewer currently has zero deterministic evidence.

Boundary clarification: PostToolUse hooks (post-edit-check.sh) enforce lint/format during the HOST's editing session. However, the reviewer (codex/gemini) runs in an isolated CLI invocation with zero access to host hooks. Phase D pre-checks provide deterministic evidence at the reviewer's input boundary:
- In review-only mode: code may not have been through the hook pipeline
- In repair-review mode: hooks catch issues during host edits, but pre-checks give the reviewer confirmed anchors to avoid hallucinating lint findings
- The SKILL.md files do NOT need to duplicate lint/format rules — hooks handle enforcement, pre-checks handle evidence

### D.1 — Pre-review checks framework

New file: `skills/_review-libs/pre-checks.sh`

For code-impl mode, run available static analysis tools on files in scope:
| Language | Tool | Check |
|---|---|---|
| Shell | `shellcheck` | lint |
| Python | `ruff check` | lint |
| Go | `go vet` | vet |
| JSON | `jq .` | syntax |
| Markdown | heading structure | format |

For plan/design mode: validate markdown structure, check for broken internal links.

Output: JSON array of deterministic findings, each with `source`, `file`, `line`, `message`.

Hard timeout: 10 seconds total for all pre-checks.

Tool discovery is opportunistic: only run checks for tools that are available (`command -v`). No hard dependencies.

### D.2 — Inject into prompt

File: `skills/_review-libs/run-review.sh`

After building the main prompt, append pre-check results:
```
## Static Analysis Results (confirmed, not suggestions)
{pre-check findings or "No issues found by static analysis."}
```

### D.3 — Relationship to hooks

The pre-checks framework reuses the same tool list as hooks where applicable. The distinction:
- Hooks → real-time enforcement during editing (host-side)
- Pre-checks → evidence collection for the reviewer (reviewer-side input)
- SKILL.md → no lint/format details needed (hooks enforce, pre-checks provide evidence)

### Verification

- `bash -n skills/_review-libs/pre-checks.sh`
- Eval detection rate for seeded syntax errors reaches 95%+

---

## Phase E: Progressive Skill Disclosure (context optimization)

Rationale: SKILL.md files are loaded into persistent context. At 200+ lines each, three review skills consume ~600 lines of context budget.

### E.1 — Slim down SKILL.md files

Target: reduce each SKILL.md from ~200 lines to ~60 lines by extracting detail into `references/`:
- Move CLI examples to `references/cli-examples.md`
- Move evidence contract details to `references/evidence-contracts.md`
- Move security requirements to `references/security-rules.md`
- Keep: trigger description, concern lens summary, invocation shim path, output schema reference, compact instructions
- Do NOT add lint/format/check details — those are handled by hooks and pre-checks (Phase D)

### E.2 — Add Compact Instructions

Each SKILL.md gets:
```markdown
## Compact Instructions
Preserve: trigger conditions, lens names, shim path.
Drop: examples, error details, security specifics (recoverable from references/).
```

### Verification

- All smoke tests pass
- Eval scores unchanged
- Total SKILL.md size reduced 60%+

---

## Phase F: Plugin Improvements (polish)

### F.1 — Review health check command

New file: `commands/review-health.md`

Checks: driver scripts exist + executable, schema files valid, required tools available, reviewer CLIs reachable. Reports availability matrix.

### F.2 — Orchestrator decomposition

File: `skills/_review-libs/run-review.sh` (751 lines)

Extract into focused modules sourced by the orchestrator:
- `skills/_review-libs/prompt-builder.sh` — prompt generation
- `skills/_review-libs/output-validator.sh` — normalization + validation
- `skills/_review-libs/workspace.sh` — workspace preparation

Orchestrator reduces to ~200 lines of flow control.

### Verification

```bash
bash -n skills/_review-libs/run-review.sh
bash -n skills/_review-libs/prompt-builder.sh
bash -n skills/_review-libs/output-validator.sh
bash -n skills/_review-libs/workspace.sh
scripts/smoke-cross-model-review.sh all --reviewer claude --timeout 1800
```

---

## Implementation Order

```
Phase A (bugs)          ← immediate, no deps
Phase B (eval)          ← parallel with A
Phase C (prompts)       ← after B (need eval to measure)
Phase D (pre-checks)    ← after C (need prompt structure)
Phase E (skill slim)    ← after C+D (reference files and hook/pre-check boundary stabilized)
Phase F (polish)        ← after all
```

A and B are parallelizable. C through F are sequential.

---

## Critical Files

| File | Phases |
|---|---|
| `skills/_review-libs/run-review.sh` | A.1, C.2, C.4, D.2, F.2 |
| `skills/_review-libs/drivers/claude.sh` | A.2 |
| `scripts/smoke-cross-model-review.sh` | A.3, B.3 |
| `docs/schemas/adversarial-reviewer-output.schema.json` | C.3 (if option A) |
| `skills/review-{plan,design,code-impl}/SKILL.md` | E.1, E.2 |
| `commands/review-{plan,design,code-impl}.md` | unchanged |
| `hooks/post-edit-check.sh` | unchanged (D.3 clarifies boundary) |
