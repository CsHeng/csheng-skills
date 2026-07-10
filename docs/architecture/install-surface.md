# Install Surface

The source tree is structured for maintainability, while installed skill surfaces remain flat for agent compatibility.

## Surfaces

- `src/skills/`: source-of-truth tree grouped by category.
- `contracts/skills.toml`: contract and exposure source.
- `skills/`: tracked generated root-flat compatibility surface. Current plugin manifests point directly here.
- `.dist/claude/skills/`: ignored, reproducible Claude-compatible flat surface generated on demand.
- `.dist/codex/skills/`: ignored, reproducible Codex-compatible flat surface generated on demand.

## Generation

Regenerate the tracked runtime surface with:

```bash
python3 scripts/flatten-skills.py --target root-flat
```

Generate ignored external surfaces only when needed:

```bash
python3 scripts/flatten-skills.py --target claude
python3 scripts/flatten-skills.py --target codex
```

External generated surfaces include `skills/.source-map.json`. The root-flat generated surface includes `.source-map.json` directly under the repository root `skills/` directory. `--target all` remains available for explicit release or packaging work, but normal repository maintenance only refreshes `root-flat`.

## Internal Runtime Support

External targets exclude internal support libraries. The root-flat target includes `_harness-libs` and `_review-libs` because current command wrappers and plugin manifests resolve those runtime files under `skills/`.

That root-flat exception is declared in `contracts/skills.toml` with `category = "internal"`, `install = ["root-flat"]`, and `runtime_support = true`.

## Validation

Use:

```bash
bash scripts/check.sh
```

The check verifies manifest/source bijection, generated index freshness, the tracked root-flat surface, temporary Claude and Codex install surfaces, and retired review-routing references outside historical docs. It also rejects tracked `.dist/` files so a fresh clone remains sufficient for validation.
