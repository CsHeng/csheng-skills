from __future__ import annotations

import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SKILL_ROOT = REPO_ROOT / "src" / "skills"


def read_skill(relative_path: str) -> str:
    return (SKILL_ROOT / relative_path).read_text(encoding="utf-8")


class ArchitectureEconomicsContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.architecture_root = (
            SKILL_ROOT / "disciplines" / "architecture-patterns"
        )
        cls.architecture_skill = read_skill(
            "disciplines/architecture-patterns/SKILL.md"
        )
        cls.design_skill = read_skill("workflows/design-change/SKILL.md")
        cls.plan_skill = read_skill("workflows/plan-change/SKILL.md")
        cls.review_design = read_skill(
            "review-components/review-design/SKILL.md"
        )
        cls.review_plan = read_skill("review-components/review-plan/SKILL.md")

    def test_architecture_selector_uses_progressive_disclosure(self) -> None:
        for reference in (
            "references/architecture-decision-economics.md",
            "references/architecture-pattern-catalog.md",
            "references/interface-and-domain-language.md",
        ):
            with self.subTest(reference=reference):
                self.assertIn(reference, self.architecture_skill)
                self.assertTrue((self.architecture_root / reference).is_file())

        for theory_heading in (
            "## Marginal Cost",
            "## Opportunity Cost",
            "## Incentives",
            "## Comparative Advantage",
            "## Supply And Demand",
        ):
            with self.subTest(theory_heading=theory_heading):
                self.assertNotIn(theory_heading, self.architecture_skill)

        for long_reference in (
            "architecture-decision-economics.md",
            "architecture-pattern-catalog.md",
        ):
            with self.subTest(long_reference=long_reference):
                content = (
                    self.architecture_root / "references" / long_reference
                ).read_text(encoding="utf-8")
                self.assertIn("## Contents", content)

    def test_economics_reference_carries_theory_and_decision_evidence(self) -> None:
        reference = (
            self.architecture_root
            / "references"
            / "architecture-decision-economics.md"
        ).read_text(encoding="utf-8")

        for expected in (
            "## Marginal Cost",
            "## Opportunity Cost",
            "## Incentives",
            "## Comparative Advantage",
            "## Supply And Demand",
            "demand_evidence",
            "scarce_resource",
            "marginal_tradeoff",
            "opportunity_cost",
            "owner_and_incentives",
            "comparative_advantage",
            "upgrade_trigger",
        ):
            with self.subTest(expected=expected):
                self.assertIn(expected, reference)

        self.assertIn("status quo", reference)
        self.assertIn("smallest sufficient", reference)
        self.assertIn("structural investment", reference)
        self.assertIn("false precision", reference)

    def test_architecture_skill_defaults_to_demand_first_selection(self) -> None:
        for expected in (
            "smallest sufficient architecture",
            "current demand",
            "constrained resource",
            "observable upgrade trigger",
        ):
            with self.subTest(expected=expected):
                self.assertIn(expected, self.architecture_skill)

    def test_design_conditionally_owns_architecture_economics(self) -> None:
        for expected in (
            "Architecture Decision Economics",
            "architecture-patterns",
            "persisted architecture boundary",
            "ordinary existing-boundary edits",
        ):
            with self.subTest(expected=expected):
                self.assertIn(expected, self.design_skill)

    def test_plan_consumes_without_rescoring_the_approved_decision(self) -> None:
        for expected in (
            "approved architecture decision",
            "architecture_decision_ref",
            "reversible increments",
            "upgrade triggers",
            "Do not rescore or reopen",
        ):
            with self.subTest(expected=expected):
                self.assertIn(expected, self.plan_skill)

    def test_review_boundaries_separate_selection_from_plan_fidelity(self) -> None:
        for expected in (
            "demand-complexity",
            "smallest sufficient option",
            "owner-cost",
            "numeric scoring",
        ):
            with self.subTest(expected=expected):
                self.assertIn(expected, self.review_design)

        for expected in (
            "approved architecture decision",
            "reversible staging",
            "upgrade triggers",
            "Do not rerun or rescore architecture selection",
        ):
            with self.subTest(expected=expected):
                self.assertIn(expected, self.review_plan)


if __name__ == "__main__":
    unittest.main()
