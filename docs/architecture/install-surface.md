# Install Surface

The source tree is structured for maintainability, while installed skill surfaces remain flat for agent compatibility.

## Surfaces

- `src/skills/`: source-of-truth tree grouped by category.
- `contracts/skills.toml`: contract and exposure source.
- `skills/`: generated root-flat compatibility surface. Current plugin manifests point directly here.
- `.dist/claude/skills/`: generated Claude-compatible flat surface.
- `.dist/codex/skills/`: generated Codex-compatible flat surface.

## Generation

Use:

```bash
python3 scripts/flatten-skills.py --target claude
python3 scripts/flatten-skills.py --target codex
python3 scripts/flatten-skills.py --target root-flat
python3 scripts/flatten-skills.py --target all
```

External generated surfaces include `skills/.source-map.json`. The root-flat generated surface includes `skills/.source-map.json` directly under the repository root `skills/` directory.

## Internal Runtime Support

External targets exclude internal support libraries. The root-flat target includes `_harness-libs` and `_review-libs` because current command wrappers and plugin manifests resolve those runtime files under `skills/`.

That root-flat exception is declared in `contracts/skills.toml` with `category = "internal"`, `install = ["root-flat"]`, and `runtime_support = true`.

## Validation

Use:

```bash
bash scripts/check.sh
```

The check verifies manifest/source bijection, generated index freshness, generated install surfaces, and retired review-routing references outside historical docs.
