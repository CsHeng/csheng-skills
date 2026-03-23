# CLI Examples

## Claude host -> Codex reviewer

Prefer `codex exec` with the shared schema at `docs/schemas/adversarial-reviewer-output.schema.json` and a prompt file passed on stdin:

```bash
printf '%s\n' \
  'Review the plan at "/absolute/path/to/plan.md" using the requirements-risk lens only.' \
  'Return structured JSON matching the shared reviewer schema.' \
  > /tmp/review-plan.prompt

codex exec \
  -C /absolute/path/to/repo \
  -s read-only \
  --skip-git-repo-check \
  --output-schema "docs/schemas/adversarial-reviewer-output.schema.json" \
  -o /tmp/review-plan-requirements.json \
  - < /tmp/review-plan.prompt
```

## Codex host -> Claude reviewer

Prefer `claude -p` with the same shared schema and the same prompt file:

```bash
claude -p \
  --tools Read,Glob,Grep \
  --json-schema "$(cat docs/schemas/adversarial-reviewer-output.schema.json)" \
  < /tmp/review-plan.prompt
```

Use a concrete plan path in the prompt file. In automation, have the orchestrator write the prompt file with the real path already substituted instead of generating shell commands by interpolating untrusted path input.
