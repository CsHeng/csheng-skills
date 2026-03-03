---
description: Check for sensitive information in code
allowed-tools: ["Bash(git ls-files:*)", "Bash(git diff:*)", "Bash(git diff --cached:*)", "Bash(git show:*)", "Read", "Grep", "Glob"]
---

# Check for secrets in current project

Scan all tracked files, unstaged changes, and common config files for sensitive information.

## Workflow

1. Enumerate files: Run `git ls-files` to get all tracked files
2. Check unstaged changes: Run `git diff` and `git diff --cached` to inspect pending changes
3. Scan for secret patterns across all enumerated files:
   - API keys and tokens (AWS, GCP, Azure, GitHub, Slack, etc.)
   - Passwords and credentials (hardcoded strings, connection strings)
   - Private keys and certificates (PEM, RSA, SSH keys)
   - Database connection strings (with embedded credentials)
   - Hardcoded secrets in environment variable assignments
4. Check common config files (`.env`, `*.config`, `credentials.*`, `secrets.*`) even if gitignored
5. For each finding, report:
   - File path and line number
   - Pattern matched and severity (critical/high/medium/low)
   - Remediation steps (e.g., move to environment variable, use secrets manager)
