---
description: Top-level sovereign harness entry for merge, release, or cleanup judgment after all required gates pass
argument-hint: "[merge|release|cleanup]"
allowed-tools: ["Read", "Glob", "Grep", "Bash"]
---

Invoke the `coding:close-change` skill as the top-level closure gate.

Interpret `$ARGUMENTS` as the requested close mode when present.

Rules:
- require review pass and verify pass before closure
- require truth sync when the change has real truth impact
- keep final completion judgment at the harness layer
- do not treat this command as permission to modify user-global Codex state or uninstall unrelated tooling
