#!/usr/bin/env python3
"""Generate flat skill install surfaces from the structured source tree."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
import tempfile
import tomllib
from pathlib import Path
from typing import TypedDict


REPO_ROOT = Path(__file__).resolve().parents[1]
CONTRACT_PATH = REPO_ROOT / "contracts" / "skills.toml"
TARGETS_PATH = REPO_ROOT / "contracts" / "install-targets.toml"


class SkillEntry(TypedDict, total=False):
    source: str
    public_id: str
    category: str
    install: list[str]
    runtime_support: bool


class TargetEntry(TypedDict, total=False):
    dest: str
    include_internal_runtime_support: bool


def load_toml(path: Path) -> dict[str, object]:
    with path.open("rb") as handle:
        return tomllib.load(handle)


def load_skills() -> dict[str, SkillEntry]:
    data = load_toml(CONTRACT_PATH)
    skills = data.get("skills")
    if not isinstance(skills, dict):
        raise SystemExit("contracts/skills.toml must contain [skills.*] entries")
    return skills  # type: ignore[return-value]


def load_targets() -> dict[str, TargetEntry]:
    data = load_toml(TARGETS_PATH)
    targets = data.get("targets")
    if not isinstance(targets, dict):
        raise SystemExit("contracts/install-targets.toml must contain [targets.*] entries")
    return targets  # type: ignore[return-value]


def selected_skills(skills: dict[str, SkillEntry], target: str) -> list[SkillEntry]:
    selected: list[SkillEntry] = []
    seen_public_ids: set[str] = set()
    for skill_name, entry in sorted(skills.items()):
        install_targets = entry.get("install", [])
        public_id = entry.get("public_id")
        source = entry.get("source")
        if target not in install_targets:
            continue
        if not public_id or not source:
            raise SystemExit(f"skill {skill_name} is missing public_id or source")
        if public_id in seen_public_ids:
            raise SystemExit(f"duplicate public_id selected for {target}: {public_id}")
        seen_public_ids.add(public_id)
        selected.append(entry)
    return selected


def remove_path(path: Path) -> None:
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.exists():
        shutil.rmtree(path)


def replace_directory(source: Path, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    backup: Path | None = None
    if dest.exists() or dest.is_symlink():
        backup = Path(tempfile.mkdtemp(prefix=f".{dest.name}.old.", dir=str(dest.parent)))
        backup.rmdir()
        dest.rename(backup)
    try:
        source.rename(dest)
    except BaseException:
        if backup is not None and not dest.exists():
            backup.rename(dest)
        raise
    else:
        if backup is not None:
            remove_path(backup)


def generate_target(target: str, dest: Path) -> None:
    skills = load_skills()
    selected = selected_skills(skills, target)
    tmp_parent = REPO_ROOT / ".tmp-install"
    tmp_parent.mkdir(exist_ok=True)
    tmp_dir = Path(tempfile.mkdtemp(prefix=f"{target}.", dir=str(tmp_parent)))
    tmp_dest = tmp_dir / "surface"
    skills_dest = tmp_dest if target == "root-flat" else tmp_dest / "skills"
    skills_dest.mkdir(parents=True)

    source_map: dict[str, str] = {}
    try:
        for entry in selected:
            public_id = entry["public_id"]
            source_rel = entry["source"]
            source_path = REPO_ROOT / source_rel
            if not source_path.is_dir():
                raise SystemExit(f"missing source directory for {public_id}: {source_rel}")
            if not (source_path / "SKILL.md").is_file():
                raise SystemExit(f"missing SKILL.md for {public_id}: {source_rel}")
            shutil.copytree(source_path, skills_dest / public_id, symlinks=False)
            source_map[public_id] = source_rel

        with (skills_dest / ".source-map.json").open("w", encoding="utf-8") as handle:
            json.dump(source_map, handle, indent=2, sort_keys=True)
            handle.write("\n")

        replace_directory(tmp_dest, dest)
    finally:
        remove_path(tmp_dir)


def target_dest(target: str, override: str | None) -> Path:
    if override:
        return (REPO_ROOT / override).resolve()
    targets = load_targets()
    entry = targets.get(target)
    if not entry or "dest" not in entry:
        raise SystemExit(f"unknown target: {target}")
    return (REPO_ROOT / entry["dest"]).resolve()


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", choices=["claude", "codex", "root-flat", "all"], required=True)
    parser.add_argument("--dest", help="Override destination for single-target generation")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    if args.target == "all":
        if args.dest:
            raise SystemExit("--dest cannot be used with --target all")
        for target in ("claude", "codex", "root-flat"):
            generate_target(target, target_dest(target, None))
        return 0
    generate_target(args.target, target_dest(args.target, args.dest))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
