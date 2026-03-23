---
name: review-health
description: Check review system health and availability
---

# Review Health Check

Validates review system components and reports availability status.

## Purpose

Diagnostic command that checks:
- Driver scripts exist and are executable
- Schema files are valid JSON
- Required tools are available (jq, bash)
- Reviewer CLIs are reachable (claude, codex, gemini)

## Usage

```bash
/review-health
```

## Output

Availability matrix showing:
- Driver status (available/missing)
- Schema validation (valid/invalid)
- Tool availability (present/absent)
- Reviewer CLI status (reachable/unreachable)

## Implementation

Shim: `commands/review-health.md`
Script: `skills/_review-libs/health-check.sh`
