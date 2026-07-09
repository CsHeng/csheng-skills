#!/usr/bin/env python3
"""Validate a generated flat skill install surface."""

from __future__ import annotations

import argparse
import json
import sys
import tomllib
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
CONTRACT_PATH = REPO_ROOT / "contracts" / "skills.toml"
TARGETS_PATH = REPO_ROOT / "contracts" / "install-targets.toml"


def load_toml(path: Path) -> dict[str, Any]:
    with path.open("rb") as handle:
        return tomllib.load(handle)


def target_dest(target: str, override: str | None) -> Path:
    if override:
        return (REPO_ROOT / override).resolve()
    targets = load_toml(TARGETS_PATH)["targets"]
    return (REPO_ROOT / targets[target]["dest"]).resolve()


def selected_entries(target: str) -> dict[str, str]:
    data = load_toml(CONTRACT_PATH)
    expected: dict[str, str] = {}
    for skill_name, entry in sorted(data["skills"].items()):
        if target not in entry.get("install", []):
            continue
        if entry.get("category") == "internal" and target != "root-flat":
            raise ValueError(f"{skill_name}: internal skill cannot be installed for {target}")
        public_id = entry["public_id"]
        if public_id in expected:
            raise ValueError(f"duplicate public_id for {target}: {public_id}")
        expected[public_id] = entry["source"]
    return expected


def validate(target: str, dest: Path) -> list[str]:
    errors: list[str] = []
    skills_dir = dest if target == "root-flat" else dest / "skills"
    if not skills_dir.is_dir():
        return [f"missing skills directory: {skills_dir.relative_to(REPO_ROOT)}"]

    try:
        expected = selected_entries(target)
    except (KeyError, ValueError) as exc:
        return [str(exc)]

    actual = sorted(path.name for path in skills_dir.iterdir() if path.is_dir())
    expected_ids = sorted(expected)
    if actual != expected_ids:
        errors.append(f"{target}: skill directories differ; expected={expected_ids} actual={actual}")

    for public_id in expected_ids:
        skill_file = skills_dir / public_id / "SKILL.md"
        if not skill_file.is_file():
            errors.append(f"{target}: missing SKILL.md for {public_id}")

    source_map_path = skills_dir / ".source-map.json"
    if not source_map_path.is_file():
        errors.append(f"{target}: missing .source-map.json")
    else:
        try:
            source_map = json.loads(source_map_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            errors.append(f"{target}: invalid .source-map.json: {exc}")
        else:
            if source_map != expected:
                errors.append(f"{target}: .source-map.json differs from manifest selection")

    return errors


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", choices=["claude", "codex", "root-flat"], required=True)
    parser.add_argument("--dest", help="Override destination")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    errors = validate(args.target, target_dest(args.target, args.dest))
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print(f"{args.target} install surface ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
