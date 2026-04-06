# Sovereign Harness Kernel V1 Implementation Plan

> For agentic workers: required execution workflow is task-by-task with explicit checkboxes and review checkpoints. Subagent-driven execution is preferred when implementation starts.

Goal: establish the first self-owned top-level harness authority in this repository by introducing request classification, top-level routing, phase control, evaluation gating, rollback resolution, and a minimal serial-first execution spine.

Architecture: build the control kernel first and keep it small. Reuse the current truth plane and evaluator plane instead of replacing them. Delay explicit parallel scheduling and unattended execution until the authority kernel is stable.

Tech Stack: Markdown skill files, Bash runtime helpers, jq-backed structured records, shell smoke tests, existing review runtime under `skills/_review-libs`

---

## Upstream Design

- design_ref: docs/superpowers/specs/2026-04-06-sovereign-harness-kernel-v1-design.md
- design_version: 2026-04-06-initial

## Implementation Scope

- scope_slice: V1 top-level authority kernel plus minimal top-level entry spine, using the existing truth and evaluator substrata
- impl_file_refs:
  - AGENTS.md
  - README.md
  - skills/design-change/SKILL.md
  - skills/plan-change/SKILL.md
  - skills/execute-change/SKILL.md
  - skills/review-change/SKILL.md
  - skills/sync-truth/SKILL.md
  - skills/close-change/SKILL.md
  - skills/_harness-libs/contracts.sh
  - skills/_harness-libs/classifier.sh
  - skills/_harness-libs/router.sh
  - skills/_harness-libs/phase-engine.sh
  - skills/_harness-libs/evaluation-gate.sh
  - skills/_harness-libs/rollback.sh
  - skills/_harness-libs/smoke-test/test-kernel-contracts.sh
  - skills/_harness-libs/smoke-test/test-kernel-routing.sh
  - skills/_harness-libs/smoke-test/test-kernel-phase.sh
  - skills/_harness-libs/smoke-test/test-kernel-rollback.sh
- test_file_refs:
  - skills/_harness-libs/smoke-test/test-kernel-contracts.sh
  - skills/_harness-libs/smoke-test/test-kernel-routing.sh
  - skills/_harness-libs/smoke-test/test-kernel-phase.sh
  - skills/_harness-libs/smoke-test/test-kernel-rollback.sh
- verification_scope:
  - `bash -n skills/_harness-libs/contracts.sh skills/_harness-libs/classifier.sh skills/_harness-libs/router.sh skills/_harness-libs/phase-engine.sh skills/_harness-libs/evaluation-gate.sh skills/_harness-libs/rollback.sh`
  - `bash skills/_harness-libs/smoke-test/test-kernel-contracts.sh`
  - `bash skills/_harness-libs/smoke-test/test-kernel-routing.sh`
  - `bash skills/_harness-libs/smoke-test/test-kernel-phase.sh`
  - `bash skills/_harness-libs/smoke-test/test-kernel-rollback.sh`
  - `rg -n "^name: (design-change|plan-change|execute-change|review-change|sync-truth|close-change)$" skills/design-change/SKILL.md skills/plan-change/SKILL.md skills/execute-change/SKILL.md skills/review-change/SKILL.md skills/sync-truth/SKILL.md skills/close-change/SKILL.md`
  - `rg -n "analyze-project|design-change|plan-change|execute-change|review-change|sync-truth|close-change" README.md AGENTS.md`
  - `git diff --check`
- out_of_scope:
  - full policy-registry automation
  - unattended mode
  - default parallel scheduler
  - rewrite of `skills/_review-libs` drivers or schemas
  - plugin manifest changes
- divergence_from_design: none

## File Structure

- `skills/_harness-libs/contracts.sh`
  Canonical enums and helper validators for entries, phases, change classes, verdicts, artifact classes, and failure kinds.
- `skills/_harness-libs/classifier.sh`
  Request and change classification logic that emits a jq-built classification record.
- `skills/_harness-libs/router.sh`
  Top-level intent router that maps classification output to one of the seven canonical entries.
- `skills/_harness-libs/phase-engine.sh`
  Phase transitions, approval-gate checks, and default next-phase resolution.
- `skills/_harness-libs/evaluation-gate.sh`
  Thin glue that normalizes review and verification outcomes into a single verdict contract.
- `skills/_harness-libs/rollback.sh`
  Failure-to-phase rollback selection and repeated-failure escalation logic.
- `skills/_harness-libs/smoke-test/test-kernel-contracts.sh`
  Smoke checks for enum validity and shared helper behavior.
- `skills/_harness-libs/smoke-test/test-kernel-routing.sh`
  Classification-to-entry routing smoke checks.
- `skills/_harness-libs/smoke-test/test-kernel-phase.sh`
  Phase transition and approval-gate smoke checks.
- `skills/_harness-libs/smoke-test/test-kernel-rollback.sh`
  Failure-kind-to-rollback-target smoke checks.
- `skills/design-change/SKILL.md`
  Top-level design entry for `design-lite` and `design-full`.
- `skills/plan-change/SKILL.md`
  Top-level plan entry that compiles approved design into a task DAG and dependency freeze surface.
- `skills/execute-change/SKILL.md`
  Top-level serial-first execution entry with an explicit future hook for approved parallel batches.
- `skills/review-change/SKILL.md`
  Top-level review entry that routes into the existing evaluator family.
- `skills/sync-truth/SKILL.md`
  Top-level truth-sync entry that wraps stable-truth maintenance using existing truth-plane behavior.
- `skills/close-change/SKILL.md`
  Top-level close entry for merge/release/cleanup gating.
- `README.md`
  Human-facing top-level inventory update.
- `AGENTS.md`
  AI-facing top-level inventory and authority update.

## Task 1: Add Kernel Contracts

Files:
- Create: `skills/_harness-libs/contracts.sh`
- Create: `skills/_harness-libs/smoke-test/test-kernel-contracts.sh`
- Test: `skills/_harness-libs/contracts.sh`
- Test: `skills/_harness-libs/smoke-test/test-kernel-contracts.sh`

- [ ] Step 1: Create `skills/_harness-libs/contracts.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly HARNESS_ENTRIES=(
  analyze-project
  design-change
  plan-change
  execute-change
  review-change
  sync-truth
  close-change
)

readonly HARNESS_PHASES=(
  intake
  truth-scan
  clarify
  design-lite
  design-full
  plan
  dependency-freeze
  implement-serial
  implement-parallel
  converge
  review
  verify
  truth-sync
  close
)

readonly HARNESS_CHANGE_CLASSES=(A B C D)
readonly HARNESS_DESIGN_STRENGTHS=(no-design design-lite design-full)
readonly HARNESS_VERDICTS=(pass needs-fixes needs-rollback manual-decision-required)
readonly HARNESS_ARTIFACT_CLASSES=(truth design plan implementation evaluation history)
readonly HARNESS_FAILURE_KINDS=(
  classification-failure
  truth-conflict
  requirement-ambiguity
  boundary-mismatch
  plan-incompleteness
  dependency-churn
  parallel-conflict
  convergence-failure
  review-blocking-failure
  verification-failure
  truth-sync-failure
)

contains_value() {
  local needle="$1"
  shift
  local item=""
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

is_valid_entry() { contains_value "$1" "${HARNESS_ENTRIES[@]}"; }
is_valid_phase() { contains_value "$1" "${HARNESS_PHASES[@]}"; }
is_valid_change_class() { contains_value "$1" "${HARNESS_CHANGE_CLASSES[@]}"; }
is_valid_design_strength() { contains_value "$1" "${HARNESS_DESIGN_STRENGTHS[@]}"; }
is_valid_verdict() { contains_value "$1" "${HARNESS_VERDICTS[@]}"; }
is_valid_artifact_class() { contains_value "$1" "${HARNESS_ARTIFACT_CLASSES[@]}"; }
is_valid_failure_kind() { contains_value "$1" "${HARNESS_FAILURE_KINDS[@]}"; }
```

- [ ] Step 2: Create `skills/_harness-libs/smoke-test/test-kernel-contracts.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
source "$ROOT_DIR/skills/_harness-libs/contracts.sh"

is_valid_entry analyze-project
is_valid_entry close-change
! is_valid_entry smart-commit

is_valid_phase truth-scan
is_valid_phase close
! is_valid_phase implement

is_valid_change_class A
is_valid_change_class D
! is_valid_change_class Z

is_valid_verdict pass
is_valid_verdict needs-rollback
! is_valid_verdict ok
```

- [ ] Step 3: Run syntax and smoke checks

Run: `bash -n skills/_harness-libs/contracts.sh skills/_harness-libs/smoke-test/test-kernel-contracts.sh`
Expected: PASS with no output

Run: `bash skills/_harness-libs/smoke-test/test-kernel-contracts.sh`
Expected: PASS with no output

- [ ] Step 4: Commit the contracts slice

```bash
git add skills/_harness-libs/contracts.sh skills/_harness-libs/smoke-test/test-kernel-contracts.sh
git commit -m "feat: add harness kernel contracts"
```

## Task 2: Add Change Classification And Routing

Files:
- Create: `skills/_harness-libs/classifier.sh`
- Create: `skills/_harness-libs/router.sh`
- Create: `skills/_harness-libs/smoke-test/test-kernel-routing.sh`
- Test: `skills/_harness-libs/classifier.sh`
- Test: `skills/_harness-libs/router.sh`
- Test: `skills/_harness-libs/smoke-test/test-kernel-routing.sh`

- [ ] Step 1: Create `skills/_harness-libs/classifier.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
source "$ROOT_DIR/skills/_harness-libs/contracts.sh"

classify_change() {
  local request_kind="$1"
  local truth_impact="$2"
  local boundary_impact="$3"
  local truth_repair="$4"

  local change_class="A"
  local design_strength="no-design"
  local truth_sync_required="false"
  local parallel_candidate="false"
  local recommended_next_phase="implement-serial"

  if [[ "$truth_repair" == "true" ]]; then
    change_class="D"
    truth_sync_required="true"
    recommended_next_phase="truth-sync"
  elif [[ "$boundary_impact" == "high" ]]; then
    change_class="C"
    design_strength="design-full"
    truth_sync_required="true"
    recommended_next_phase="design-full"
  elif [[ "$truth_impact" == "medium" || "$boundary_impact" == "medium" ]]; then
    change_class="B"
    design_strength="design-lite"
    truth_sync_required="true"
    parallel_candidate="conditional"
    recommended_next_phase="design-lite"
  fi

  jq -n \
    --arg request_kind "$request_kind" \
    --arg change_class "$change_class" \
    --arg design_strength "$design_strength" \
    --arg truth_impact "$truth_impact" \
    --arg boundary_impact "$boundary_impact" \
    --arg truth_sync_required "$truth_sync_required" \
    --arg parallel_candidate "$parallel_candidate" \
    --arg recommended_next_phase "$recommended_next_phase" \
    '{
      request_kind: $request_kind,
      change_class: $change_class,
      design_strength: $design_strength,
      truth_impact: $truth_impact,
      boundary_impact: $boundary_impact,
      truth_sync_required: ($truth_sync_required == "true"),
      parallel_candidate: $parallel_candidate,
      recommended_next_phase: $recommended_next_phase
    }'
}
```

- [ ] Step 2: Create `skills/_harness-libs/router.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
source "$ROOT_DIR/skills/_harness-libs/contracts.sh"

route_entry() {
  local request_kind="$1"
  case "$request_kind" in
    state-query) printf 'analyze-project\n' ;;
    change-definition) printf 'design-change\n' ;;
    change-planning) printf 'plan-change\n' ;;
    change-execution) printf 'execute-change\n' ;;
    artifact-review) printf 'review-change\n' ;;
    truth-maintenance) printf 'sync-truth\n' ;;
    integration-closeout) printf 'close-change\n' ;;
    *) return 1 ;;
  esac
}
```

- [ ] Step 3: Create `skills/_harness-libs/smoke-test/test-kernel-routing.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
source "$ROOT_DIR/skills/_harness-libs/classifier.sh"
source "$ROOT_DIR/skills/_harness-libs/router.sh"

record="$(classify_change change-definition medium low false)"
[[ "$(jq -r '.change_class' <<<"$record")" == "B" ]]
[[ "$(jq -r '.design_strength' <<<"$record")" == "design-lite" ]]

[[ "$(route_entry state-query)" == "analyze-project" ]]
[[ "$(route_entry artifact-review)" == "review-change" ]]
[[ "$(route_entry truth-maintenance)" == "sync-truth" ]]
```

- [ ] Step 4: Run syntax and smoke checks

Run: `bash -n skills/_harness-libs/classifier.sh skills/_harness-libs/router.sh skills/_harness-libs/smoke-test/test-kernel-routing.sh`
Expected: PASS with no output

Run: `bash skills/_harness-libs/smoke-test/test-kernel-routing.sh`
Expected: PASS with no output

- [ ] Step 5: Commit the classifier and router slice

```bash
git add skills/_harness-libs/classifier.sh skills/_harness-libs/router.sh skills/_harness-libs/smoke-test/test-kernel-routing.sh
git commit -m "feat: add harness change classification and routing"
```

## Task 3: Add Phase Engine, Evaluation Gate, And Rollback Resolver

Files:
- Create: `skills/_harness-libs/phase-engine.sh`
- Create: `skills/_harness-libs/evaluation-gate.sh`
- Create: `skills/_harness-libs/rollback.sh`
- Create: `skills/_harness-libs/smoke-test/test-kernel-phase.sh`
- Create: `skills/_harness-libs/smoke-test/test-kernel-rollback.sh`
- Test: `skills/_harness-libs/phase-engine.sh`
- Test: `skills/_harness-libs/evaluation-gate.sh`
- Test: `skills/_harness-libs/rollback.sh`

- [ ] Step 1: Create `skills/_harness-libs/phase-engine.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
source "$ROOT_DIR/skills/_harness-libs/contracts.sh"

next_phase_for_entry() {
  local entry="$1"
  case "$entry" in
    analyze-project) printf 'truth-scan\n' ;;
    design-change) printf 'design-lite\n' ;;
    plan-change) printf 'plan\n' ;;
    execute-change) printf 'implement-serial\n' ;;
    review-change) printf 'review\n' ;;
    sync-truth) printf 'truth-sync\n' ;;
    close-change) printf 'close\n' ;;
    *) return 1 ;;
  esac
}

phase_requires_human_approval() {
  local phase="$1"
  case "$phase" in
    clarify|design-lite|design-full|plan|dependency-freeze|truth-sync|close) return 0 ;;
    *) return 1 ;;
  esac
}
```

- [ ] Step 2: Create `skills/_harness-libs/evaluation-gate.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
source "$ROOT_DIR/skills/_harness-libs/contracts.sh"

normalize_evaluation_verdict() {
  local review_status="$1"
  local verify_status="$2"

  if [[ "$review_status" == "pass" && "$verify_status" == "pass" ]]; then
    printf 'pass\n'
    return
  fi
  if [[ "$review_status" == "needs-rollback" || "$verify_status" == "needs-rollback" ]]; then
    printf 'needs-rollback\n'
    return
  fi
  if [[ "$review_status" == "manual-decision-required" || "$verify_status" == "manual-decision-required" ]]; then
    printf 'manual-decision-required\n'
    return
  fi
  printf 'needs-fixes\n'
}
```

- [ ] Step 3: Create `skills/_harness-libs/rollback.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
source "$ROOT_DIR/skills/_harness-libs/contracts.sh"

rollback_target_for_failure() {
  local failure_kind="$1"
  case "$failure_kind" in
    requirement-ambiguity) printf 'clarify\n' ;;
    truth-conflict) printf 'truth-scan\n' ;;
    boundary-mismatch) printf 'design-full\n' ;;
    plan-incompleteness) printf 'plan\n' ;;
    dependency-churn) printf 'dependency-freeze\n' ;;
    parallel-conflict|convergence-failure) printf 'dependency-freeze\n' ;;
    review-blocking-failure|verification-failure) printf 'implement-serial\n' ;;
    truth-sync-failure) printf 'truth-sync\n' ;;
    *) return 1 ;;
  esac
}
```

- [ ] Step 4: Create `skills/_harness-libs/smoke-test/test-kernel-phase.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
source "$ROOT_DIR/skills/_harness-libs/phase-engine.sh"
source "$ROOT_DIR/skills/_harness-libs/evaluation-gate.sh"

[[ "$(next_phase_for_entry analyze-project)" == "truth-scan" ]]
[[ "$(next_phase_for_entry execute-change)" == "implement-serial" ]]
phase_requires_human_approval plan
! phase_requires_human_approval verify
[[ "$(normalize_evaluation_verdict pass pass)" == "pass" ]]
[[ "$(normalize_evaluation_verdict needs-fixes pass)" == "needs-fixes" ]]
```

- [ ] Step 5: Create `skills/_harness-libs/smoke-test/test-kernel-rollback.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
source "$ROOT_DIR/skills/_harness-libs/rollback.sh"

[[ "$(rollback_target_for_failure requirement-ambiguity)" == "clarify" ]]
[[ "$(rollback_target_for_failure boundary-mismatch)" == "design-full" ]]
[[ "$(rollback_target_for_failure verification-failure)" == "implement-serial" ]]
```

- [ ] Step 6: Run syntax and smoke checks

Run: `bash -n skills/_harness-libs/phase-engine.sh skills/_harness-libs/evaluation-gate.sh skills/_harness-libs/rollback.sh skills/_harness-libs/smoke-test/test-kernel-phase.sh skills/_harness-libs/smoke-test/test-kernel-rollback.sh`
Expected: PASS with no output

Run: `bash skills/_harness-libs/smoke-test/test-kernel-phase.sh`
Expected: PASS with no output

Run: `bash skills/_harness-libs/smoke-test/test-kernel-rollback.sh`
Expected: PASS with no output

- [ ] Step 7: Commit the phase/evaluation/rollback slice

```bash
git add \
  skills/_harness-libs/phase-engine.sh \
  skills/_harness-libs/evaluation-gate.sh \
  skills/_harness-libs/rollback.sh \
  skills/_harness-libs/smoke-test/test-kernel-phase.sh \
  skills/_harness-libs/smoke-test/test-kernel-rollback.sh
git commit -m "feat: add harness phase and rollback engine"
```

## Task 4: Add The Top-Level Entry Spine

Files:
- Create: `skills/design-change/SKILL.md`
- Create: `skills/plan-change/SKILL.md`
- Create: `skills/execute-change/SKILL.md`
- Create: `skills/review-change/SKILL.md`
- Create: `skills/sync-truth/SKILL.md`
- Create: `skills/close-change/SKILL.md`
- Modify: `README.md`
- Modify: `AGENTS.md`

- [ ] Step 1: Create `skills/design-change/SKILL.md`

```markdown
---
name: design-change
description: "Use when a change request needs boundary definition, truth-impact assessment, or explicit selection between no-design, design-lite, and design-full."
---

# Design Change

Use this as the top-level entry for change definition.

Responsibilities:

- consume truth-scan output
- determine change class and design strength
- define non-goals, affected boundaries, truth impact, and boundary impact
- stop for human approval before planning
```

- [ ] Step 2: Create `skills/plan-change/SKILL.md`

```markdown
---
name: plan-change
description: "Use when an approved change definition must be compiled into a task DAG with dependencies, write sets, verification commands, and rollback triggers."
---

# Plan Change

Use this as the top-level planning entry.

Responsibilities:

- consume approved design
- define task DAG
- define dependency-freeze surface
- define verification per task
- mark any future parallel-safe candidate batches explicitly
```

- [ ] Step 3: Create `skills/execute-change/SKILL.md`

```markdown
---
name: execute-change
description: "Use when an approved implementation plan should be executed under the sovereign harness with serial-first execution and explicit review, verification, and rollback checkpoints."
---

# Execute Change

Use this as the top-level execution entry.

Rules:

- serial-first by default
- no unattended execution in V1
- no implicit parallel batches
- review and verify gates remain mandatory
```

- [ ] Step 4: Create `skills/review-change/SKILL.md`

```markdown
---
name: review-change
description: "Use when a design, plan, code implementation, or truth-sync artifact needs a single top-level review entry that routes into the evaluator family."
---

# Review Change

Use this as the top-level review entry.

Route targets:

- design -> `review-design`
- plan -> `review-plan`
- code implementation -> `review-code-impl`
```

- [ ] Step 5: Create `skills/sync-truth/SKILL.md`

```markdown
---
name: sync-truth
description: "Use when a verified change has truth impact and stable truth must be updated without letting stage artifacts become default current truth."
---

# Sync Truth

Use this as the top-level truth maintenance entry.

This entry wraps stable-truth updates and preserves the truth/history boundary.
```

- [ ] Step 6: Create `skills/close-change/SKILL.md`

```markdown
---
name: close-change
description: "Use when a reviewed and verified change should merge, release, or clean up under a single close gate owned by the sovereign harness."
---

# Close Change

Use this as the top-level close entry.

Close requires:

- review pass
- verify pass
- truth-sync completed when required
- explicit human approval
```

- [ ] Step 7: Update `README.md` and `AGENTS.md`

Add the new top-level harness inventory and position:

```markdown
- `analyze-project`: top-level truth-scan and state-query entry.
- `design-change`: top-level change-definition entry.
- `plan-change`: top-level planning entry.
- `execute-change`: top-level execution entry.
- `review-change`: top-level review entry.
- `sync-truth`: top-level truth maintenance entry.
- `close-change`: top-level close entry.
```

Also update AI-facing notes so guideline and review skills are clearly lower-plane components inside the harness.

- [ ] Step 8: Validate the entry spine

Run: `rg -n "^name: (design-change|plan-change|execute-change|review-change|sync-truth|close-change)$" skills/design-change/SKILL.md skills/plan-change/SKILL.md skills/execute-change/SKILL.md skills/review-change/SKILL.md skills/sync-truth/SKILL.md skills/close-change/SKILL.md`
Expected: PASS with one hit per new top-level entry

Run: `rg -n "analyze-project|design-change|plan-change|execute-change|review-change|sync-truth|close-change" README.md AGENTS.md`
Expected: PASS with the new top-level entry inventory visible to both humans and agents

- [ ] Step 9: Commit the entry spine slice

```bash
git add \
  skills/design-change/SKILL.md \
  skills/plan-change/SKILL.md \
  skills/execute-change/SKILL.md \
  skills/review-change/SKILL.md \
  skills/sync-truth/SKILL.md \
  skills/close-change/SKILL.md \
  README.md \
  AGENTS.md
git commit -m "feat: add sovereign harness top-level entries"
```

## Task 5: Run Final Validation And Prepare For Execution

Files:
- Test: `skills/_harness-libs/contracts.sh`
- Test: `skills/_harness-libs/classifier.sh`
- Test: `skills/_harness-libs/router.sh`
- Test: `skills/_harness-libs/phase-engine.sh`
- Test: `skills/_harness-libs/evaluation-gate.sh`
- Test: `skills/_harness-libs/rollback.sh`
- Test: `skills/_harness-libs/smoke-test/test-kernel-contracts.sh`
- Test: `skills/_harness-libs/smoke-test/test-kernel-routing.sh`
- Test: `skills/_harness-libs/smoke-test/test-kernel-phase.sh`
- Test: `skills/_harness-libs/smoke-test/test-kernel-rollback.sh`
- Test: `README.md`
- Test: `AGENTS.md`

- [ ] Step 1: Run full syntax checks

Run: `bash -n skills/_harness-libs/contracts.sh skills/_harness-libs/classifier.sh skills/_harness-libs/router.sh skills/_harness-libs/phase-engine.sh skills/_harness-libs/evaluation-gate.sh skills/_harness-libs/rollback.sh skills/_harness-libs/smoke-test/test-kernel-contracts.sh skills/_harness-libs/smoke-test/test-kernel-routing.sh skills/_harness-libs/smoke-test/test-kernel-phase.sh skills/_harness-libs/smoke-test/test-kernel-rollback.sh`
Expected: PASS with no output

- [ ] Step 2: Run the smoke tests

Run: `bash skills/_harness-libs/smoke-test/test-kernel-contracts.sh`
Expected: PASS with no output

Run: `bash skills/_harness-libs/smoke-test/test-kernel-routing.sh`
Expected: PASS with no output

Run: `bash skills/_harness-libs/smoke-test/test-kernel-phase.sh`
Expected: PASS with no output

Run: `bash skills/_harness-libs/smoke-test/test-kernel-rollback.sh`
Expected: PASS with no output

- [ ] Step 3: Validate top-level inventory and diff health

Run: `rg -n "analyze-project|design-change|plan-change|execute-change|review-change|sync-truth|close-change" README.md AGENTS.md`
Expected: PASS with all seven entries listed

Run: `git diff --check`
Expected: PASS with no output

- [ ] Step 4: Commit the final validation state

```bash
git add \
  skills/_harness-libs/contracts.sh \
  skills/_harness-libs/classifier.sh \
  skills/_harness-libs/router.sh \
  skills/_harness-libs/phase-engine.sh \
  skills/_harness-libs/evaluation-gate.sh \
  skills/_harness-libs/rollback.sh \
  skills/_harness-libs/smoke-test/test-kernel-contracts.sh \
  skills/_harness-libs/smoke-test/test-kernel-routing.sh \
  skills/_harness-libs/smoke-test/test-kernel-phase.sh \
  skills/_harness-libs/smoke-test/test-kernel-rollback.sh \
  skills/design-change/SKILL.md \
  skills/plan-change/SKILL.md \
  skills/execute-change/SKILL.md \
  skills/review-change/SKILL.md \
  skills/sync-truth/SKILL.md \
  skills/close-change/SKILL.md \
  README.md \
  AGENTS.md
git commit -m "feat: add sovereign harness kernel v1"
```

## Self-Review

Spec coverage:

- single sovereign top-level harness authority: covered by Tasks 1 through 4
- seven canonical top-level entries: covered by Task 4
- explicit request classification: covered by Task 2
- explicit phase model and approval gates: covered by Task 3
- unified review/verify gate: covered by Task 3
- rollback depth selection: covered by Task 3
- truth plane preserved and wrapped rather than replaced: covered by Task 4
- serial-first execution spine: covered by Task 4

Placeholder scan:

- no task says "TBD" or "implement later"
- all created files are named
- each task lists exact validation commands

Type consistency:

- entries in contracts, router, and inventory all use the same canonical names
- failure kinds in contracts and rollback resolver use the same hyphen-style identifiers
