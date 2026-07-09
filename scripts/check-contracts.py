#!/usr/bin/env python3
"""Validate skill manifest, structured sources, and generated inventory."""

from __future__ import annotations

import json
import subprocess
import sys
import tomllib
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
CONTRACT_PATH = REPO_ROOT / "contracts" / "skills.toml"
INDEX_PATH = REPO_ROOT / "skills.index.json"
VALID_CATEGORIES = {
    "workflow",
    "session",
    "discipline",
    "policy",
    "tool",
    "manual-tool",
    "review-component",
    "internal",
}
EXTERNAL_TARGETS = {"claude", "codex"}


def load_manifest() -> dict[str, Any]:
    with CONTRACT_PATH.open("rb") as handle:
        data = tomllib.load(handle)
    skills = data.get("skills")
    if not isinstance(skills, dict):
        raise ValueError("contracts/skills.toml must contain [skills.*] entries")
    return skills


def source_skill_dirs() -> set[str]:
    result: set[str] = set()
    for skill_file in (REPO_ROOT / "src" / "skills").rglob("SKILL.md"):
        result.add(skill_file.parent.relative_to(REPO_ROOT).as_posix())
    return result


def check_index() -> list[str]:
    if not INDEX_PATH.is_file():
        return ["skills.index.json is missing"]
    result = subprocess.run(
        [sys.executable, "scripts/generate-skills-index.py", "--check"],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        return [result.stderr.strip() or result.stdout.strip() or "skills.index.json is stale"]
    try:
        json.loads(INDEX_PATH.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return [f"skills.index.json is invalid JSON: {exc}"]
    return []


def validate() -> list[str]:
    errors: list[str] = []
    try:
        skills = load_manifest()
    except (OSError, tomllib.TOMLDecodeError, ValueError) as exc:
        return [str(exc)]

    manifest_sources: set[str] = set()
    public_ids: set[str] = set()

    for skill_name, entry in sorted(skills.items()):
        source = entry.get("source")
        public_id = entry.get("public_id")
        category = entry.get("category")
        install = entry.get("install", [])

        if not isinstance(source, str):
            errors.append(f"{skill_name}: source must be a string")
            continue
        manifest_sources.add(source)
        source_path = REPO_ROOT / source
        if not source_path.is_dir():
            errors.append(f"{skill_name}: source does not exist: {source}")
        elif not (source_path / "SKILL.md").is_file():
            errors.append(f"{skill_name}: source lacks SKILL.md: {source}")

        if not isinstance(public_id, str) or not public_id:
            errors.append(f"{skill_name}: public_id must be a non-empty string")
        elif public_id in public_ids:
            errors.append(f"{skill_name}: duplicate public_id: {public_id}")
        else:
            public_ids.add(public_id)

        if category not in VALID_CATEGORIES:
            errors.append(f"{skill_name}: invalid category: {category}")

        if entry.get("lifecycle_owner", False) and category != "workflow":
            errors.append(f"{skill_name}: only workflow skills may set lifecycle_owner=true")

        if category == "internal":
            external_installs = sorted(set(install) & EXTERNAL_TARGETS)
            if external_installs:
                errors.append(f"{skill_name}: internal skill exposes external targets: {external_installs}")
            if install and install != ["root-flat"]:
                errors.append(f"{skill_name}: internal install must be [] or ['root-flat']")
            if install == ["root-flat"] and not entry.get("runtime_support", False):
                errors.append(f"{skill_name}: root-flat internal support requires runtime_support=true")

        if category == "manual-tool" and entry.get("implicit_invocation", False):
            errors.append(f"{skill_name}: manual-tool cannot be implicitly invoked")

        if entry.get("may_mutate_repo", False):
            has_guard = entry.get("requires_explicit_user_request", False) or entry.get("requires_approved_plan", False)
            if not has_guard:
                errors.append(f"{skill_name}: mutation-capable skills need explicit request or approved-plan guard")

    source_dirs = source_skill_dirs()
    missing_manifest = sorted(source_dirs - manifest_sources)
    stale_manifest = sorted(manifest_sources - source_dirs)
    if missing_manifest:
        errors.append("source skills missing manifest entries: " + ", ".join(missing_manifest))
    if stale_manifest:
        errors.append("manifest sources missing from src/skills: " + ", ".join(stale_manifest))

    errors.extend(check_index())
    return errors


def main() -> int:
    errors = validate()
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("contracts ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
