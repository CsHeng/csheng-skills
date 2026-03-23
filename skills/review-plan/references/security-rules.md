# Security Requirements

- Run opposite-model reviewers only from an isolated workspace, such as a temporary worktree or CI checkout that contains only the files under review.
- Validate caller-provided paths before generating prompt files.
- Keep prompt-file generation static in examples; let automation substitute concrete paths safely before execution.
- When a plan path is accepted, the allowed canonical roots are: the canonical repository root, the canonical plugin root, and `CLAUDE_PLUGIN_ROOT` when it is set and canonicalized.
- Canonicalize all file and workspace paths with `realpath` before use and reject any path that resolves outside the isolated workspace or other explicitly allowed roots.
- In automation, invoke reviewer CLIs with argument arrays in the host language runtime. Do not build shell command strings from untrusted input.
