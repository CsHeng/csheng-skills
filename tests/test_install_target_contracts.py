"""Contract tests for generated install-surface destination resolution."""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path
from types import ModuleType


REPO_ROOT = Path(__file__).resolve().parents[1]


def load_script(module_name: str, script_name: str) -> ModuleType:
    """Load a repository script as a testable module."""
    spec = importlib.util.spec_from_file_location(
        module_name, REPO_ROOT / "scripts" / script_name
    )
    if spec is None or spec.loader is None:
        raise RuntimeError(f"failed to load scripts/{script_name}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


FLATTEN_SKILLS = load_script("flatten_skills", "flatten-skills.py")
CHECK_INSTALL_SURFACE = load_script("check_install_surface", "check-install-surface.py")


class InstallTargetContractTests(unittest.TestCase):
    """Keep generator and validator defaults aligned with install-target contracts."""

    def test_external_default_destinations_resolve_under_dist(self) -> None:
        expected_destinations = {
            "claude": REPO_ROOT / ".dist/claude",
            "codex": REPO_ROOT / ".dist/codex",
        }

        for target_name, expected_destination in expected_destinations.items():
            with self.subTest(target=target_name):
                resolved_destination = expected_destination.resolve()
                self.assertEqual(
                    resolved_destination,
                    FLATTEN_SKILLS.target_dest(target_name, None),
                )
                self.assertEqual(
                    resolved_destination,
                    CHECK_INSTALL_SURFACE.target_dest(target_name, None),
                )


if __name__ == "__main__":
    unittest.main()
