#!/usr/bin/env python3
"""Generate stable PlantUML views from the installed workflow contract."""

from __future__ import annotations

import argparse
import re
import sys
import tomllib
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
SKILLS_CONTRACT = REPO_ROOT / "contracts" / "skills.toml"
CONTROLLER_ID = "implement-change"
DIAGRAM_DIR = REPO_ROOT / "docs" / "architecture" / "diagrams"
DAG_PATH = DIAGRAM_DIR / "implementation-invocation-dag.puml"
REPAIR_PATH = DIAGRAM_DIR / "implementation-repair-loop.puml"


def load_toml(path: Path) -> dict[str, Any]:
    with path.open("rb") as handle:
        return tomllib.load(handle)


def controller_contract() -> tuple[Path, dict[str, Any]]:
    skills = load_toml(SKILLS_CONTRACT)["skills"]
    entry = skills.get(CONTROLLER_ID)
    if not entry:
        raise ValueError(f"missing {CONTROLLER_ID} skill contract")
    runtime_contract = entry.get("runtime_contract")
    if not runtime_contract:
        raise ValueError(f"missing runtime contract for {CONTROLLER_ID}")
    path = REPO_ROOT / entry["source"] / runtime_contract
    contract = load_toml(path)
    if contract.get("workflow", {}).get("id") != CONTROLLER_ID:
        raise ValueError(f"workflow id does not match {CONTROLLER_ID}")
    return path, contract


def alias(value: str) -> str:
    return "n_" + re.sub(r"[^a-zA-Z0-9_]", "_", value)


def render_dag(contract_path: Path, contract: dict[str, Any]) -> str:
    nodes = contract["nodes"]
    edges = contract.get("edges", [])
    forbidden = contract.get("forbidden_edges", [])
    source = contract_path.relative_to(REPO_ROOT).as_posix()
    lines = [
        "@startuml",
        f"' Generated from {source}; do not edit by hand.",
        "title Implementation Invocation DAG",
        "left to right direction",
        "skinparam shadowing false",
        "skinparam componentStyle rectangle",
        "skinparam ArrowColor #475569",
        "skinparam rectangle {",
        "  BackgroundColor #F8FAFC",
        "  BorderColor #475569",
        "}",
        "",
    ]
    for node in nodes:
        node_id = node["id"]
        role = node["role"]
        lines.append(f'rectangle "{node_id}\\n({role})" as {alias(node_id)} <<{role}>>')
    lines.append("")
    for edge in edges:
        lines.append(f'{alias(edge["from"])} --> {alias(edge["to"])} : invoke')

    if forbidden:
        lines.extend(["", f"note bottom of {alias(contract['workflow']['id'])}", "  Forbidden reverse calls:"])
        for edge in forbidden:
            lines.append(f"  {edge['from']} -X-> {edge['to']}")
        lines.append("end note")

    lines.extend(
        [
            "",
            "legend right",
            "  controller = lifecycle and repair owner",
            "  gate = verdict normalization or next-state gate",
            "  evaluator = read-only evidence producer",
            "endlegend",
            "@enduml",
            "",
        ]
    )
    return "\n".join(lines)


def render_repair_loop(contract_path: Path, contract: dict[str, Any]) -> str:
    repair = contract["repair"]
    states = repair["states"]
    typed_exits = repair["typed_exits"]
    source = contract_path.relative_to(REPO_ROOT).as_posix()
    required_states = {"implement", "verify", "review", "classify", "diagnose", "repair"}
    if set(states) != required_states:
        raise ValueError(f"repair states differ from supported diagram shape: {states}")

    lines = [
        "@startuml",
        f"' Generated from {source}; do not edit by hand.",
        "title Controller-Owned Implementation Repair Loop",
        "hide empty description",
        "skinparam shadowing false",
        "skinparam state {",
        "  BackgroundColor #F8FAFC",
        "  BorderColor #475569",
        "}",
        "",
    ]
    for state in states:
        lines.append(f'state "{state}" as {alias(state)}')
    for exit_name in typed_exits:
        lines.append(f'state "{exit_name}" as {alias("exit_" + exit_name)} <<exit>>')

    lines.extend(
        [
            "",
            f"[*] --> {alias('implement')}",
            f"{alias('implement')} --> {alias('verify')} : task slice complete",
            f"{alias('verify')} --> {alias('review')} : declared oracles complete",
            f"{alias('review')} --> {alias('classify')} : bounded candidates",
            f"{alias('classify')} --> {alias('diagnose')} : accepted local repair",
            f"{alias('diagnose')} --> {alias('repair')} : root-cause hypothesis",
            f"{alias('repair')} --> {alias('verify')} : batched in-scope fix",
        ]
    )
    for exit_name in typed_exits:
        label = "review + verification pass" if exit_name == "pass" else "typed boundary"
        lines.append(f"{alias('classify')} --> {alias('exit_' + exit_name)} : {label}")
        lines.append(f"{alias('exit_' + exit_name)} --> [*]")

    lines.extend(
        [
            "",
            f"note right of {alias('repair')}",
            f"  Owner: {repair['owner']}",
            f"  Initial bounded review: {repair['initial_review_passes']}",
            f"  Focused verification: {repair['focused_verification_passes']}",
            f"  Additional same-slice repair attempts: {repair['additional_same_slice_repair_attempts']}",
            "  Only main-agent accepted findings enter repair.",
            "end note",
            "@enduml",
            "",
        ]
    )
    return "\n".join(lines)


def expected_outputs() -> dict[Path, str]:
    contract_path, contract = controller_contract()
    return {
        DAG_PATH: render_dag(contract_path, contract),
        REPAIR_PATH: render_repair_loop(contract_path, contract),
    }


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Fail when generated diagrams are stale")
    args = parser.parse_args(argv)

    try:
        outputs = expected_outputs()
    except (KeyError, OSError, ValueError, tomllib.TOMLDecodeError) as exc:
        print(f"workflow diagram generation failed: {exc}", file=sys.stderr)
        return 1

    if args.check:
        stale = [path for path, expected in outputs.items() if not path.is_file() or path.read_text(encoding="utf-8") != expected]
        if stale:
            for path in stale:
                print(f"stale workflow diagram: {path.relative_to(REPO_ROOT)}", file=sys.stderr)
            return 1
        print("workflow diagrams ok")
        return 0

    DIAGRAM_DIR.mkdir(parents=True, exist_ok=True)
    for path, content in outputs.items():
        path.write_text(content, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
