from __future__ import annotations

import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SKILL_ROOT = REPO_ROOT / "src" / "skills"


def read_skill(relative_path: str) -> str:
    return (SKILL_ROOT / relative_path).read_text(encoding="utf-8")


class PythonMaintenanceCharacterizationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.skill = read_skill("policies/python-guidelines/SKILL.md")

    def test_project_toolchain_remains_uv_owned(self) -> None:
        for expected in (
            "Package/dependency management: `uv`",
            "Configuration SSOT: `pyproject.toml`",
            "Formatting + linting: `ruff`",
            "Testing: `pytest`",
            "Type checking: `ty`",
        ):
            with self.subTest(expected=expected):
                self.assertIn(expected, self.skill)

    def test_project_and_dependency_preflight_remain_explicit(self) -> None:
        self.assertIn("uv run --project <project-root>", self.skill)
        self.assertIn("### pytest Dependency Preflight", self.skill)
        self.assertIn("pytest-cov", self.skill)
        self.assertIn("nearest owning Python project", self.skill)

    def test_cache_isolation_contract_remains_explicit(self) -> None:
        for variable in (
            "PYTHONDONTWRITEBYTECODE",
            "PYTHONPYCACHEPREFIX",
            "RUFF_CACHE_DIR",
            "UV_PROJECT_ENVIRONMENT",
        ):
            with self.subTest(variable=variable):
                self.assertIn(variable, self.skill)


class PlanTimeLanguageRoutingContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.language_skill = read_skill(
            "disciplines/language-decision-tree/SKILL.md"
        )
        cls.plan_skill = read_skill("workflows/plan-change/SKILL.md")
        cls.session_skill = read_skill("session/use-coding-skills/SKILL.md")
        cls.routing_reference = read_skill(
            "session/use-coding-skills/references/routing.md"
        )

    def test_language_selection_is_for_new_persisted_boundaries(self) -> None:
        self.assertIn("persisted", self.language_skill)
        self.assertIn("design or planning", self.language_skill)
        self.assertIn("new project", self.language_skill)
        self.assertIn("approved migration", self.language_skill)

    def test_ad_hoc_command_choice_is_an_explicit_non_trigger(self) -> None:
        self.assertIn("ad hoc command", self.language_skill)
        self.assertIn("tool-decision-tree", self.language_skill)

    def test_plan_records_conditional_implementation_decisions(self) -> None:
        self.assertIn("language-decision-tree", self.plan_skill)
        for field in (
            "implementation_archetype",
            "implementation_language",
            "language_rationale",
        ):
            with self.subTest(field=field):
                self.assertIn(field, self.plan_skill)
        self.assertIn("only when", self.plan_skill)

    def test_session_routing_distinguishes_persisted_from_ad_hoc(self) -> None:
        for document in (self.session_skill, self.routing_reference):
            with self.subTest(document=document[:40]):
                self.assertIn("persisted", document)
                self.assertIn("ad hoc", document)


class AdHocCompositionAndShellEscalationContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.tool_skill = read_skill("disciplines/tool-decision-tree/SKILL.md")
        cls.tool_reference_path = (
            SKILL_ROOT
            / "disciplines"
            / "tool-decision-tree"
            / "references"
            / "adhoc-command-composition.md"
        )
        cls.shell_skill = read_skill("policies/shell-guidelines/SKILL.md")
        cls.shell_patterns = read_skill(
            "policies/shell-guidelines/references/script-patterns.md"
        )
        cls.python_skill = read_skill("policies/python-guidelines/SKILL.md")

    def test_tool_decision_owns_ad_hoc_composition(self) -> None:
        self.assertIn("ad hoc", self.tool_skill)
        self.assertIn("references/adhoc-command-composition.md", self.tool_skill)
        self.assertTrue(self.tool_reference_path.is_file())

    def test_nested_interpreters_are_avoided_not_blanket_forbidden(self) -> None:
        reference = self.tool_reference_path.read_text(encoding="utf-8")
        self.assertIn("AVOID", reference)
        self.assertIn("bash -c", reference)
        self.assertIn("python -c", reference)
        self.assertIn("scratch", reference)
        self.assertNotIn("PROHIBITED: Use `bash -c`", reference)

    def test_hard_safety_boundary_is_narrow(self) -> None:
        reference = self.tool_reference_path.read_text(encoding="utf-8")
        self.assertIn("untrusted", reference)
        self.assertIn("irreversible", reference)
        self.assertIn("COUNT", reference)
        self.assertIn("PREVIEW", reference)
        prohibitions = [
            line for line in reference.splitlines() if line.startswith("PROHIBITED:")
        ]
        self.assertEqual(2, len(prohibitions), prohibitions)

    def test_shell_escalation_is_language_neutral_with_go_preference(self) -> None:
        combined = self.shell_skill + self.shell_patterns
        self.assertNotIn("delegate to Python", combined)
        self.assertNotIn("move logic into Python", combined)
        self.assertIn("language-decision-tree", combined)
        self.assertIn("Prefer Go", combined)
        self.assertIn("persistent state", combined)

    def test_python_fallback_example_uses_external_scratch_script(self) -> None:
        self.assertNotIn("uvx --with pyyaml python3 - <<'PY'", self.python_skill)
        self.assertIn("scratch", self.python_skill)
        self.assertIn("uvx --with pyyaml python3", self.python_skill)


class GoPurposeProfileContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.go_root = SKILL_ROOT / "policies" / "go-guidelines"
        cls.skill = (cls.go_root / "SKILL.md").read_text(encoding="utf-8")
        cls.cli_path = cls.go_root / "references" / "cli-tool-patterns.md"
        cls.api_path = cls.go_root / "references" / "api-service-patterns.md"
        cls.review = (cls.go_root / "references" / "review-checklist.md").read_text(
            encoding="utf-8"
        )

    def test_progressive_disclosure_has_two_purpose_profiles(self) -> None:
        self.assertIn("references/cli-tool-patterns.md", self.skill)
        self.assertIn("references/api-service-patterns.md", self.skill)
        self.assertTrue(self.cli_path.is_file())
        self.assertTrue(self.api_path.is_file())

    def test_shared_baseline_uses_standard_toolchain_defaults(self) -> None:
        for expected in ("gofmt", "go vet ./...", "go test ./...", "tool directive"):
            with self.subTest(expected=expected):
                self.assertIn(expected, self.skill)
        self.assertNotIn("Use `golangci-lint` for code quality checks", self.skill)
        self.assertIn("when configured", self.skill)

    def test_errors_and_interfaces_are_conditional(self) -> None:
        self.assertIn("errors.Is", self.skill)
        self.assertIn("errors.As", self.skill)
        self.assertIn("only when", self.skill)

    def test_cli_profile_covers_selection_architecture_and_delivery(self) -> None:
        cli = self.cli_path.read_text(encoding="utf-8")
        for expected in (
            "standard library `flag`",
            "Cobra",
            "completion",
            "stdout",
            "stderr",
            "log/slog",
            "dry-run",
            "go build",
        ):
            with self.subTest(expected=expected):
                self.assertIn(expected, cli)

    def test_api_profile_covers_server_lifecycle_and_testing(self) -> None:
        api = self.api_path.read_text(encoding="utf-8")
        for expected in (
            "net/http",
            "existing framework",
            "timeouts",
            "graceful shutdown",
            "health",
            "readiness",
            "httptest",
        ):
            with self.subTest(expected=expected):
                self.assertIn(expected, api)

    def test_review_selects_the_matching_profile(self) -> None:
        self.assertIn("cli-tool-patterns.md", self.review)
        self.assertIn("api-service-patterns.md", self.review)
        self.assertIn("archetype", self.review)


class StableRoutingTruthTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.agents = (REPO_ROOT / "AGENTS.md").read_text(encoding="utf-8")
        cls.readme = (REPO_ROOT / "README.md").read_text(encoding="utf-8")
        cls.workflow = (
            REPO_ROOT / "docs" / "architecture" / "workflow-orchestration.md"
        ).read_text(encoding="utf-8")

    def test_root_routing_separates_persisted_and_ad_hoc_decisions(self) -> None:
        for document in (self.agents, self.readme):
            with self.subTest(document=document[:40]):
                self.assertIn("persisted implementation", document)
                self.assertIn("ad hoc command", document)

    def test_readme_describes_go_purpose_profiles(self) -> None:
        self.assertIn("CLI-tool and API-service", self.readme)
        self.assertNotIn("gofmt, golangci-lint, service patterns", self.readme)

    def test_workflow_records_conditional_plan_policy_overlay(self) -> None:
        self.assertIn("language-decision-tree", self.workflow)
        self.assertIn("tool-decision-tree", self.workflow)
        self.assertIn("persisted implementation", self.workflow)


if __name__ == "__main__":
    unittest.main()
