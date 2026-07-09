#!/usr/bin/env python3
"""Generate a deterministic skill inventory from contracts/skills.toml."""

from __future__ import annotations

import argparse
import json
import sys
import tomllib
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
CONTRACT_PATH = REPO_ROOT / "contracts" / "skills.toml"
INDEX_PATH = REPO_ROOT / "skills.index.json"


def load_manifest() -> dict[str, Any]:
    with CONTRACT_PATH.open("rb") as handle:
        data = tomllib.load(handle)
    skills = data.get("skills")
    if not isinstance(skills, dict):
        raise SystemExit("contracts/skills.toml must contain [skills.*] entries")
    return skills


def build_index() -> dict[str, Any]:
    skills = []
    for skill_name, entry in sorted(load_manifest().items()):
        skills.append(
            {
                "id": skill_name,
                "source": entry["source"],
                "public_id": entry["public_id"],
                "category": entry["category"],
                "install": entry.get("install", []),
                "lifecycle_owner": entry.get("lifecycle_owner", False),
                "implicit_invocation": entry.get("implicit_invocation", False),
                "may_mutate_repo": entry.get("may_mutate_repo", False),
            }
        )
    return {"generated_from": "contracts/skills.toml", "skills": skills}


def formatted_index() -> str:
    return json.dumps(build_index(), indent=2, sort_keys=True) + "\n"


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Fail if skills.index.json is stale")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    rendered = formatted_index()
    if args.check:
        if not INDEX_PATH.is_file():
            print("skills.index.json is missing", file=sys.stderr)
            return 1
        current = INDEX_PATH.read_text(encoding="utf-8")
        if current != rendered:
            print("skills.index.json is stale; run scripts/generate-skills-index.py", file=sys.stderr)
            return 1
        return 0
    INDEX_PATH.write_text(rendered, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
