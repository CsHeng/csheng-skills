from __future__ import annotations

import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = REPO_ROOT / "src" / "skills"


def read(relative_path: str) -> str:
    return (SOURCE_ROOT / relative_path).read_text(encoding="utf-8")


class SkillOutputContractTests(unittest.TestCase):
    def test_output_styles_owns_composition_baseline(self) -> None:
        skill = read("session/output-styles/SKILL.md")

        self.assertIn("exactly one primary skill", skill)
        self.assertIn("shared conversational rendering baseline", skill)
        self.assertIn("semantic overlay", skill)
        self.assertIn("must not emit a second report template", skill)

    def test_analyze_project_defaults_to_selective_terse_output(self) -> None:
        skill = read("workflows/analyze-project/SKILL.md")
        contract = read("workflows/analyze-project/references/output-contract.md")

        self.assertIn("selective terse output by default", skill)
        self.assertIn("## Default: Selective Terse", contract)
        self.assertIn("They are not mandatory headings", contract)
        self.assertNotIn("## Required Sections", contract)

    def test_analyze_project_full_audit_is_explicit_and_progressive(self) -> None:
        skill = read("workflows/analyze-project/SKILL.md")
        contract = read("workflows/analyze-project/references/output-contract.md")
        audit = read("workflows/analyze-project/references/full-audit-output.md")

        self.assertIn("only for an explicit comprehensive project truth audit", skill)
        self.assertIn("only when the user explicitly requests", contract)
        self.assertIn("A degraded or untrusted document-health result does not by itself", contract)
        self.assertIn("## Semantic Sections", audit)

    def test_analyze_project_yields_output_shape_to_domain_owner(self) -> None:
        skill = read("workflows/analyze-project/SKILL.md")
        contract = read("workflows/analyze-project/references/output-contract.md")

        self.assertIn("matching domain skill as response owner", skill)
        self.assertIn("do not render a standalone project report", contract)

    def test_oracle_selector_exposes_semantics_without_fixed_report_template(self) -> None:
        skill = read("disciplines/executable-oracle-architecture-selector/SKILL.md")

        self.assertIn("preserve these semantic results", skill)
        self.assertIn("as a semantic overlay", skill)
        self.assertIn("Avoid generic coverage advice and empty template sections", skill)
        self.assertNotIn("When using this skill, answer in this structure", skill)


if __name__ == "__main__":
    unittest.main()
