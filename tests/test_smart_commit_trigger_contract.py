from __future__ import annotations

import tomllib
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


class SmartCommitTriggerContractTest(unittest.TestCase):
    def test_contract_allows_intent_gated_model_selection(self) -> None:
        with (REPO_ROOT / "contracts" / "skills.toml").open("rb") as handle:
            contract = tomllib.load(handle)["skills"]["smart-commit"]

        self.assertEqual(contract["category"], "tool")
        self.assertTrue(contract["implicit_invocation"])
        self.assertTrue(contract["requires_explicit_user_request"])

    def test_description_requires_grouping_and_commit_intent(self) -> None:
        skill = (REPO_ROOT / "src" / "skills" / "git" / "smart-commit" / "SKILL.md").read_text(encoding="utf-8")

        self.assertIn("group current working-tree diffs by business domain or purpose", skill)
        self.assertIn("create focused local commits", skill)
        self.assertIn(
            "Do not use for a generic commit request, diff inspection, status reporting, or history cleanup.",
            skill,
        )

    def test_openai_policy_allows_implicit_invocation(self) -> None:
        metadata = (
            REPO_ROOT / "src" / "skills" / "git" / "smart-commit" / "agents" / "openai.yaml"
        ).read_text(encoding="utf-8")

        self.assertIn("allow_implicit_invocation: true", metadata)


if __name__ == "__main__":
    unittest.main()
