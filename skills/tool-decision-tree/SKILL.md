---
name: tool-decision-tree
description: "Use for agent ad hoc CLI/tool selection and command composition, including fd/find, rg/grep, ast-grep, jq/yq, reviewable scratch scripts, and COUNT/PREVIEW/EXECUTE."
---

# Tool Decision Tree

## Purpose

Canonical agent ad hoc tool selection, command composition, and progressive search workflow (COUNT -> PREVIEW -> EXECUTE). This skill governs how the current task is executed; it does not choose the implementation language for new persisted repository code.

## Progressive Disclosure

- Ad hoc command composition and nested-interpreter boundaries: `references/adhoc-command-composition.md`
- Local command-output proxy guidance: `references/command-output-proxies.md`

## Target Preflight

Before searching, refactoring, or running repository-specific commands, identify the target:

```bash
pwd
git rev-parse --show-toplevel 2>/dev/null || true
test -e <target-path>
```

Rules:
- If no Git root exists, do not treat `git status` failure as a task blocker; switch to path-scoped file checks.
- If multiple repositories or home directories are in scope, print or record the active target path before drawing conclusions.
- For runtime or host-specific work, verify the active host/home context before importing assumptions from a previous incident.
- For missing paths, first verify whether the path is ignored, generated, mounted, or under a different home before concluding it does not exist.

## Toolchain Preflight

Assume the preferred tools exist in the normal agent environment. Do not run ritual `command -v` checks before ordinary searches.

Use `command -v <tool>` only when:
- the preferred tool fails with `command not found`, a PATH-like error, or an unexpected launcher/runtime error
- choosing between an explicit fallback path after the preferred command fails
- diagnosing host-specific, non-interactive, CI, or remote-shell PATH behavior
- writing script logic that must emit a deterministic missing-tool error or report optional capability availability

Preferred tools with explicit fallbacks:
- File discovery: `fd` -> `find`
- Text search: `rg` -> `grep`
- Text search with lookaround/backreferences: `rg --pcre2` -> reviewable scratch script using the standard library
- Structural search/refactor: `ast-grep` -> "text search + manual edit"
- JSON extraction: `jq` -> standard-library Python scratch script
- YAML validation/extraction: `yq` -> `uvx --with pyyaml python3 <scratch-script>`

### Python Fallback Dependencies

Plain `python3` fallback commands may assume only the Python standard library. Do not assume PyYAML, requests, pytest, or other third-party packages exist in system Python or mise-managed Python. When procedural fallback logic is more than a simple expression, put it in a repo-external scratch script, review it, syntax-check it, and invoke it directly instead of nesting Python source inside a Shell command string. For one-off parsing that needs a third-party package, use `uvx --with <package> python3 <scratch-script>` and redirect Python bytecode caches when the script imports files from the target repository.

## Progressive Search Workflow

For any search that may return many results or any refactor that may touch multiple files:

### Step 1: COUNT (Assess Scope)

Count matches before printing large outputs.

```bash
rg -n "pattern" . | wc -l
fd -t f -e py . | wc -l
```

For `rg`, exit code `1` means no matches when the command otherwise ran successfully. Treat it as a no-match search result, not a tool failure.

### Step 2: PREVIEW (Validate Target)

Preview representative matches before executing edits.

```bash
rg -n "pattern" . | head -n 50
rg -n --context 2 "pattern" path/to/dir | head -n 80
```

Use `rg --pcre2` before patterns with lookaround or backreferences. If PCRE2 is unavailable, switch to a small reviewable parser in a repo-external scratch file instead of repeatedly retrying invalid `rg` syntax or compressing procedural logic into nested quoting.

### Step 3: EXECUTE (Make the Change)

Execute changes only after COUNT and PREVIEW confirm correctness and scope.
Prefer structured refactors (`ast-grep`) over regex when available.

## Output Control

REQUIRED: Avoid dumping unbounded command output into the session.
PREFERRED: Use `head`, `sed -n`, targeted globs, and directory scoping.

## Command Output Proxies

Prefer token-reducing command proxies when they are available and when output filtering does not change the evidence needed. See `references/command-output-proxies.md` for the local `rtk` guidance.

## Structured History Search

For large JSONL histories such as Codex or Claude sessions, prefer a structured parser over raw text search. Count files first, parse JSON records, and filter injected system/skill text before treating matches as user intent.

## Safety

PROHIBITED: Run destructive operations (mass edits, deletes, resets) without an explicit plan and a scoped preview of impact.
PROHIBITED: Interpolate untrusted values into executable Shell, Python, or other source strings.
PREFERRED: Avoid nested interpreters and generated code strings when a direct tool, single-layer command, or reviewable scratch script can express the operation.
