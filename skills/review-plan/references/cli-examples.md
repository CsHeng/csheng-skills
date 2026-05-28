# CLI Examples

## Claude host -> Codex reviewer

Prefer `codex exec` with the plugin-bundled schema resolved to an absolute path and a prompt file passed on stdin:

```bash
CODING_PLUGIN_ROOT="/absolute/path/to/coding-plugin"
SCHEMA="$(realpath "$CODING_PLUGIN_ROOT/skills/_review-libs/schemas/adversarial-reviewer-output.schema.json")"

printf '%s\n' \
  'Review the plan at "/absolute/path/to/plan.md" using the requirements-risk lens only.' \
  'Return structured JSON matching the shared reviewer schema.' \
  > /tmp/review-plan.prompt

codex exec \
  -C /absolute/path/to/repo \
  -s read-only \
  --skip-git-repo-check \
  --output-schema "$SCHEMA" \
  -o /tmp/review-plan-requirements.json \
  - < /tmp/review-plan.prompt
```

## Codex host -> Claude reviewer

Prefer `claude -p` with the same shared schema and the same prompt file:

```bash
CODING_PLUGIN_ROOT="/absolute/path/to/coding-plugin"
SCHEMA="$(realpath "$CODING_PLUGIN_ROOT/skills/_review-libs/schemas/adversarial-reviewer-output.schema.json")"

claude -p \
  --tools Read,Glob,Grep \
  --json-schema "$(cat "$SCHEMA")" \
  < /tmp/review-plan.prompt
```

Use a concrete plan path in the prompt file. In automation, have the orchestrator write the prompt file with the real path already substituted instead of generating shell commands by interpolating untrusted path input.
