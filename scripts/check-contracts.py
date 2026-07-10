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
VALID_WORKFLOW_ROLES = {"controller", "gate", "evaluator", "policy", "oracle", "support"}


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


def _runtime_contract_cycle(adjacency: dict[str, set[str]]) -> list[str] | None:
    visiting: set[str] = set()
    visited: set[str] = set()
    stack: list[str] = []

    def visit(node: str) -> list[str] | None:
        if node in visited:
            return None
        if node in visiting:
            start = stack.index(node)
            return stack[start:] + [node]

        visiting.add(node)
        stack.append(node)
        for target in sorted(adjacency.get(node, set())):
            cycle = visit(target)
            if cycle:
                return cycle
        stack.pop()
        visiting.remove(node)
        visited.add(node)
        return None

    for node in sorted(adjacency):
        cycle = visit(node)
        if cycle:
            return cycle
    return None


def validate_runtime_contracts(skills: dict[str, Any], repo_root: Path = REPO_ROOT) -> list[str]:
    errors: list[str] = []
    public_entries: dict[str, dict[str, Any]] = {}
    global_node_roles: dict[str, str] = {}
    global_edges: set[tuple[str, str]] = set()
    global_forbidden_edges: set[tuple[str, str]] = set()
    global_repair_owners: list[tuple[str, str]] = []
    for skill_name, entry in skills.items():
        public_id = entry.get("public_id")
        if isinstance(public_id, str) and public_id:
            public_entries[public_id] = entry

    for skill_name, entry in sorted(skills.items()):
        runtime_contract = entry.get("runtime_contract")
        if runtime_contract is None:
            continue
        if not isinstance(runtime_contract, str) or not runtime_contract:
            errors.append(f"{skill_name}: runtime_contract must be a non-empty relative path")
            continue
        if Path(runtime_contract).is_absolute() or ".." in Path(runtime_contract).parts:
            errors.append(f"{skill_name}: runtime_contract must stay inside the skill source")
            continue

        source = entry.get("source")
        if not isinstance(source, str):
            errors.append(f"{skill_name}: runtime contract requires a valid source")
            continue
        contract_path = repo_root / source / runtime_contract
        if not contract_path.is_file():
            errors.append(f"{skill_name}: runtime contract does not exist: {contract_path.relative_to(repo_root)}")
            continue

        try:
            with contract_path.open("rb") as handle:
                contract = tomllib.load(handle)
        except (OSError, tomllib.TOMLDecodeError) as exc:
            errors.append(f"{skill_name}: invalid runtime contract: {exc}")
            continue

        workflow = contract.get("workflow")
        nodes = contract.get("nodes")
        edges = contract.get("edges", [])
        forbidden_edges = contract.get("forbidden_edges", [])
        repair = contract.get("repair")
        public_id = entry.get("public_id")

        if not isinstance(workflow, dict) or workflow.get("id") != public_id:
            errors.append(f"{skill_name}: workflow.id must match public_id")
        if not isinstance(nodes, list) or not nodes:
            errors.append(f"{skill_name}: runtime contract requires at least one [[nodes]] entry")
            continue

        node_roles: dict[str, str] = {}
        repair_owners: list[str] = []
        for node in nodes:
            if not isinstance(node, dict):
                errors.append(f"{skill_name}: each runtime node must be a table")
                continue
            node_id = node.get("id")
            role = node.get("role")
            if not isinstance(node_id, str) or not node_id:
                errors.append(f"{skill_name}: runtime node id must be a non-empty string")
                continue
            if node_id in node_roles:
                errors.append(f"{skill_name}: duplicate runtime node: {node_id}")
                continue
            if node_id not in public_entries:
                errors.append(f"{skill_name}: unknown runtime node target: {node_id}")
            if role not in VALID_WORKFLOW_ROLES:
                errors.append(f"{skill_name}: invalid runtime node role for {node_id}: {role}")
            node_roles[node_id] = str(role)
            existing_role = global_node_roles.get(node_id)
            if existing_role is not None and existing_role != role:
                errors.append(
                    f"{skill_name}: runtime node role conflicts across contracts for {node_id}: "
                    f"{existing_role} != {role}"
                )
            else:
                global_node_roles[node_id] = str(role)
            if node.get("owns_repair_loop", False):
                repair_owners.append(node_id)

        edge_set: set[tuple[str, str]] = set()
        adjacency: dict[str, set[str]] = {node_id: set() for node_id in node_roles}
        if not isinstance(edges, list):
            errors.append(f"{skill_name}: edges must be an array of tables")
            edges = []
        for edge in edges:
            if not isinstance(edge, dict):
                errors.append(f"{skill_name}: each runtime edge must be a table")
                continue
            source_id = edge.get("from")
            target_id = edge.get("to")
            if source_id not in node_roles or target_id not in node_roles:
                errors.append(f"{skill_name}: runtime edge references unknown node: {source_id} -> {target_id}")
                continue
            edge_pair = (str(source_id), str(target_id))
            edge_set.add(edge_pair)
            global_edges.add(edge_pair)
            adjacency[str(source_id)].add(str(target_id))
            if node_roles[str(source_id)] == "evaluator":
                errors.append(f"{skill_name}: evaluator cannot invoke another skill: {source_id} -> {target_id}")

        if not isinstance(forbidden_edges, list):
            errors.append(f"{skill_name}: forbidden_edges must be an array of tables")
            forbidden_edges = []
        for edge in forbidden_edges:
            if not isinstance(edge, dict):
                errors.append(f"{skill_name}: each forbidden edge must be a table")
                continue
            edge_pair = (str(edge.get("from", "")), str(edge.get("to", "")))
            global_forbidden_edges.add(edge_pair)
            if edge_pair in edge_set:
                errors.append(f"{skill_name}: forbidden runtime edge is active: {edge_pair[0]} -> {edge_pair[1]}")

        cycle = _runtime_contract_cycle(adjacency)
        if cycle:
            errors.append(f"{skill_name}: runtime invocation graph contains a cycle: {' -> '.join(cycle)}")

        if not isinstance(repair, dict):
            errors.append(f"{skill_name}: runtime contract requires a [repair] table")
            continue
        repair_owner = repair.get("owner")
        expected_rounds = repair.get("expected_rounds")
        hard_limit = repair.get("hard_limit")
        if repair_owners != [repair_owner]:
            errors.append(f"{skill_name}: runtime contract must declare exactly one matching repair-loop owner")
        if isinstance(repair_owner, str) and repair_owner:
            global_repair_owners.append((skill_name, repair_owner))
        if repair_owner != public_id or not entry.get("lifecycle_owner", False):
            errors.append(f"{skill_name}: repair-loop owner must be the lifecycle-owning public skill")
        if not isinstance(expected_rounds, int) or not isinstance(hard_limit, int):
            errors.append(f"{skill_name}: repair round limits must be integers")
        elif not (1 <= expected_rounds <= hard_limit <= 10):
            errors.append(f"{skill_name}: repair rounds must satisfy 1 <= expected_rounds <= hard_limit <= 10")

    global_adjacency: dict[str, set[str]] = {
        node_id: set() for node_id in global_node_roles
    }
    for source_id, target_id in global_edges:
        global_adjacency.setdefault(source_id, set()).add(target_id)
        global_adjacency.setdefault(target_id, set())
        if global_node_roles.get(source_id) == "evaluator":
            errors.append(
                f"global runtime graph: evaluator cannot invoke another skill: "
                f"{source_id} -> {target_id}"
            )

    global_cycle = _runtime_contract_cycle(global_adjacency)
    if global_cycle:
        errors.append(
            "global runtime invocation graph contains a cycle: "
            + " -> ".join(global_cycle)
        )

    for source_id, target_id in sorted(global_forbidden_edges & global_edges):
        errors.append(
            f"global runtime graph: forbidden edge is active: {source_id} -> {target_id}"
        )

    if len(global_repair_owners) != 1:
        owner_summary = ", ".join(
            f"{skill_name}:{owner}" for skill_name, owner in global_repair_owners
        ) or "none"
        errors.append(
            "global runtime contracts must declare exactly one repair-loop owner; "
            f"found {owner_summary}"
        )

    return errors


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

    errors.extend(validate_runtime_contracts(skills))
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
