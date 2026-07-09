# csheng-skills Restructuring Plan

## 0. Decision Summary

Adopt **方案 A**: keep the sovereign harness model, but harden its public/internal boundaries and make the skill surface generated from a structured source tree.

Primary direction:

- Keep the existing lifecycle kernel: `analyze → design → plan → execute → review → sync-truth → close`.
- Move from flat source layout to layered source layout.
- Do **not** add invocation metadata to individual `SKILL.md` files.
- Put skill contracts, install exposure, invocation policy, and lifecycle authority into an external manifest.
- Generate flat install surfaces for Claude Code / Codex CLI / other agents that may not support nested skill directories.
- Remove cross-driver / adversarial / multi-model review from the skills repo.
- Keep review same-driver / same-session by default.
- Treat future multi-LLM routing as a separate agent/router problem, not a skill problem.
- Add a maintenance contract, schema checks, generated inventory, and regression fixtures.

The goal is not to make the repo generic. The goal is to make the personal high-assurance harness maintainable, inspectable, installable, and less ambiguous to coding agents.

---

## 1. Non-goals

Do not do these in this migration:

- Do not rewrite the whole skill content.
- Do not convert this repo into a generic public skill pack.
- Do not split public/private repos yet.
- Do not introduce a Pi agent, router agent, or multi-LLM broker here.
- Do not keep cross-model review as a hidden fallback.
- Do not assume Claude Code or Codex CLI support nested skill directories.
- Do not rely on symlinks for installation.
- Do not add frontmatter or contract metadata into every `SKILL.md` unless later explicitly decided.
- Do not add operating-system-specific, host-specific, project-specific, or private-environment assumptions to published skills.
- Do not weaken existing invariants around human approval, no unattended execution, review gates, artifact validation, and evidence requirements.

---

## 2. Core Design

### 2.1 Source tree is structured; install surface is generated

Use a structured source tree as the source of truth:

```text
src/
  skills/
    workflows/
    session/
    disciplines/
    policies/
    tools/
    git/
    review-components/
    _internal/
```

Generate flat compatibility surfaces from that tree:

```text
.dist/
  claude/
    skills/
      analyze-project/
      design-change/
      plan-change/
      ...
  codex/
    skills/
      analyze-project/
      design-change/
      plan-change/
      ...
```

Optionally keep root `skills/` as a generated flat compatibility surface if current plugin packaging or local usage depends on it:

```text
skills/                         # generated, not source of truth
  analyze-project/
  design-change/
  plan-change/
  ...
```

If root `skills/` is kept, add a check that fails when generated output differs from source.

Do not use symlinks. Copy files deterministically.

### 2.2 `SKILL.md` remains prompt content, not contract storage

All machine-readable metadata should live outside `SKILL.md`.

Preferred contract location:

```text
contracts/
  skills.toml                  # source-of-truth skill catalog and exposure contract
  lifecycle.toml               # lifecycle phase definitions and allowed transitions
  workflow-modes.toml          # workflow composition profiles
  install-targets.toml         # target-specific install rules, if needed
```

Rationale:

- Keeps `SKILL.md` clean and model-facing.
- Avoids mixing prompt text with repo governance metadata.
- Makes validation independent from model prompt parsing.
- Allows target-specific exposure without editing skill text.

Use TOML by default because Python 3.11+ can parse it with stdlib `tomllib`. If the repo already has a reliable YAML checker/parser, YAML is acceptable; avoid adding a fragile parser dependency just to use YAML.

### 2.3 Skill contract categories

Define each skill in the external manifest with a category and invocation contract.

Recommended invocation classes:

| Class | Meaning | Can be user-visible | Can be auto-invoked by model | Can own lifecycle | Can mutate repo |
|---|---|---:|---:|---:|---:|
| `workflow` | Top-level lifecycle authority | yes | no, unless explicit router policy allows | yes | maybe |
| `session` | Session/bootstrap behavior | yes | maybe | no | no |
| `discipline` | Reusable engineering method | yes | yes | no | normally no |
| `policy` | Language/security/tooling rules | yes | yes | no | no |
| `tool` | Narrow tool adapter or operational helper | maybe | constrained | no | maybe |
| `manual-tool` | Explicit user action only | yes | no | no | yes |
| `review-component` | Called by review workflow or scripts | no or limited | no | no | no |
| `internal` | Shared library / implementation detail | no | no | no | no |

The important rule: **only `workflow` skills may own lifecycle state.**

### 2.4 Example `contracts/skills.toml`

```toml
[skills.analyze-project]
source = "src/skills/workflows/analyze-project"
public_id = "analyze-project"
category = "workflow"
install = ["claude", "codex", "root-flat"]
lifecycle_owner = true
implicit_invocation = false
may_mutate_repo = false
may_spawn_agent = false

[skills.design-change]
source = "src/skills/workflows/design-change"
public_id = "design-change"
category = "workflow"
install = ["claude", "codex", "root-flat"]
lifecycle_owner = true
implicit_invocation = false
may_mutate_repo = false
may_spawn_agent = false

[skills.plan-change]
source = "src/skills/workflows/plan-change"
public_id = "plan-change"
category = "workflow"
install = ["claude", "codex", "root-flat"]
lifecycle_owner = true
implicit_invocation = false
may_mutate_repo = false
may_spawn_agent = false

[skills.execute-change]
source = "src/skills/workflows/execute-change"
public_id = "execute-change"
category = "workflow"
install = ["claude", "codex", "root-flat"]
lifecycle_owner = true
implicit_invocation = false
may_mutate_repo = true
may_spawn_agent = true
requires_approved_plan = true

[skills.review-change]
source = "src/skills/workflows/review-change"
public_id = "review-change"
category = "workflow"
install = ["claude", "codex", "root-flat"]
lifecycle_owner = true
implicit_invocation = false
may_mutate_repo = false
may_spawn_agent = true

[skills.sync-truth]
source = "src/skills/workflows/sync-truth"
public_id = "sync-truth"
category = "workflow"
install = ["claude", "codex", "root-flat"]
lifecycle_owner = true
implicit_invocation = false
may_mutate_repo = true
may_spawn_agent = false

[skills.close-change]
source = "src/skills/workflows/close-change"
public_id = "close-change"
category = "workflow"
install = ["claude", "codex", "root-flat"]
lifecycle_owner = true
implicit_invocation = false
may_mutate_repo = false
may_spawn_agent = false

[skills.use-coding-skills]
source = "src/skills/session/use-coding-skills"
public_id = "use-coding-skills"
category = "session"
install = ["claude", "codex", "root-flat"]
lifecycle_owner = false
implicit_invocation = true
may_mutate_repo = false
may_spawn_agent = false

[skills.infrastructure-triage]
source = "src/skills/disciplines/infrastructure-triage"
public_id = "infrastructure-triage"
category = "discipline"
install = ["claude", "codex", "root-flat"]
lifecycle_owner = false
implicit_invocation = true
may_mutate_repo = false
may_spawn_agent = false

[skills.smart-commit]
source = "src/skills/git/smart-commit"
public_id = "smart-commit"
category = "manual-tool"
install = ["claude", "codex", "root-flat"]
lifecycle_owner = false
implicit_invocation = false
may_mutate_repo = true
may_spawn_agent = false
requires_explicit_user_request = true

[skills.review-code-impl]
source = "src/skills/review-components/review-code-impl"
public_id = "review-code-impl"
category = "review-component"
install = ["claude", "codex", "root-flat"]
lifecycle_owner = false
implicit_invocation = false
may_mutate_repo = false
may_spawn_agent = false

[skills.harness-libs]
source = "src/skills/_internal/harness-libs"
public_id = "_harness-libs"
category = "internal"
install = []
lifecycle_owner = false
implicit_invocation = false
may_mutate_repo = false
may_spawn_agent = false
```

Adjust names to match the actual repo inventory during implementation.

---

## 3. Proposed File Layout

Target source layout:

```text
.
├── contracts/
│   ├── skills.toml
│   ├── lifecycle.toml
│   ├── workflow-modes.toml
│   └── install-targets.toml
│
├── docs/
│   ├── architecture/
│   │   ├── harness-state-machine.md
│   │   ├── invocation-contract.md
│   │   ├── install-surface.md
│   │   └── maintenance-contract.md
│   └── changelog/
│       └── design-decisions.md
│
├── scripts/
│   ├── install.sh
│   ├── flatten-skills.py
│   ├── generate-skills-index.py
│   ├── check-contracts.py
│   ├── check-install-surface.py
│   └── check-no-cross-driver-review.sh
│
├── src/
│   └── skills/
│       ├── workflows/
│       │   ├── analyze-project/
│       │   ├── design-change/
│       │   ├── plan-change/
│       │   ├── execute-change/
│       │   ├── review-change/
│       │   ├── sync-truth/
│       │   └── close-change/
│       │
│       ├── session/
│       │   ├── use-coding-skills/
│       │   └── output-styles/
│       │
│       ├── disciplines/
│       │   ├── infrastructure-triage/
│       │   ├── testing-strategy/
│       │   ├── executable-oracle-architecture-selector/
│       │   ├── architecture-patterns/
│       │   ├── clean-architecture/
│       │   ├── error-patterns/
│       │   └── skill-miner/
│       │
│       ├── policies/
│       │   ├── python-guidelines/
│       │   ├── go-guidelines/
│       │   ├── shell-guidelines/
│       │   ├── powershell-guidelines/
│       │   ├── lua-guidelines/
│       │   ├── security-guardrails/
│       │   └── logging-standards/
│       │
│       ├── tools/
│       │   ├── web-fetch/
│       │   ├── context7-registry/
│       │   ├── docker-multiarch-build/
│       │   └── sops-age-guardrails/
│       │
│       ├── git/
│       │   ├── smart-commit/
│       │   └── smart-squash/
│       │
│       ├── review-components/
│       │   ├── review-design/
│       │   ├── review-plan/
│       │   └── review-code-impl/
│       │
│       └── _internal/
│           ├── harness-libs/
│           └── review-libs/
│
├── tests/
│   ├── fixtures/
│   └── golden/
│
├── skills/                    # optional generated flat compatibility surface
├── .dist/                     # generated target install surfaces
├── CHANGELOG.md
└── README.md
```

The exact skill list must be generated from the current repo, not assumed from this plan.

---

## 4. Workflow Composition Model

The current `design-change` `no/lite/full` split should not carry the whole burden of workflow routing. Move routing earlier into an explicit workflow mode selector.

### 4.1 Add workflow modes

Create `contracts/workflow-modes.toml`:

```toml
[modes.read_only]
description = "Analysis, triage, explanation, audit, inventory, or fact gathering. No repo mutation."
phases = ["analyze"]
allows_repo_mutation = false
requires_human_approval = false
requires_design_artifact = false
requires_plan_artifact = false
requires_review = false

[modes.micro]
description = "Small bounded change with low truth impact and low boundary impact."
phases = ["plan-lite", "execute", "verify", "close"]
allows_repo_mutation = true
requires_human_approval = true
requires_design_artifact = false
requires_plan_artifact = true
requires_review = "optional"

[modes.standard]
description = "Normal software change."
phases = ["analyze", "design-lite", "plan", "execute", "review", "sync-truth", "close"]
allows_repo_mutation = true
requires_human_approval = true
requires_design_artifact = true
requires_plan_artifact = true
requires_review = true

[modes.regulated]
description = "Infra, network, GitOps, IaC, secrets, auth, security, deployment, public API, irreversible data, or high-blast-radius changes."
phases = ["analyze", "design-full", "review-design", "plan", "review-plan", "execute", "review-impl", "sync-truth", "close"]
allows_repo_mutation = true
requires_human_approval = true
requires_design_artifact = true
requires_plan_artifact = true
requires_review = true
requires_rollback_surface = true
requires_fresh_evidence = true

[modes.emergency]
description = "Break/fix path. Minimize up-front ceremony, require post-change truth sync."
phases = ["triage", "minimal-plan", "execute", "verify", "posthoc-review", "sync-truth", "close"]
allows_repo_mutation = true
requires_human_approval = true
requires_design_artifact = "posthoc"
requires_plan_artifact = "minimal"
requires_review = "posthoc"
requires_fresh_evidence = true
```

### 4.2 Routing rules

Add router policy in `docs/architecture/harness-state-machine.md` or `contracts/lifecycle.toml`.

Recommended default routing:

| Request type | Mode |
|---|---|
| explanation, repo inspection, debugging hypothesis, doc audit | `read_only` |
| typo, local docs fix, narrow script fix, bounded low-risk edit | `micro` |
| ordinary feature/fix/refactor | `standard` |
| infra, network, proxy, tunnel, container networking, GitOps, IaC, secrets, auth, security, deploy, public API, data migration | `regulated` |
| outage, broken local workflow, urgent revert, minimal break/fix | `emergency` |

`design-change` should become a phase implementation, not the global router.

### 4.3 Composition rule

A workflow may compose disciplines and policies, but lower-plane skills must not advance lifecycle state.

Allowed:

```text
regulated workflow
  -> infrastructure-triage
  -> security-guardrails
  -> design-change
  -> review-design
  -> plan-change
  -> review-plan
  -> execute-change
  -> review-code-impl
  -> sync-truth
  -> close-change
```

Not allowed:

```text
infrastructure-triage
  -> directly execute repo mutation
  -> directly close change
```

---

## 5. Remove Cross-driver / Multi-model Review from Skills

### 5.1 New policy

The skills repo should only support same-driver review.

Policy:

- `review-change` may run same-driver / same-session / same-harness review.
- Review must be grounded in local artifacts, diffs, and fresh evidence.
- Review must not rely on a delegated model's success claim.
- Cross-model or adversarial review is out of scope for skills.
- External review reports may be attached as evidence, but skills do not spawn or route to external LLMs.
- Future multi-model routing belongs in a separate agent/router layer, possibly Pi-agent-based.

### 5.2 Remove or quarantine these concepts

Search and update references to:

```text
cross-driver
cross model
cross-model
multi-model
adversarial review
opposing model
review driver matrix
codex reviewer
claude reviewer
gemini reviewer
gemini --approval-mode yolo
same-driver opt-in
cross-driver opt-in
```

Suggested command:

```bash
grep -RInE 'cross[- ]driver|cross[- ]model|multi[- ]model|adversarial|opposing model|review driver|gemini|approval-mode yolo|same-driver|codex reviewer|claude reviewer' . \
  --exclude-dir=.git \
  --exclude-dir=.dist \
  --exclude-dir=skills
```

Do not blindly delete all matches. Classify each match:

| Match type | Action |
|---|---|
| old policy saying cross-driver is supported | remove or rewrite |
| same-driver default policy | keep, simplify |
| scripts only needed for cross-driver | delete or quarantine |
| reusable review runner needed by same-driver | keep |
| external report ingestion | keep only as passive evidence ingestion |
| docs explaining historical reason | move to changelog/design decision |

### 5.3 Target wording

Use wording like:

```text
Review is same-driver by default and by design. This repo does not route review work across different LLM providers or harnesses. External review reports may be attached as evidence, but spawning, selecting, or arbitrating between different LLMs is outside the skill layer.
```

### 5.4 Verification

Add `scripts/check-no-cross-driver-review.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

bad=0
patterns=(
  'cross-driver'
  'cross driver'
  'cross-model'
  'cross model'
  'multi-model review'
  'adversarial review'
  'opposing model'
  'approval-mode yolo'
)

for p in "${patterns[@]}"; do
  if grep -RIn --exclude-dir=.git --exclude-dir=.dist --exclude-dir=skills "$p" README.md src contracts docs scripts 2>/dev/null; then
    bad=1
  fi
done

if [[ "$bad" -ne 0 ]]; then
  echo "cross-driver / multi-model review references remain" >&2
  exit 1
fi
```

Allow historical references only in `CHANGELOG.md` or `docs/changelog/design-decisions.md`, and exclude those paths from the check if needed.

---

## 6. Maintenance Contract

Add `docs/architecture/maintenance-contract.md`.

It should define hard repo invariants.

### 6.1 Source and generated surfaces

Rules:

- `src/skills/**/SKILL.md` is the source of truth.
- `contracts/skills.toml` is the source of truth for skill exposure and invocation policy.
- Root `skills/` is generated compatibility output if kept.
- `.dist/` is generated install output.
- Do not edit generated skill surfaces directly.
- Any generated surface committed to git must be reproducible by `scripts/install.sh` or `scripts/flatten-skills.py`.

### 6.2 Skill change requirements

Any skill addition, deletion, rename, or category change must update:

- `contracts/skills.toml`
- generated `skills.index.json`, if committed
- README inventory
- relevant install target output
- at least one check or fixture when behavior changes
- `CHANGELOG.md` or design decision log when policy changes

### 6.3 Lifecycle authority rules

- Only `category = "workflow"` may set `lifecycle_owner = true`.
- A lifecycle owner must be user-invoked or explicitly routed by the session bootstrap.
- Discipline, policy, tool, review-component, and internal skills must not approve, execute, or close lifecycle state.
- Mutation-capable skills must require explicit user approval or an approved upstream artifact.
- `manual-tool` skills such as `smart-commit` must never be implicitly invoked.

### 6.4 Safety and evidence invariants

Keep these invariants:

- No unattended execution by default.
- Human approval gates remain authoritative.
- Fresh evidence is required for completion claims.
- Delegated-agent success reports are not sufficient evidence.
- Review must operate on explicit artifacts, diffs, or evidence.
- Review budgets must be enforced.
- Rollback surface must be explicit for regulated changes.
- Repo-owned docs/code/scripts/tests/skills are durable truth.
- Memories, summaries, logs, sessions, and caches are not durable truth unless explicitly promoted.

### 6.5 Environment-specific content policy

Allowed:

- Personal engineering style.
- Opinionated defaults.
- Local-first workflow preference.
- Infra/security/network/GitOps bias.

Not allowed in generally installed skills:

- Host-specific paths.
- Private project names.
- Private token names.
- OS-specific commands unless the skill is explicitly OS-specific.
- Assumptions about locally installed model providers unless guarded by capability checks.
- Provider-specific model names as required defaults.

---

## 7. Generated Inventory and Contract Checks

### 7.1 Generated inventory

Create generated inventory:

```text
skills.index.json
```

Example shape:

```json
{
  "generated_from": "contracts/skills.toml",
  "skills": [
    {
      "id": "analyze-project",
      "source": "src/skills/workflows/analyze-project",
      "public_id": "analyze-project",
      "category": "workflow",
      "install": ["claude", "codex", "root-flat"],
      "lifecycle_owner": true,
      "implicit_invocation": false,
      "may_mutate_repo": false
    }
  ]
}
```

### 7.2 Contract checker

Implement `scripts/check-contracts.py`.

Checks:

- Every `src/skills/**/SKILL.md` has one manifest entry.
- Every manifest `source` exists.
- Every manifest source contains `SKILL.md` unless explicitly marked as library-only.
- `public_id` values are unique.
- `workflow` is the only category that may set `lifecycle_owner = true`.
- `internal` skills have empty `install`.
- `manual-tool` skills have `implicit_invocation = false`.
- `may_mutate_repo = true` requires either `requires_explicit_user_request = true` or `requires_approved_plan = true`.
- Generated root `skills/`, if committed, matches source output.
- README inventory and manifest are consistent, if README has a generated inventory block.

### 7.3 Install checker

Implement `scripts/check-install-surface.py`.

Checks:

- Flattened install has no duplicate public IDs.
- Every installed skill has `SKILL.md`.
- No `internal` skill is installed.
- Optional: no generated output contains stale paths to old flat source layout.

---

## 8. Installer / Flattening Design

### 8.1 `scripts/install.sh`

Target interface:

```bash
./scripts/install.sh --target codex --dest .dist/codex
./scripts/install.sh --target claude --dest .dist/claude
./scripts/install.sh --target root-flat --dest skills
./scripts/install.sh --target all
./scripts/install.sh --check
```

Behavior:

- Read `contracts/skills.toml`.
- Select skills whose `install` includes the requested target.
- Copy each skill directory to `$dest/skills/$public_id`.
- Preserve files under each skill directory.
- Do not symlink.
- Write source map:

```text
$dest/skills/.source-map.json
```

- Generate atomically:

```text
.tmp-install/<target>/...
rename/move into final destination
```

- Fail on collision, missing `SKILL.md`, unknown target, or internal skill exposure.

### 8.2 Preserve prompt content

Do not inject generated headers into `SKILL.md` unless explicitly needed. Header pollution changes model-facing prompt content and makes diffs noisy.

Put source metadata in `.source-map.json` instead.

Example:

```json
{
  "analyze-project": "src/skills/workflows/analyze-project",
  "design-change": "src/skills/workflows/design-change"
}
```

---

## 9. README Restructure

README should expose layers explicitly.

Recommended structure:

```markdown
# csheng-skills

## Positioning
Human-sovereign, evidence-gated engineering harness for local coding agents.

## Lifecycle Kernel
- analyze-project
- design-change
- plan-change
- execute-change
- review-change
- sync-truth
- close-change

## Session Bootstrap
- use-coding-skills
- output-styles

## Reusable Disciplines
- infrastructure-triage
- testing-strategy
- executable-oracle-architecture-selector
- ...

## Policies
- python-guidelines
- go-guidelines
- shell-guidelines
- security-guardrails
- ...

## Manual Tools
- smart-commit
- smart-squash

## Review Components
Explain that these are components, not top-level lifecycle owners.

## Internal Libraries
Explain that these are not installed directly.

## Install
Explain generated flat surfaces and target adapters.

## Maintenance Contract
Link to docs/architecture/maintenance-contract.md.
```

README should not imply that lower-plane skills own lifecycle state.

---

## 10. CHANGELOG / Design Decision Log

Add `CHANGELOG.md` or `docs/changelog/design-decisions.md`.

Use this format:

```markdown
## YYYY-MM-DD - Remove cross-driver review from skill layer

### Failure mode
Cross-model review looked attractive as adversarial checking, but practical execution was unreliable and expanded the harness failure surface.

### Change
Review is now same-driver by design. Cross-model LLM routing is out of scope for skills and belongs to a separate agent/router layer.

### Operational impact
- Fewer moving parts in the skill layer.
- Less false confidence from mismatched external reviewer behavior.
- External review reports can still be attached as passive evidence.

### Follow-up
A future router agent may select task-specific LLMs outside this repo.
```

Also add entries for:

- structured source tree + flattened install surface
- external skill contracts instead of `SKILL.md` metadata
- workflow modes replacing `design-change` as global route selector
- maintenance contract and generated inventory

---

## 11. Regression Fixtures

Add lightweight static fixtures first. Do not introduce a heavy eval framework in this migration.

Suggested fixtures:

```text
tests/fixtures/
  readonly-request/
  micro-doc-change/
  regulated-infra-change/
  missing-oracle-plan/
  underlinked-review-artifact/
  repeated-review-failure/
  implicit-smart-commit-request/
  cross-driver-review-reference/
```

Suggested golden expectations:

```text
tests/golden/
  readonly-request.expected.json
  micro-doc-change.expected.json
  regulated-infra-change.expected.json
  missing-oracle-plan.expected.json
  underlinked-review-artifact.expected.json
  repeated-review-failure.expected.json
  implicit-smart-commit-request.expected.json
```

Minimum useful assertions:

| Fixture | Expected |
|---|---|
| read-only request | no mutation-capable skill selected |
| micro docs change | no design-full requirement |
| regulated infra change | regulated mode selected |
| missing oracle plan | stop state: `needs-oracle-strategy` |
| underlinked review artifact | stop state: `artifact-upgrade-required` |
| repeated review failure | stop state: `needs-next-batch-approval` |
| implicit smart-commit | reject implicit invocation |
| cross-driver reference | static check fails unless historical doc path is excluded |

Start with static checks and golden JSON. Defer live agent evals.

---

## 12. Migration Phases

### Phase 0 — Baseline inventory

Objective: inspect current repo and capture existing behavior before moving files.

Tasks:

1. Create a branch or worktree.
2. Capture current skill list:

   ```bash
   find skills -maxdepth 2 -name SKILL.md | sort
   ```

3. Capture current review-driver references:

   ```bash
   grep -RInE 'cross[- ]driver|cross[- ]model|multi[- ]model|adversarial|review driver|gemini|approval-mode yolo|same-driver' . \
     --exclude-dir=.git
   ```

4. Capture current install/plugin files:

   ```bash
   find . -maxdepth 3 \( -name '*plugin*' -o -name '*manifest*' -o -name 'openai.yaml' -o -name 'claude*' -o -name 'codex*' \) | sort
   ```

5. Do not change behavior in this phase.

Acceptance:

- Current skill inventory is known.
- Current install assumptions are known.
- Current cross-driver references are known.

---

### Phase 1 — Introduce structured source tree

Objective: move source skills under `src/skills/**` without changing content.

Tasks:

1. Create category directories under `src/skills/`.
2. Move each current skill directory into the appropriate category.
3. Preserve exact `SKILL.md` contents.
4. Preserve support files under each skill directory.
5. Do not edit prompt wording except path references that are mechanically invalid after the move.

Initial category mapping:

```text
workflows:
  analyze-project
  design-change
  plan-change
  execute-change
  review-change
  sync-truth
  close-change

session:
  use-coding-skills
  output-styles

review-components:
  review-design
  review-plan
  review-code-impl

_internal:
  _harness-libs
  _review-libs

git:
  smart-commit
  smart-squash

policies:
  language/tool/security/logging guidelines

disciplines:
  testing, architecture, decision, infra triage, oracle, skill-miner

tools:
  narrow tool adapters and operational helpers
```

If a skill does not fit cleanly, put it in `disciplines/` first and record a TODO in the contract file.

Acceptance:

```bash
find src/skills -name SKILL.md | sort
```

returns all previous skills.

---

### Phase 2 — Add external skill contract

Objective: create machine-readable skill metadata without changing `SKILL.md`.

Tasks:

1. Add `contracts/skills.toml`.
2. Add one entry per skill.
3. Include at least:

   ```toml
   source = "..."
   public_id = "..."
   category = "..."
   install = ["claude", "codex", "root-flat"]
   lifecycle_owner = false
   implicit_invocation = false
   may_mutate_repo = false
   may_spawn_agent = false
   ```

4. Mark only lifecycle kernel skills as `lifecycle_owner = true`.
5. Mark `smart-commit` and similar mutation tools as `manual-tool`, `implicit_invocation = false`, `may_mutate_repo = true`, `requires_explicit_user_request = true`.
6. Mark internal libraries as `category = "internal"`, `install = []`.

Acceptance:

- Every source skill has exactly one manifest entry.
- No `internal` skill is installable.
- No non-workflow skill owns lifecycle.

---

### Phase 3 — Add generator and flat install surfaces

Objective: support coding agents that expect flat skill directories.

Tasks:

1. Add `scripts/flatten-skills.py`.
2. Add `scripts/install.sh` wrapper.
3. Generate `.dist/claude/skills/$public_id`.
4. Generate `.dist/codex/skills/$public_id`.
5. If needed, generate root `skills/$public_id` for backward compatibility.
6. Add `.source-map.json` to generated surfaces.
7. Do not symlink.

Acceptance:

```bash
./scripts/install.sh --target claude --dest .dist/claude
./scripts/install.sh --target codex --dest .dist/codex
./scripts/install.sh --target root-flat --dest skills
find .dist/claude/skills -maxdepth 2 -name SKILL.md | sort
find .dist/codex/skills -maxdepth 2 -name SKILL.md | sort
```

The generated surfaces contain the expected installable skills and exclude internal-only skills.

---

### Phase 4 — Add contract checks

Objective: make source/manifest/install drift detectable.

Tasks:

1. Add `scripts/check-contracts.py`.
2. Add `scripts/check-install-surface.py`.
3. Add `scripts/check-no-cross-driver-review.sh`.
4. Add a top-level check command, either:

   ```bash
   ./scripts/check.sh
   ```

   or a `Makefile` target:

   ```bash
   make check
   ```

Minimum checks:

```text
- source skills and manifest are bijective
- public_id unique
- only workflow skills lifecycle_owner=true
- internal install=[]
- manual-tool implicit_invocation=false
- mutation-capable skill has explicit request or approved-plan requirement
- generated install surface matches manifest
- no cross-driver review references outside changelog/design-history docs
```

Acceptance:

```bash
./scripts/check.sh
```

passes.

---

### Phase 5 — Remove cross-driver review from active skill layer

Objective: delete or quarantine unreliable multi-model review behavior.

Tasks:

1. Update `review-change` wording to same-driver only.
2. Remove active references to cross-driver/adversarial/multi-model review.
3. Delete or quarantine scripts/configs that only exist to select external LLM reviewers.
4. Keep same-driver review runner behavior if still used.
5. Add design decision log entry explaining why this moved out of skills.
6. Allow passive external review evidence only if user supplies it.

Acceptance:

```bash
./scripts/check-no-cross-driver-review.sh
```

passes.

Manual verification:

- `review-change` no longer suggests spawning another provider/model.
- README no longer advertises cross-driver review as a repo capability.
- Any future router agent is mentioned only as out-of-scope design direction.

---

### Phase 6 — Add workflow modes

Objective: make composition explicit and reduce overloading of `design-change`.

Tasks:

1. Add `contracts/workflow-modes.toml`.
2. Add `docs/architecture/harness-state-machine.md`.
3. Update `use-coding-skills` or add a lightweight `workflow-router` skill/doc to select mode before invoking phase skills.
4. Change wording so `design-change` is a phase, not the global workflow selector.
5. Preserve existing `no/lite/full` semantics as implementation detail if still useful.

Acceptance:

- Read-only tasks map to `read_only`.
- Small bounded tasks map to `micro`.
- Normal changes map to `standard`.
- Infra/security/auth/secrets/IaC/network/deployment changes map to `regulated`.
- Emergency break/fix maps to `emergency`.

---

### Phase 7 — Add maintenance contract and README update

Objective: make long-term repo rules explicit.

Tasks:

1. Add `docs/architecture/maintenance-contract.md`.
2. Update README to expose layered architecture.
3. Add generated or manually maintained skill inventory grouped by category.
4. Link README to maintenance contract, install surface doc, and state machine doc.
5. Add `CHANGELOG.md` or design decision log.

Acceptance:

- README clearly distinguishes lifecycle kernel, session bootstrap, disciplines, policies, manual tools, review components, and internals.
- README does not imply every skill is a peer top-level authority.
- Maintenance contract states source/generated boundary and invocation rules.

---

### Phase 8 — Add lightweight regression fixtures

Objective: catch the highest-value routing and policy regressions without live agent evals.

Tasks:

1. Add static fixtures under `tests/fixtures/`.
2. Add expected outcomes under `tests/golden/`.
3. Add script to validate fixture expectations against contract/router data.
4. Start with simple JSON assertions; do not build a heavy evaluator yet.

Acceptance:

```bash
./scripts/check.sh
```

runs fixture checks and passes.

---

## 13. Final Acceptance Criteria

The migration is complete when all of these are true:

```text
[ ] Source skills live under src/skills/**.
[ ] Root skills/ is either removed or generated from src/skills/**.
[ ] No install path depends on symlinks.
[ ] contracts/skills.toml defines every skill.
[ ] SKILL.md files do not contain machine-readable repo contract metadata.
[ ] Only lifecycle workflow skills can own lifecycle state.
[ ] Manual mutation tools cannot be implicitly invoked.
[ ] Internal libraries are not installed.
[ ] Same-driver review is the only active review mode in skills.
[ ] Cross-driver / multi-model review is moved out of scope.
[ ] workflow modes exist and route before design-change.
[ ] Maintenance contract exists.
[ ] README exposes the new layering.
[ ] Generated install surfaces work for Claude/Codex/root-flat targets.
[ ] Static checks detect manifest drift, generated-surface drift, and forbidden cross-driver references.
[ ] Changelog/design decision log explains the migration and the removal of cross-driver review.
```

---

## 14. Suggested Codex Execution Protocol

Use this protocol while implementing the plan:

1. Work in small commits or at least small diff groups:

   ```text
   1. move source tree only
   2. add contracts
   3. add generator
   4. add checks
   5. remove cross-driver review
   6. add modes/docs
   7. update README/changelog
   ```

2. After each diff group, run:

   ```bash
   git status --short
   find src/skills -name SKILL.md | sort
   ./scripts/check.sh
   ```

   If `check.sh` does not exist yet, run the available partial checks.

3. Avoid semantic prompt rewrites during file movement.

4. When removing cross-driver review, preserve same-driver review behavior.

5. When uncertain whether a skill is `discipline`, `tool`, or `policy`, choose the least-authoritative category first.

6. Do not introduce new runtime dependencies without a clear reason.

7. Prefer static validation over agent-runtime assumptions.

8. Stop and report if the current plugin packaging requires root `skills/` as source and cannot tolerate generated output. In that case, keep root `skills/` generated and committed, with a strict drift check.

---

## 15. Expected End State

The repo should read as:

```text
Human-facing concept:
  sovereign lifecycle harness

Source-of-truth implementation:
  structured src/skills tree
  external contracts
  workflow modes
  generated install surfaces

Agent-facing install surface:
  flat skills directory per target

Control invariants:
  human-sovereign
  evidence-gated
  no unattended execution by default
  same-driver review only
  lower-plane skills cannot own lifecycle
  mutation requires explicit request or approved artifact
```

This keeps the personal style and high-assurance workflow intact while reducing accidental invocation, flat-directory entropy, cross-driver unreliability, and maintenance drift.
