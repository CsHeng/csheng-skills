---
name: tool-decision-tree
description: "Use when performing file searches, text searches, refactors, or choosing between equivalent CLI tools (fd/find, rg/grep, ast-grep, jq/yq). Enforces COUNT-PREVIEW-EXECUTE workflow. 中文触发：工具选型、搜索工具、重构工具。"
---

# Tool Decision Tree

## Purpose

Canonical tool selection and progressive search workflow (COUNT -> PREVIEW -> EXECUTE).

## Toolchain Preflight

Before depending on a tool, verify it exists with `command -v <tool>`.

Preferred tools with explicit fallbacks:
- File discovery: `fd` -> `find`
- Text search: `rg` -> `grep`
- Structural search/refactor: `ast-grep` -> "text search + manual edit"
- JSON extraction: `jq` -> `python3 -c 'import json; ...'`
- YAML validation/extraction: `yq` -> `python3 -c 'import yaml; ...'`

## Progressive Search Workflow

For any search that may return many results or any refactor that may touch multiple files:

### Step 1: COUNT (Assess Scope)

Count matches before printing large outputs.

```bash
rg -n "pattern" . | wc -l
fd -t f -e py . | wc -l
```

### Step 2: PREVIEW (Validate Target)

Preview representative matches before executing edits.

```bash
rg -n "pattern" . | head -n 50
rg -n --context 2 "pattern" path/to/dir | head -n 80
```

### Step 3: EXECUTE (Make the Change)

Execute changes only after COUNT and PREVIEW confirm correctness and scope.
Prefer structured refactors (`ast-grep`) over regex when available.

## Output Control

REQUIRED: Avoid dumping unbounded command output into the session.
PREFERRED: Use `head`, `sed -n`, targeted globs, and directory scoping.

## Safety

PROHIBITED: Run destructive operations (mass edits, deletes, resets) without an explicit plan and a scoped preview of impact.
