# Security Requirements

- Run opposite-model reviewers only from an isolated workspace, such as a temporary worktree or CI checkout that contains only the files under review and required local context.
- The isolated workspace must not contain secrets, credentials, private keys, `.env` files, production configs, or unrelated source trees.
- Validate caller-provided implementation plan paths before generating prompt files.
- Keep prompt-file generation static in examples; do not teach shell interpolation of caller input in the example commands.
- Canonicalize all file and workspace paths with `realpath` before use and reject any path that resolves outside the isolated workspace or other explicitly allowed roots.
- The only explicitly allowed non-workspace roots are the canonical repository root, the canonical plugin root, and `CLAUDE_PLUGIN_ROOT` when it is set and canonicalized.
- In automation, invoke reviewer CLIs with argument arrays in the host language runtime. Do not build shell command strings from untrusted input.
