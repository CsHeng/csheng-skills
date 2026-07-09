#!/usr/bin/env python3
"""Validate static workflow and invocation fixtures against contracts."""

from __future__ import annotations

import json
import sys
import tomllib
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
FIXTURE_DIR = REPO_ROOT / "tests" / "fixtures"
GOLDEN_DIR = REPO_ROOT / "tests" / "golden"


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def load_toml(path: Path) -> dict[str, Any]:
    with path.open("rb") as handle:
        return tomllib.load(handle)


def assert_equal(actual: Any, expected: Any, label: str, errors: list[str]) -> None:
    if actual != expected:
        errors.append(f"{label}: expected {expected!r}, got {actual!r}")


def check_mode_fixture(name: str, modes: dict[str, Any], errors: list[str]) -> None:
    fixture = load_json(FIXTURE_DIR / f"{name}.json")
    golden = load_json(GOLDEN_DIR / f"{name}.expected.json")
    mode_name = fixture["expected_mode"]
    mode = modes.get(mode_name)
    if not mode:
        errors.append(f"{name}: missing workflow mode {mode_name}")
        return
    assert_equal(mode_name, golden["mode"], f"{name}.mode", errors)
    for key, expected in golden.items():
        if key == "mode":
            continue
        assert_equal(mode.get(key), expected, f"{name}.{key}", errors)


def check_smart_commit_fixture(skills: dict[str, Any], errors: list[str]) -> None:
    golden = load_json(GOLDEN_DIR / "implicit-smart-commit-request.expected.json")
    skill = skills.get("smart-commit")
    if not skill:
        errors.append("implicit-smart-commit-request: missing smart-commit contract")
        return
    for key, expected in golden.items():
        assert_equal(skill.get(key), expected, f"smart-commit.{key}", errors)


def check_output_styles_contract(errors: list[str]) -> None:
    skill_file = REPO_ROOT / "src" / "skills" / "session" / "output-styles" / "SKILL.md"
    explanatory_ref = skill_file.parent / "references" / "explanatory.md"
    review_ref = skill_file.parent / "references" / "review.md"

    skill_text = skill_file.read_text(encoding="utf-8")
    explanatory_text = explanatory_ref.read_text(encoding="utf-8")
    review_text = review_ref.read_text(encoding="utf-8")

    required_pairs = {
        "output-styles.unique-labels": (skill_text, "Use globally unique list labels"),
        "output-styles.no-restart": (skill_text, "Do not restart `1. 2. 3.`"),
        "output-styles.plan-confirmation-labels": (skill_text, "`C*` for confirmation clearance"),
        "output-styles.a-b-labels": (explanatory_text, "`A1`, `A2`"),
        "output-styles.review-prefixes": (review_text, "findings: `F1`, `F2`"),
    }
    for label, (content, needle) in required_pairs.items():
        if needle not in content:
            errors.append(f"{label}: missing {needle!r}")


def main() -> int:
    errors: list[str] = []
    modes = load_toml(REPO_ROOT / "contracts" / "workflow-modes.toml")["modes"]
    skills = load_toml(REPO_ROOT / "contracts" / "skills.toml")["skills"]
    for name in ("read-only-request", "micro-doc-change", "regulated-infra-change"):
        check_mode_fixture(name, modes, errors)
    check_smart_commit_fixture(skills, errors)
    check_output_styles_contract(errors)
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("fixtures ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
