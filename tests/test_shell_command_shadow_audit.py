from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = (
    REPO_ROOT
    / "src"
    / "skills"
    / "policies"
    / "shell-guidelines"
    / "scripts"
    / "audit-homebrew-command-shadowing.py"
)
SPEC = importlib.util.spec_from_file_location(
    "audit_homebrew_command_shadowing", SCRIPT_PATH
)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"failed to load {SCRIPT_PATH}")
AUDIT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(AUDIT)


def write_executable(candidate_path: Path) -> None:
    candidate_path.parent.mkdir(parents=True, exist_ok=True)
    candidate_path.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
    candidate_path.chmod(0o755)


class HomebrewCommandShadowAuditTests(unittest.TestCase):
    def test_audit_reports_shadows_duplicates_and_effective_provider(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            coreutils = root / "opt" / "coreutils" / "libexec" / "gnubin"
            findutils = root / "opt" / "findutils" / "libexec" / "gnubin"
            system_dir = root / "system"

            for command_path in (
                coreutils / "gstat",
                coreutils / "shared-tool",
                coreutils / "stat",
                findutils / "shared-tool",
                system_dir / "stat",
            ):
                write_executable(command_path)

            path_value = ":".join((str(coreutils), str(findutils), str(system_dir)))
            report = AUDIT.audit_path(path_value, (system_dir,))

            self.assertEqual(2, report["path_gnubin_dirs"])
            self.assertEqual(3, report["unique_commands"])
            self.assertEqual(1, report["system_shadow_count"])
            self.assertEqual(2, report["gnubin_only_count"])
            self.assertEqual(1, report["duplicate_provider_count"])
            self.assertEqual(
                ["coreutils", "findutils"],
                [item["formula"] for item in report["directories"]],
            )

            shadow = report["system_shadows"][0]
            self.assertEqual("stat", shadow["name"])
            self.assertEqual(str(coreutils / "stat"), shadow["effective"])
            self.assertEqual([str(system_dir / "stat")], shadow["system_candidates"])

            duplicate = report["duplicates"][0]
            self.assertEqual("shared-tool", duplicate["name"])
            self.assertEqual(
                [str(coreutils / "shared-tool"), str(findutils / "shared-tool")],
                duplicate["providers"],
            )

    def test_cli_emits_machine_readable_compact_json(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            gnubin_dir = root / "opt" / "coreutils" / "libexec" / "gnubin"
            system_dir = root / "system"
            write_executable(gnubin_dir / "ls")
            write_executable(system_dir / "ls")

            stdout = io.StringIO()
            with contextlib.redirect_stdout(stdout):
                exit_code = AUDIT.main(
                    [
                        "--path",
                        str(gnubin_dir),
                        "--system-dir",
                        str(system_dir),
                        "--compact",
                    ]
                )

            self.assertEqual(0, exit_code)
            self.assertNotIn("\n  ", stdout.getvalue())
            report = json.loads(stdout.getvalue())
            self.assertEqual(1, report["schema_version"])
            self.assertEqual(1, report["system_shadow_count"])


if __name__ == "__main__":
    unittest.main()
