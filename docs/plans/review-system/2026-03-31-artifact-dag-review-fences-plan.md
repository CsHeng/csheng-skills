# Artifact DAG Review Fences Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement artifact-DAG-enforced review and repair fences so plan review requires upstream design linkage and code-implementation repair stays inside design/plan-approved scope.

**Architecture:** Add a new shell helper module that parses design and plan markdown contracts, resolves upstream design metadata, and computes allowed touch sets before reviewer invocation. Thread that metadata through workspace preparation, prompt construction, output classification, and wrapper/manual-gate logic, then update docs and smoke fixtures so the new contract is testable without relying on live reviewer output.

**Tech Stack:** Bash, jq, markdown-based design/plan documents, existing shared review runner, shell smoke tests

---

## File Structure

- `skills/_review-libs/artifact-dag.sh` New helper module for parsing `design_ref`, `design_version`, `impl_file_refs`, `test_file_refs`, `verification_scope`, and set operations such as subset/intersection/difference.
- `skills/_review-libs/run-review.sh` Extend orchestration state with resolved upstream design, allowed touch metadata, and manual-gate decisions derived from finding scope classes.
- `skills/_review-libs/workspace.sh` Load the upstream design from the plan, copy it into the isolated workspace, compute `allowed_touch_set`, and reject or flag out-of-scope code touches.
- `skills/_review-libs/prompt-builder.sh` Reorder plan/code review prompts to evaluate `design -> plan -> code`, and require `scope_class` on every finding.
- `skills/_review-libs/output-validator.sh` Validate `scope_class`, attach richer scope metadata to run output, and reconcile `manual_review_required` when blocking findings are outside repairable scope.
- `skills/_review-libs/schemas/adversarial-reviewer-output.schema.json` Add `scope_class` to each finding.
- `skills/_review-libs/schemas/review-run-output.schema.json` Add scope metadata fields such as `design_path`, `design_version`, `allowed_touch_set`, and `out_of_scope_touched_files`.
- `skills/_review-libs/smoke-test/fixtures/sample-design.md` Replace the generic design fixture with a repo-relevant design that includes `Implementation Surface`.
- `skills/_review-libs/smoke-test/fixtures/sample-plan.md` New fixture plan that references the sample design and narrows the implementation slice.
- `skills/_review-libs/smoke-test/test-artifact-dag.sh` New deterministic shell test for markdown parsing, subset enforcement, and schema shape checks.
- `skills/_review-libs/smoke-test/smoke-cross-model-review.sh` Point plan smoke tests at the new sample plan and keep code-impl smoke constrained to the reviewed files.
- `commands/review-plan.md`
  Document the new prevalidation contract: `design_ref` required, design must expose `impl_file_refs`, and plan refs must stay inside the design ceiling.
- `commands/review-code-impl.md` Document design-first evaluation order, allowed-touch filtering, and manual stop when findings are outside the current DAG slice.
- `skills/review-plan/SKILL.md` Update plan-review expectations to require upstream design linkage and constrained implementation refs.
- `skills/review-code-impl/SKILL.md` Update code review concerns and repair loop policy around `allowed_touch_set` and non-repairable finding classes.
- `skills/review-design/SKILL.md`
  Document the new design-side contract: implementation-surface refs are required.
- `skills/review-plan/references/workflow-details.md` Align plan workflow with design loading and prevalidation.
- `skills/review-code-impl/references/workflow-details.md` Align code-review workflow with design-first evaluation and repair fences.
- `skills/review-design/references/workflow-details.md` Require design docs to declare implementation surface refs.
- `skills/review-*/references/evidence-contracts.md` Mention `scope_class` and the new blocking/manual-gate interpretation.
- `skills/review-*/references/good-finding-example.md` Add `scope_class` to the JSON example so prompts and schema agree.
- `skills/review-*/references/bad-finding-example.md` Show omission or misuse of `scope_class` as an anti-pattern.

### Task 1: Add Fixture-Backed Artifact DAG Parsing

**Files:**
- Create: `skills/_review-libs/artifact-dag.sh`
- Create: `skills/_review-libs/smoke-test/fixtures/sample-plan.md`
- Create: `skills/_review-libs/smoke-test/test-artifact-dag.sh`
- Modify: `skills/_review-libs/smoke-test/fixtures/sample-design.md`
- Test: `skills/_review-libs/smoke-test/test-artifact-dag.sh`

- [ ] **Step 1: Write a failing shell test for design/plan parsing**

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
source "$ROOT_DIR/skills/_review-libs/artifact-dag.sh"

assert_eq() {
  local expected="$1" actual="$2" message="$3"
  if [[ "$expected" != "$actual" ]]; then
    printf 'ASSERT_EQ failed: %s\nexpected: %s\nactual:   %s\n' "$message" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_contains() {
  local needle="$1"
  shift
  local item=""
  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done
  printf 'ASSERT_CONTAINS failed: %s\n' "$needle" >&2
  exit 1
}

PLAN="$ROOT_DIR/skills/_review-libs/smoke-test/fixtures/sample-plan.md"
DESIGN="$ROOT_DIR/skills/_review-libs/smoke-test/fixtures/sample-design.md"

read -r resolved_design resolved_version < <(resolve_plan_design_ref "$ROOT_DIR" "$PLAN")
assert_eq "$DESIGN" "$resolved_design" "plan design_ref resolves to the sample design"
assert_eq "f203ff0" "$resolved_version" "plan design_version is pinned"

mapfile -t design_impl_refs < <(extract_markdown_list "$DESIGN" "Implementation Surface" "impl_file_refs")
mapfile -t plan_impl_refs < <(extract_markdown_list "$PLAN" "Implementation Scope" "impl_file_refs")
mapfile -t plan_test_refs < <(extract_markdown_list "$PLAN" "Implementation Scope" "test_file_refs")
mapfile -t allowed_touch_set < <(build_allowed_touch_set "$PLAN" "$DESIGN")

assert_contains "skills/_review-libs/run-review.sh" "${design_impl_refs[@]}"
assert_contains "skills/_review-libs/workspace.sh" "${plan_impl_refs[@]}"
assert_contains "skills/_review-libs/smoke-test/test-artifact-dag.sh" "${plan_test_refs[@]}"
assert_contains "skills/_review-libs/workspace.sh" "${allowed_touch_set[@]}"
assert_contains "skills/_review-libs/smoke-test/test-artifact-dag.sh" "${allowed_touch_set[@]}"

assert_plan_refs_within_design "$PLAN" "$DESIGN"
```

- [ ] **Step 2: Run the test and verify it fails because the helper and fixture plan do not exist yet**

Run: `bash skills/_review-libs/smoke-test/test-artifact-dag.sh`  
Expected: FAIL with `artifact-dag.sh: no such file or directory` or `resolve_plan_design_ref: command not found`

- [ ] **Step 3: Replace the generic design fixture and add a plan fixture that points at it**

```md
# Review Runner Artifact DAG Design

## Goals

- Make implementation-plan review require a pinned upstream design
- Make code-implementation review evaluate design, then plan, then code
- Prevent repair-review from touching files outside the current plan slice

## Non-Goals

- Building a central artifact registry
- Auto-rewriting design or plan mainline intent during repair loops
- Pulling unrelated historical defects into the active repair batch

## Implementation Surface

- impl_file_refs:
  - skills/_review-libs/run-review.sh
  - skills/_review-libs/workspace.sh
  - skills/_review-libs/prompt-builder.sh
  - skills/_review-libs/output-validator.sh
- test_file_refs:
  - skills/_review-libs/smoke-test/test-artifact-dag.sh
  - skills/_review-libs/smoke-test/smoke-cross-model-review.sh
- out_of_scope_file_refs:
  - commands/smart-commit.md
  - skills/gh-address-comments/
```
```md
# Review Runner Artifact DAG Plan

## Upstream Design

- design_ref: skills/_review-libs/smoke-test/fixtures/sample-design.md
- design_version: f203ff0

## Implementation Scope

- scope_slice: enforce design linkage and allowed-touch filtering for plan and code-implementation review
- impl_file_refs:
  - skills/_review-libs/run-review.sh
  - skills/_review-libs/workspace.sh
  - skills/_review-libs/prompt-builder.sh
- test_file_refs:
  - skills/_review-libs/smoke-test/test-artifact-dag.sh
  - skills/_review-libs/smoke-test/smoke-cross-model-review.sh
- verification_scope:
  - bash skills/_review-libs/smoke-test/test-artifact-dag.sh
  - bash skills/_review-libs/smoke-test/smoke-cross-model-review.sh plan --reviewer codex --timeout 1800 --plan skills/_review-libs/smoke-test/fixtures/sample-plan.md
- out_of_scope:
  - command wrapper changes outside review-plan and review-code-impl
  - unrelated historical review findings
- divergence_from_design: none
```

- [ ] **Step 4: Implement the markdown parsing helper and set operations**

```bash
#!/usr/bin/env bash

extract_markdown_list() {
  local file="$1" section="$2" key="$3"
  awk -v section="$section" -v key="$key" '
    $0 == "## " section { in_section=1; next }
    /^## / && in_section { exit }
    in_section && $1 == "-" && $2 == key ":" { in_key=1; next }
    in_section && in_key && $1 == "-" {
      sub(/^[[:space:]]*-[[:space:]]*/, "", $0)
      print $0
      next
    }
    in_section && in_key && $1 != "-" && NF > 0 { in_key=0 }
  ' "$file"
}

extract_markdown_scalar() {
  local file="$1" section="$2" key="$3"
  awk -v section="$section" -v key="$key" '
    $0 == "## " section { in_section=1; next }
    /^## / && in_section { exit }
    in_section && $1 == "-" && $2 == key ":" {
      sub(/^[[:space:]]*-[[:space:]]*[^:]+:[[:space:]]*/, "", $0)
      print $0
      exit
    }
  ' "$file"
}

resolve_plan_design_ref() {
  local repo_root="$1" plan_file="$2"
  local design_ref design_version resolved_design
  design_ref="$(extract_markdown_scalar "$plan_file" "Upstream Design" "design_ref")"
  design_version="$(extract_markdown_scalar "$plan_file" "Upstream Design" "design_version")"
  [[ -n "$design_ref" ]] || return 1
  [[ -n "$design_version" ]] || return 1
  resolved_design="$(realpath "$repo_root/$design_ref" 2>/dev/null || realpath "$design_ref" 2>/dev/null)" || return 1
  printf '%s %s\n' "$resolved_design" "$design_version"
}

build_allowed_touch_set() {
  local plan_file="$1"
  local design_file="$2"
  {
    extract_markdown_list "$plan_file" "Implementation Scope" "impl_file_refs"
    extract_markdown_list "$plan_file" "Implementation Scope" "test_file_refs"
  } | awk 'NF { seen[$0]=1 } END { for (path in seen) print path }' | sort
}

assert_plan_refs_within_design() {
  local plan_file="$1" design_file="$2"
  local missing=0 path=""
  local design_refs
  design_refs="$(extract_markdown_list "$design_file" "Implementation Surface" "impl_file_refs")"
  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    if ! grep -Fxq "$path" <<< "$design_refs"; then
      printf 'plan ref outside design ceiling: %s\n' "$path" >&2
      missing=1
    fi
  done < <(extract_markdown_list "$plan_file" "Implementation Scope" "impl_file_refs")
  [[ "$missing" -eq 0 ]]
}
```

- [ ] **Step 5: Re-run the test and verify the parser, fixture, and set logic pass**

Run: `bash skills/_review-libs/smoke-test/test-artifact-dag.sh`  
Expected: PASS with no output

- [ ] **Step 6: Commit the helper and fixture baseline**

```bash
git add \
  skills/_review-libs/artifact-dag.sh \
  skills/_review-libs/smoke-test/fixtures/sample-design.md \
  skills/_review-libs/smoke-test/fixtures/sample-plan.md \
  skills/_review-libs/smoke-test/test-artifact-dag.sh
git commit -m "test: add artifact DAG parsing fixtures"
```

### Task 2: Extend Schemas And Validator With Scope Metadata

**Files:**
- Modify: `skills/_review-libs/schemas/adversarial-reviewer-output.schema.json`
- Modify: `skills/_review-libs/schemas/review-run-output.schema.json`
- Modify: `skills/_review-libs/output-validator.sh`
- Modify: `skills/_review-libs/smoke-test/test-artifact-dag.sh`
- Test: `skills/_review-libs/smoke-test/test-artifact-dag.sh`

- [ ] **Step 1: Add failing schema assertions for `scope_class` and new scope metadata**

```bash
reviewer_schema="$ROOT_DIR/skills/_review-libs/schemas/adversarial-reviewer-output.schema.json"
run_schema="$ROOT_DIR/skills/_review-libs/schemas/review-run-output.schema.json"

jq -e '.["$defs"].finding.required | index("scope_class")' "$reviewer_schema" >/dev/null
jq -e '.["$defs"].finding.properties.scope_class.enum | index("in_scope_blocking")' "$reviewer_schema" >/dev/null
jq -e '.properties.scope.properties.design_path.type == "string"' "$run_schema" >/dev/null
jq -e '.properties.scope.properties.design_version.type == "string"' "$run_schema" >/dev/null
jq -e '.properties.scope.properties.allowed_touch_set.type == "array"' "$run_schema" >/dev/null
jq -e '.properties.scope.properties.out_of_scope_touched_files.type == "array"' "$run_schema" >/dev/null
```

- [ ] **Step 2: Run the test and verify the new assertions fail against the current schemas**

Run: `bash skills/_review-libs/smoke-test/test-artifact-dag.sh`  
Expected: FAIL with a `jq` assertion failure because `scope_class` and the new scope fields are absent

- [ ] **Step 3: Add `scope_class` to the reviewer schema and new scope metadata to the run schema**

```json
"required": [
  "severity",
  "scope_class",
  "location",
  "evidence",
  "impact",
  "fix",
  "confidence"
],
"scope_class": {
  "type": "string",
  "enum": [
    "baseline_mismatch",
    "in_scope_blocking",
    "adjacent_debt",
    "out_of_dag_issue",
    "external_verification_failure"
  ]
}
```
```json
"required": [
  "mode",
  "workspace_root",
  "workspace_mode",
  "spec_baseline",
  "plan_path",
  "design_path",
  "design_version",
  "allowed_touch_set",
  "out_of_scope_touched_files",
  "files"
],
"design_path": { "type": "string" },
"design_version": { "type": "string" },
"allowed_touch_set": {
  "type": "array",
  "items": { "type": "string", "minLength": 1 }
},
"out_of_scope_touched_files": {
  "type": "array",
  "items": { "type": "string", "minLength": 1 }
}
```

- [ ] **Step 4: Update validator and scope-json builders to require the new fields**

```bash
and (.scope_class == "baseline_mismatch"
  or .scope_class == "in_scope_blocking"
  or .scope_class == "adjacent_debt"
  or .scope_class == "out_of_dag_issue"
  or .scope_class == "external_verification_failure")
```
```bash
jq -n \
  --arg mode "$MODE" \
  --arg workspace_root "$WORKSPACE_ROOT" \
  --arg spec_baseline "$SPEC_BASELINE" \
  --arg plan_path "${WORKSPACE_PLAN_PATH:-}" \
  --arg design_path "${WORKSPACE_DESIGN_PATH:-}" \
  --arg design_version "${DESIGN_VERSION:-}" \
  --argjson allowed_touch_set "$allowed_touch_set_json" \
  --argjson out_of_scope_touched_files "$out_of_scope_json" \
  --argjson files "$file_list_json" '
    {
      mode: $mode,
      workspace_root: $workspace_root,
      workspace_mode: "isolated",
      spec_baseline: $spec_baseline,
      plan_path: $plan_path,
      design_path: $design_path,
      design_version: $design_version,
      allowed_touch_set: $allowed_touch_set,
      out_of_scope_touched_files: $out_of_scope_touched_files,
      files: $files
    }
  ' > "$scope_file"
```

- [ ] **Step 5: Re-run the artifact-DAG test and validate both schemas directly**

Run: `bash skills/_review-libs/smoke-test/test-artifact-dag.sh`  
Expected: PASS with no output

Run: `jq . skills/_review-libs/schemas/adversarial-reviewer-output.schema.json >/dev/null`  
Expected: PASS

Run: `jq . skills/_review-libs/schemas/review-run-output.schema.json >/dev/null`  
Expected: PASS

- [ ] **Step 6: Commit the schema and validator changes**

```bash
git add \
  skills/_review-libs/schemas/adversarial-reviewer-output.schema.json \
  skills/_review-libs/schemas/review-run-output.schema.json \
  skills/_review-libs/output-validator.sh \
  skills/_review-libs/smoke-test/test-artifact-dag.sh
git commit -m "feat: classify review findings by scope"
```

### Task 3: Enforce Design Linkage And Allowed-Touch Filtering In The Runner

**Files:**
- Modify: `skills/_review-libs/run-review.sh`
- Modify: `skills/_review-libs/workspace.sh`
- Modify: `skills/_review-libs/artifact-dag.sh`
- Modify: `skills/_review-libs/smoke-test/test-artifact-dag.sh`
- Test: `skills/_review-libs/smoke-test/test-artifact-dag.sh`

- [ ] **Step 1: Add a failing test for scope filtering and out-of-scope detection**

```bash
candidate_paths=(
  "skills/_review-libs/run-review.sh"
  "skills/_review-libs/workspace.sh"
  "commands/review-plan.md"
)
mapfile -t allowed_touch_set < <(build_allowed_touch_set "$PLAN" "$DESIGN")

mapfile -t filtered_scope < <(intersect_paths_from_array candidate_paths allowed_touch_set)

mapfile -t out_of_scope < <(subtract_paths_from_array candidate_paths allowed_touch_set)

assert_eq "2" "${#filtered_scope[@]}" "only in-scope files remain after filtering"
assert_eq "1" "${#out_of_scope[@]}" "one touched file remains out of scope"
assert_contains "commands/review-plan.md" "${out_of_scope[@]}"
```

- [ ] **Step 2: Run the test and verify it fails because filtering helpers do not exist yet**

Run: `bash skills/_review-libs/smoke-test/test-artifact-dag.sh`  
Expected: FAIL with `intersect_paths_from_array: command not found`

- [ ] **Step 3: Extend the helper with path filtering and plan/design loading helpers**

```bash
intersect_paths_from_array() {
  local -n candidates_ref="$1"
  local -n allowed_ref="$2"
  local path="" allowed_path=""
  for path in "${candidates_ref[@]}"; do
    for allowed_path in "${allowed_ref[@]}"; do
      if [[ "$path" == "$allowed_path" ]]; then
        printf '%s\n' "$path"
        break
      fi
    done
  done
}

subtract_paths_from_array() {
  local -n candidates_ref="$1"
  local -n allowed_ref="$2"
  local path="" allowed_path="" matched=0
  for path in "${candidates_ref[@]}"; do
    matched=0
    for allowed_path in "${allowed_ref[@]}"; do
      if [[ "$path" == "$allowed_path" ]]; then
        matched=1
        break
      fi
    done
    if [[ "$matched" -eq 0 ]]; then
      printf '%s\n' "$path"
    fi
  done
}
```

- [ ] **Step 4: Load the upstream design in `run-review.sh` and enforce allowed-touch filtering in `workspace.sh`**

```bash
source "$SCRIPT_DIR/artifact-dag.sh"

RESOLVED_DESIGN=""
WORKSPACE_DESIGN_PATH=""
DESIGN_VERSION=""
ALLOWED_TOUCH_SET=()
OUT_OF_SCOPE_TOUCHED_FILES=()
```
```bash
if [[ -n "$PLAN_PATH" && ( "$MODE" == "plan" || "$MODE" == "code-impl" ) ]]; then
  read -r RESOLVED_DESIGN DESIGN_VERSION < <(resolve_plan_design_ref "$REPO_ROOT" "$RESOLVED_PLAN")
  assert_plan_refs_within_design "$RESOLVED_PLAN" "$RESOLVED_DESIGN" || \
    die $EXIT_INPUT_NOT_FOUND "plan impl_file_refs exceed design impl_file_refs"
  mapfile -t ALLOWED_TOUCH_SET < <(build_allowed_touch_set "$RESOLVED_PLAN" "$RESOLVED_DESIGN")
fi
```
```bash
if [[ "$MODE" == "code-impl" ]]; then
  collect_code_impl_scope
  mapfile -t OUT_OF_SCOPE_TOUCHED_FILES < <(subtract_paths_from_array CODE_IMPL_SCOPE ALLOWED_TOUCH_SET)
  mapfile -t CODE_IMPL_SCOPE < <(intersect_paths_from_array CODE_IMPL_SCOPE ALLOWED_TOUCH_SET)
  [[ "${#CODE_IMPL_SCOPE[@]}" -gt 0 ]] || die $EXIT_EMPTY_SCOPE "no code implementation files remain after allowed-touch filtering"
fi

if [[ -n "$RESOLVED_DESIGN" ]]; then
  local design_rel
  design_rel="$(realpath --relative-to="$REPO_ROOT" "$RESOLVED_DESIGN" 2>/dev/null || printf 'external-design/%s' "$(basename -- "$RESOLVED_DESIGN")")"
  copy_file_into_workspace "$RESOLVED_DESIGN" "$design_rel"
  WORKSPACE_DESIGN_PATH="$design_rel"
fi
```

- [ ] **Step 5: Re-run the test and verify helper parsing plus scope filtering now pass**

Run: `bash skills/_review-libs/smoke-test/test-artifact-dag.sh`  
Expected: PASS with no output

- [ ] **Step 6: Commit the runner/workspace enforcement changes**

```bash
git add \
  skills/_review-libs/artifact-dag.sh \
  skills/_review-libs/run-review.sh \
  skills/_review-libs/workspace.sh \
  skills/_review-libs/smoke-test/test-artifact-dag.sh
git commit -m "feat: enforce design-linked review scope"
```

### Task 4: Update Prompts And Repair Gating

**Files:**
- Modify: `skills/_review-libs/prompt-builder.sh`
- Modify: `skills/_review-libs/output-validator.sh`
- Create: `skills/_review-libs/smoke-test/test-review-gating.sh`
- Modify: `skills/review-plan/references/good-finding-example.md`
- Modify: `skills/review-plan/references/bad-finding-example.md`
- Modify: `skills/review-code-impl/references/good-finding-example.md`
- Modify: `skills/review-code-impl/references/bad-finding-example.md`
- Modify: `skills/review-design/references/good-finding-example.md`
- Modify: `skills/review-design/references/bad-finding-example.md`
- Test: `skills/_review-libs/smoke-test/test-review-gating.sh`

- [ ] **Step 1: Write a failing gating test that expects non-`in_scope_blocking` findings to force manual review**

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SCRIPT_DIR="$ROOT_DIR/skills/_review-libs"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

source "$SCRIPT_DIR/output-validator.sh"

EXIT_SCHEMA_VALIDATION_FAILED=12
MODE="code-impl"
HOST="claude"
WORKSPACE_ROOT="$ROOT_DIR"
WORKSPACE_PLAN_PATH="skills/_review-libs/smoke-test/fixtures/sample-plan.md"
WORKSPACE_DESIGN_PATH="skills/_review-libs/smoke-test/fixtures/sample-design.md"
DESIGN_VERSION="f203ff0"
RUN_SCHEMA_PATH="$SCRIPT_DIR/schemas/review-run-output.schema.json"
BATCH_NUMBER=1
ROUND_NUMBER=1
MAX_ROUNDS=3
ALLOWED_TOUCH_SET=("skills/_review-libs/run-review.sh" "skills/_review-libs/workspace.sh")
OUT_OF_SCOPE_TOUCHED_FILES=("commands/review-plan.md")
CODE_IMPL_SCOPE=("skills/_review-libs/run-review.sh")

cat > "$TMP_DIR/reviewer.json" <<'JSON'
{
  "lens": "spec compliance, testing and operations",
  "verdict": "FAIL",
  "summary": "Plan drift requires manual intervention.",
  "findings": [
    {
      "severity": "Important",
      "scope_class": "baseline_mismatch",
      "location": "skills/_review-libs/smoke-test/fixtures/sample-plan.md:3",
      "evidence": "The plan references files outside the design ceiling.",
      "impact": "Auto-repair would legalize scope drift.",
      "fix": "Update the plan or design before retrying implementation repair.",
      "confidence": "high"
    }
  ],
  "pass_rationale": ""
}
JSON

build_scope_json "$TMP_DIR/scope.json"
build_run_output "$TMP_DIR/reviewer.json" "$TMP_DIR/scope.json" "$TMP_DIR/run.json" "cross-driver" "codex" "gpt-5.4"

jq -e '.status == "manual_review_required"' "$TMP_DIR/run.json" >/dev/null
jq -e '.next_action == "human_decision_required"' "$TMP_DIR/run.json" >/dev/null
```

- [ ] **Step 2: Run the test and verify it fails because the current reconciler still treats all blocking findings as repairable**

Run: `bash skills/_review-libs/smoke-test/test-review-gating.sh`  
Expected: FAIL because `.status` is still `needs_fixes`

- [ ] **Step 3: Update plan and code prompts to load the design first and require `scope_class`**

```bash
Only inspect the plan file, the upstream design file, and any root context files in this isolated workspace.
Review the design first, then the plan.
If the plan's impl_file_refs exceed the design's impl_file_refs, report a Critical `baseline_mismatch`.
```
```bash
Use the upstream design as the first-order constraint.
Review in this order:
1. design boundaries and non-goals
2. plan commitments and allowed touch set
3. code correctness, tests, and production readiness
If a blocking issue is outside the current plan slice, classify it as `adjacent_debt` or `out_of_dag_issue`, not `in_scope_blocking`.
```
```json
{
  "severity": "Critical" | "Important" | "Minor",
  "scope_class": "baseline_mismatch" | "in_scope_blocking" | "adjacent_debt" | "out_of_dag_issue" | "external_verification_failure",
  "location": string,
  "evidence": string,
  "impact": string,
  "fix": string,
  "confidence": "high" | "medium" | "low"
}
```

- [ ] **Step 4: Reconcile run output so only `in_scope_blocking` remains auto-repairable**

```bash
repairable_findings_json="$(jq '[.findings[] | select((.severity == "Critical" or .severity == "Important") and .scope_class == "in_scope_blocking")]' "$reviewer_json")"
blocking_findings_json="$(jq '[.findings[] | select(.severity == "Critical" or .severity == "Important")]' "$reviewer_json")"
manual_only_count="$(jq '[.findings[] | select((.severity == "Critical" or .severity == "Important") and .scope_class != "in_scope_blocking")] | length' "$reviewer_json")"

if [[ "$manual_only_count" -gt 0 ]]; then
  status="manual_review_required"
  next_action="human_decision_required"
  manual_required="true"
  suggested_next_round=1
  suggested_next_batch=$((BATCH_NUMBER + 1))
fi
```

- [ ] **Step 5: Re-run the gating test and update the finding examples**

Run: `bash skills/_review-libs/smoke-test/test-review-gating.sh`  
Expected: PASS with no output

Run: `rg -n "scope_class" skills/review-*/references/good-finding-example.md skills/review-*/references/bad-finding-example.md`  
Expected: PASS with at least one `scope_class` hit in each file

- [ ] **Step 6: Commit prompt and repair-gating changes**

```bash
git add \
  skills/_review-libs/prompt-builder.sh \
  skills/_review-libs/output-validator.sh \
  skills/_review-libs/smoke-test/test-review-gating.sh \
  skills/review-plan/references/good-finding-example.md \
  skills/review-plan/references/bad-finding-example.md \
  skills/review-code-impl/references/good-finding-example.md \
  skills/review-code-impl/references/bad-finding-example.md \
  skills/review-design/references/good-finding-example.md \
  skills/review-design/references/bad-finding-example.md
git commit -m "feat: gate repair-review by artifact scope"
```

### Task 5: Refresh Commands, Skills, And Smoke Validation

**Files:**
- Modify: `commands/review-plan.md`
- Modify: `commands/review-code-impl.md`
- Modify: `commands/review-design.md`
- Modify: `skills/review-plan/SKILL.md`
- Modify: `skills/review-code-impl/SKILL.md`
- Modify: `skills/review-design/SKILL.md`
- Modify: `skills/review-plan/references/workflow-details.md`
- Modify: `skills/review-code-impl/references/workflow-details.md`
- Modify: `skills/review-design/references/workflow-details.md`
- Modify: `skills/review-plan/references/evidence-contracts.md`
- Modify: `skills/review-code-impl/references/evidence-contracts.md`
- Modify: `skills/review-design/references/evidence-contracts.md`
- Modify: `skills/_review-libs/smoke-test/smoke-cross-model-review.sh`
- Test: `bash skills/_review-libs/smoke-test/test-artifact-dag.sh`
- Test: `bash skills/_review-libs/smoke-test/test-review-gating.sh`
- Test: `bash -n ...`
- Test: `jq . ...`

- [ ] **Step 1: Add failing grep checks for the new contract language**

```bash
rg -n "design_ref is required|allowed_touch_set|design -> plan -> code" \
  commands/review-plan.md \
  commands/review-code-impl.md \
  skills/review-plan/SKILL.md \
  skills/review-code-impl/SKILL.md \
  skills/review-design/SKILL.md >/dev/null
```

- [ ] **Step 2: Run the grep check and verify it fails because the docs still describe the old contract**

Run: `rg -n "design_ref is required|allowed_touch_set|design -> plan -> code" commands/review-plan.md commands/review-code-impl.md skills/review-plan/SKILL.md skills/review-code-impl/SKILL.md skills/review-design/SKILL.md >/dev/null`  
Expected: FAIL with exit code `1`

- [ ] **Step 3: Update command wrappers and skill docs to match the artifact-DAG contract**

```md
- `--plan <path>`: implementation plan file to review. Required.
- The plan must declare `design_ref` and `design_version`.
- Before invoking the reviewer, load the upstream design and require the design to expose `impl_file_refs`.
- If the plan's impl refs exceed the design ceiling, stop before reviewer invocation.
```
```md
- Review context must load `design + plan + scoped code`.
- Evaluate in this order: design boundaries, plan commitments, code correctness.
- `repair-review` may only fix `in_scope_blocking` findings inside `allowed_touch_set`.
- Any blocking finding outside the current plan slice must return `manual_review_required`.
```
```md
- Design documents under review must include an `Implementation Surface` section with `impl_file_refs`, `test_file_refs`, and optional `out_of_scope_file_refs`.
```

- [ ] **Step 4: Update workflow references, evidence contracts, and smoke harness defaults**

```md
6. If the plan includes `design_ref`, resolve the upstream design before reviewer invocation.
7. Fail fast if `design_ref` is missing, the design omits `impl_file_refs`, or the plan exceeds the design ceiling.
8. For code-implementation review, compute `allowed_touch_set = plan.impl_file_refs + plan.test_file_refs` and restrict repair to that set.
```
```md
Every Critical or Important finding must include:
- `scope_class`: one of `baseline_mismatch`, `in_scope_blocking`, `adjacent_debt`, `out_of_dag_issue`, `external_verification_failure`
```
```bash
PLAN_PATH="skills/_review-libs/smoke-test/fixtures/sample-plan.md"
DESIGN_PATH="skills/_review-libs/smoke-test/fixtures/sample-design.md"
```

- [ ] **Step 5: Run the full validation set and verify the repository is internally consistent**

Run: `bash skills/_review-libs/smoke-test/test-artifact-dag.sh`  
Expected: PASS with no output

Run: `bash skills/_review-libs/smoke-test/test-review-gating.sh`  
Expected: PASS with no output

Run: `bash -n skills/_review-libs/artifact-dag.sh skills/_review-libs/run-review.sh skills/_review-libs/workspace.sh skills/_review-libs/prompt-builder.sh skills/_review-libs/output-validator.sh skills/_review-libs/smoke-test/test-artifact-dag.sh skills/_review-libs/smoke-test/test-review-gating.sh skills/_review-libs/smoke-test/smoke-cross-model-review.sh`  
Expected: PASS with no output

Run: `jq . skills/_review-libs/schemas/adversarial-reviewer-output.schema.json >/dev/null && jq . skills/_review-libs/schemas/review-run-output.schema.json >/dev/null`  
Expected: PASS with no output

Run: `bash skills/_review-libs/smoke-test/smoke-cross-model-review.sh plan --reviewer codex --timeout 1800 --plan skills/_review-libs/smoke-test/fixtures/sample-plan.md`  
Expected: PASS when `codex` CLI is available; if the CLI is unavailable, run `bash skills/_review-libs/health-check.sh` and confirm the missing reviewer is reported explicitly

- [ ] **Step 6: Commit the documentation and smoke-validation refresh**

```bash
git add \
  commands/review-plan.md \
  commands/review-code-impl.md \
  commands/review-design.md \
  skills/review-plan/SKILL.md \
  skills/review-code-impl/SKILL.md \
  skills/review-design/SKILL.md \
  skills/review-plan/references/workflow-details.md \
  skills/review-code-impl/references/workflow-details.md \
  skills/review-design/references/workflow-details.md \
  skills/review-plan/references/evidence-contracts.md \
  skills/review-code-impl/references/evidence-contracts.md \
  skills/review-design/references/evidence-contracts.md \
  skills/_review-libs/smoke-test/smoke-cross-model-review.sh
git commit -m "docs: align review workflows with artifact DAG fences"
```

## Self-Review

- Spec coverage:
  - design must declare implementation surface: covered in Tasks 1 and 5
  - plan must declare upstream design: covered in Tasks 1, 3, and 5
  - review-plan must fail without valid design linkage: covered in Tasks 3 and 5
  - code review must evaluate `design -> plan -> code`: covered in Tasks 4 and 5
  - repair-review must stay inside `allowed_touch_set`: covered in Tasks 3 and 4
  - out-of-scope issues must stop auto-repair: covered in Task 4
- Placeholder scan:
  - no deferred implementation markers remain
  - every changed task names exact file paths and exact commands
- Type consistency:
  - the plan uses one finding classifier name: `scope_class`
  - the plan uses one allowed-repair set name: `allowed_touch_set`
  - the plan uses one design bound name: `design_ceiling`
