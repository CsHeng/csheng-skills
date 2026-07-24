from __future__ import annotations

import json
import tomllib
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = REPO_ROOT / "src" / "skills" / "disciplines"
API_CONTRACT_ROOT = SOURCE_ROOT / "api-contract-strategy"
TESTING_ROOT = SOURCE_ROOT / "testing-strategy"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


class APIContractStrategyContractTests(unittest.TestCase):
    def test_skill_uses_one_level_progressive_disclosure(self) -> None:
        skill = read(API_CONTRACT_ROOT / "SKILL.md")

        for reference in (
            "references/structured-contract-stack.md",
            "references/verification-layers.md",
            "references/contract-lifecycle.md",
            "references/legacy-adoption.md",
            "references/tool-selection.md",
        ):
            with self.subTest(reference=reference):
                self.assertIn(reference, skill)
                self.assertTrue((API_CONTRACT_ROOT / reference).is_file())

        self.assertLess(len(skill.splitlines()), 220)

    def test_structured_stack_separates_authoring_sources_and_projections(
        self,
    ) -> None:
        reference = read(
            API_CONTRACT_ROOT
            / "references"
            / "structured-contract-stack.md"
        )

        for expected in (
            "OpenAPI-first",
            "typed declarative code-first",
            "annotation",
            "complete",
            "stale",
            "domain",
            "root",
            "bundle",
            "generated",
            "provider",
            "consumer",
            "human reference",
        ):
            with self.subTest(expected=expected):
                self.assertIn(expected, reference)

        self.assertIn("maintained source", reference)
        self.assertIn("deterministic", reference)
        self.assertIn("Do not generate", reference)
        self.assertIn("endpoint-by-endpoint Markdown", reference)

    def test_structured_stack_assigns_workflow_runner_and_glue_roles(
        self,
    ) -> None:
        reference = read(
            API_CONTRACT_ROOT
            / "references"
            / "structured-contract-stack.md"
        )

        for expected in (
            "OpenAPI",
            "Arazzo",
            "Respect",
            "operation IDs",
            "success criteria",
            "runtime inputs",
            "lifecycle glue",
            "process",
            "database",
            "fixture",
            "readiness",
            "cleanup",
        ):
            with self.subTest(expected=expected):
                self.assertIn(expected, reference)

        self.assertIn("must not restate", reference)
        self.assertIn("CLI", reference)
        self.assertIn("deterministic", reference)

    def test_human_ad_hoc_and_gui_surfaces_are_conditional(self) -> None:
        stack = read(
            API_CONTRACT_ROOT
            / "references"
            / "structured-contract-stack.md"
        )
        tools = read(
            API_CONTRACT_ROOT / "references" / "tool-selection.md"
        )

        for expected in (
            "generated HTML",
            "Restish",
            "curl",
            "single-operation",
            "Bruno",
            "Postman",
            "Yaak",
            "GUI collaboration",
        ):
            with self.subTest(expected=expected):
                self.assertIn(expected, stack + tools)

        self.assertIn("named", stack)
        self.assertIn("generated or synchronized projection", stack)
        self.assertIn("never", stack)
        self.assertIn("Do not default to Bruno", tools)

    def test_verification_topology_separates_and_joins_boundaries(self) -> None:
        reference = read(
            API_CONTRACT_ROOT / "references" / "verification-layers.md"
        )

        for expected in (
            "Wire Contract",
            "Provider Conformance",
            "Consumer Adapter",
            "Business Workflow",
            "Critical UI / E2E",
            "Schema compatibility",
            "semantic compatibility",
            "runtime",
        ):
            with self.subTest(expected=expected):
                self.assertIn(expected, reference)

        self.assertIn("fan out", reference)
        self.assertIn("join", reference)

    def test_skill_preserves_single_owner_boundaries(self) -> None:
        skill = read(API_CONTRACT_ROOT / "SKILL.md")

        for expected in (
            "executable-oracle-architecture-selector",
            "testing-strategy",
            "architecture-patterns",
            "lower-plane",
            "lifecycle",
        ):
            with self.subTest(expected=expected):
                self.assertIn(expected, skill)

        self.assertIn("does not own", skill)
        self.assertIn("comprehensive assessment", skill)
        self.assertIn("decision-relevant", skill)

    def test_lifecycle_and_legacy_adoption_are_conditional(self) -> None:
        lifecycle = read(
            API_CONTRACT_ROOT / "references" / "contract-lifecycle.md"
        )
        legacy = read(API_CONTRACT_ROOT / "references" / "legacy-adoption.md")

        for expected in (
            "provider repository",
            "independent contract repository",
            "workspace contract",
            "development",
            "release",
            "generated",
        ):
            with self.subTest(expected=expected):
                self.assertIn(expected, lifecycle)

        for expected in (
            "baseline",
            "lint",
            "compatibility",
            "provider",
            "workflow",
            "consumer",
            "CDC",
        ):
            with self.subTest(expected=expected):
                self.assertIn(expected, legacy)

        self.assertIn("upgrade trigger", lifecycle)
        self.assertIn("Do not rewrite", legacy)
        self.assertIn("bundle", lifecycle)
        self.assertIn("Arazzo", legacy)
        self.assertIn("lifecycle glue", legacy)

    def test_tool_guidance_prices_operations_and_rejects_defaults(self) -> None:
        reference = read(API_CONTRACT_ROOT / "references" / "tool-selection.md")

        for expected in (
            "operational cost",
            "alternative",
            "rejected",
            "upgrade trigger",
            "Pact",
            "Bruno",
            "OpenAPI",
            "generated client",
            "Redocly",
            "Respect",
            "Arazzo",
        ):
            with self.subTest(expected=expected):
                self.assertIn(expected, reference)

        self.assertIn("Do not automatically recommend Pact", reference)
        self.assertIn("Do not create one workflow file per endpoint", reference)

    def test_testing_strategy_maps_boundaries_to_owned_gates(self) -> None:
        skill = read(TESTING_ROOT / "SKILL.md")
        ci_reference = read(TESTING_ROOT / "references" / "ci-config.md")

        self.assertIn(
            "boundary -> oracle -> fixture/environment -> owning suite -> "
            "CI/release lane -> diagnosis owner",
            skill,
        )
        self.assertIn("Carry forward the selected executable oracle", skill)
        self.assertNotIn("Select the executable oracle", skill)
        self.assertIn("missing verification layer", skill)
        self.assertIn("schema compatibility", skill)
        self.assertIn("semantic compatibility", skill)

        for forbidden in (
            "Overall code coverage: ≥ 80%",
            "Critical business logic coverage: ≥ 95%",
            "New feature coverage: ≥ 85%",
            "actions/checkout@",
            "sleep 30",
            "go-version: '1.21'",
        ):
            with self.subTest(forbidden=forbidden):
                self.assertNotIn(forbidden, skill + ci_reference)

        for lane in (
            "Static contract",
            "Compatibility",
            "Provider",
            "Consumer",
            "Workflow",
            "UI / E2E",
            "Runtime",
        ):
            with self.subTest(lane=lane):
                self.assertIn(lane, ci_reference)

    def test_oracle_selector_cross_routes_without_losing_authority(self) -> None:
        selector = read(
            SOURCE_ROOT
            / "executable-oracle-architecture-selector"
            / "SKILL.md"
        )

        self.assertIn("api-contract-strategy", selector)
        self.assertIn("multi-client", selector)
        self.assertIn("retains", selector)
        self.assertIn("oracle", selector)

    def test_manifest_readme_and_generated_surface_are_registered(self) -> None:
        with (REPO_ROOT / "contracts" / "skills.toml").open("rb") as handle:
            manifest = tomllib.load(handle)["skills"]["api-contract-strategy"]

        self.assertEqual(
            manifest["source"],
            "src/skills/disciplines/api-contract-strategy",
        )
        self.assertEqual(manifest["category"], "discipline")
        self.assertEqual(manifest["install"], ["claude", "codex", "root-flat"])
        self.assertFalse(manifest["lifecycle_owner"])
        self.assertTrue(manifest["implicit_invocation"])
        self.assertFalse(manifest["may_mutate_repo"])
        self.assertFalse(manifest["may_spawn_agent"])

        self.assertIn("api-contract-strategy", read(REPO_ROOT / "README.md"))
        generated_root = REPO_ROOT / "skills" / "api-contract-strategy"
        self.assertTrue((generated_root / "SKILL.md").is_file())
        self.assertEqual(
            read(API_CONTRACT_ROOT / "SKILL.md"),
            read(generated_root / "SKILL.md"),
        )
        source_map = json.loads(
            read(REPO_ROOT / "skills" / ".source-map.json")
        )
        self.assertEqual(
            source_map["api-contract-strategy"],
            "src/skills/disciplines/api-contract-strategy",
        )


if __name__ == "__main__":
    unittest.main()
