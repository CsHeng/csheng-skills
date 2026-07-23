from __future__ import annotations

import contextlib
import importlib.util
import io
import json
from pathlib import Path
import sys
import tempfile
from types import ModuleType
import unittest
from unittest import mock


REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = (
    REPO_ROOT
    / "src"
    / "skills"
    / "tools"
    / "codex-session-recovery"
    / "scripts"
    / "merge-codex-sessions.py"
)


def load_script() -> ModuleType:
    """Load the session recovery script as a testable module."""

    spec = importlib.util.spec_from_file_location(
        "codex_session_recovery_merge", SCRIPT_PATH
    )
    if spec is None or spec.loader is None:
        raise RuntimeError(f"failed to load {SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


RECOVERY = load_script()


def make_home(root: Path, name: str) -> Path:
    """Create a minimal Codex home with a sessions directory."""

    home = root / name
    (home / "sessions").mkdir(parents=True)
    return home


def write_session(
    home: Path, relative_path: str, records: list[dict[str, object]]
) -> Path:
    """Write a valid session JSONL fixture and return its path."""

    session_path = home / "sessions" / relative_path
    session_path.parent.mkdir(parents=True, exist_ok=True)
    payload = "".join(json.dumps(record, sort_keys=True) + "\n" for record in records)
    session_path.write_text(payload, encoding="utf-8")
    return session_path


def run_cli(arguments: list[str]) -> tuple[int, str, str]:
    """Run the CLI without leaking expected diagnostic output into test logs."""

    stdout = io.StringIO()
    stderr = io.StringIO()
    with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
        exit_code = RECOVERY.main(arguments)
    return exit_code, stdout.getvalue(), stderr.getvalue()


class CodexSessionRecoveryTests(unittest.TestCase):
    """Protect the file-only, conflict-safe Codex session merge contract."""

    def test_dry_run_then_apply_merges_prefix_chain_without_touching_sqlite(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source_a = make_home(root, "source-a")
            source_b = make_home(root, "source-b")
            destination = make_home(root, "destination")
            report = root / "reports" / "merge.json"
            backup = root / "backup"

            identical = "2026/07/01/rollout-identical.jsonl"
            add = "2026/07/02/rollout-add.jsonl"
            extend = "2026/07/03/rollout-extend.jsonl"
            destination_newer = "2026/07/04/rollout-destination-newer.jsonl"

            write_session(source_a, identical, [{"event": 1}])
            write_session(source_a, add, [{"added": True}])
            write_session(source_a, extend, [{"step": 1}, {"step": 2}])
            write_session(source_a, destination_newer, [{"step": 1}])
            write_session(
                source_b,
                extend,
                [{"step": 1}, {"step": 2}, {"step": 3}],
            )

            write_session(destination, identical, [{"event": 1}])
            shorter_path = write_session(destination, extend, [{"step": 1}])
            shorter_payload = shorter_path.read_bytes()
            write_session(
                destination,
                destination_newer,
                [{"step": 1}, {"step": 2}],
            )
            sqlite_path = destination / "state_5.sqlite"
            sqlite_payload = b"opaque sqlite sentinel\x00\xff"
            sqlite_path.write_bytes(sqlite_payload)

            base_arguments = [
                "--source-home",
                str(source_a),
                "--source-home",
                str(source_b),
                "--destination-home",
                str(destination),
                "--report",
                str(report),
            ]

            exit_code, _, stderr = run_cli(base_arguments)

            self.assertEqual(0, exit_code, stderr)
            self.assertFalse((destination / "sessions" / add).exists())
            self.assertEqual(shorter_payload, shorter_path.read_bytes())
            dry_run_report = json.loads(report.read_text(encoding="utf-8"))
            self.assertFalse(dry_run_report["applied"])
            self.assertEqual(
                {
                    "add": 1,
                    "destination_is_newer": 1,
                    "extend_destination": 1,
                    "identical": 1,
                },
                dry_run_report["counts"],
            )

            exit_code, stdout, stderr = run_cli(
                base_arguments
                + [
                    "--backup-dir",
                    str(backup),
                    "--confirm-all-homes-inactive",
                    "--apply",
                ]
            )

            self.assertEqual(0, exit_code, stderr)
            self.assertIn('"applied": true', stdout)
            self.assertEqual(
                (source_a / "sessions" / add).read_bytes(),
                (destination / "sessions" / add).read_bytes(),
            )
            self.assertEqual(
                (source_b / "sessions" / extend).read_bytes(),
                shorter_path.read_bytes(),
            )
            self.assertEqual(
                shorter_payload,
                (backup / "replaced-prefix" / extend).read_bytes(),
            )
            self.assertEqual(sqlite_payload, sqlite_path.read_bytes())
            applied_report = json.loads(report.read_text(encoding="utf-8"))
            self.assertTrue(applied_report["applied"])

    def test_non_prefix_source_conflict_blocks_every_destination_write(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source_a = make_home(root, "source-a")
            source_b = make_home(root, "source-b")
            destination = make_home(root, "destination")
            conflict = "2026/07/01/rollout-conflict.jsonl"
            add = "2026/07/02/rollout-add.jsonl"
            report = root / "merge.json"

            write_session(source_a, conflict, [{"branch": "a"}])
            write_session(source_b, conflict, [{"branch": "b"}])
            write_session(source_a, add, [{"safe": "only without conflict"}])

            exit_code, _, stderr = run_cli(
                [
                    "--source-home",
                    str(source_a),
                    "--source-home",
                    str(source_b),
                    "--destination-home",
                    str(destination),
                    "--report",
                    str(report),
                    "--backup-dir",
                    str(root / "backup"),
                    "--confirm-all-homes-inactive",
                    "--apply",
                ]
            )

            self.assertEqual(RECOVERY.CONFLICT_EXIT_CODE, exit_code)
            self.assertIn("merge blocked", stderr)
            self.assertFalse((destination / "sessions" / add).exists())
            result = json.loads(report.read_text(encoding="utf-8"))
            self.assertFalse(result["applied"])
            self.assertEqual("conflict", result["status"])
            self.assertEqual(1, result["counts"]["conflict"])
            conflict_decision = next(
                decision
                for decision in result["decisions"]
                if decision["relative_path"] == conflict
            )
            self.assertEqual(2, len(conflict_decision["source_variants"]))
            self.assertEqual(
                2,
                len(
                    {
                        variant["sha256"]
                        for variant in conflict_decision["source_variants"]
                    }
                ),
            )

    def test_apply_requires_explicit_inactive_confirmation(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source = make_home(root, "source")
            destination = make_home(root, "destination")
            relative_path = "2026/07/01/rollout-add.jsonl"
            write_session(source, relative_path, [{"event": 1}])

            exit_code, _, stderr = run_cli(
                [
                    "--source-home",
                    str(source),
                    "--destination-home",
                    str(destination),
                    "--report",
                    str(root / "merge.json"),
                    "--backup-dir",
                    str(root / "backup"),
                    "--apply",
                ]
            )

            self.assertEqual(RECOVERY.ERROR_EXIT_CODE, exit_code)
            self.assertIn("--confirm-all-homes-inactive", stderr)
            self.assertFalse((destination / "sessions" / relative_path).exists())

    def test_malformed_jsonl_and_symlink_entries_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            malformed_source = make_home(root, "malformed-source")
            destination = make_home(root, "destination")
            malformed_path = (
                malformed_source / "sessions" / "2026/07/01/rollout-malformed.jsonl"
            )
            malformed_path.parent.mkdir(parents=True)
            malformed_path.write_text(
                '{"valid": true}\n{"truncated":', encoding="utf-8"
            )

            exit_code, _, stderr = run_cli(
                [
                    "--source-home",
                    str(malformed_source),
                    "--destination-home",
                    str(destination),
                    "--report",
                    str(root / "malformed.json"),
                ]
            )

            self.assertEqual(RECOVERY.ERROR_EXIT_CODE, exit_code)
            self.assertIn("invalid JSONL record", stderr)

            symlink_source = make_home(root, "symlink-source")
            real_session = write_session(
                symlink_source,
                "2026/07/02/rollout-real.jsonl",
                [{"event": 1}],
            )
            symlink_path = real_session.with_name("rollout-link.jsonl")
            try:
                symlink_path.symlink_to(real_session)
            except OSError as error:
                self.skipTest(f"symlinks unavailable: {error}")

            exit_code, _, stderr = run_cli(
                [
                    "--source-home",
                    str(symlink_source),
                    "--destination-home",
                    str(destination),
                    "--report",
                    str(root / "symlink.json"),
                ]
            )

            self.assertEqual(RECOVERY.ERROR_EXIT_CODE, exit_code)
            self.assertIn("symlink", stderr)

    def test_destination_change_after_audit_aborts_before_merge(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source = make_home(root, "source")
            destination = make_home(root, "destination")
            relative_path = "2026/07/01/rollout-extend.jsonl"
            write_session(source, relative_path, [{"step": 1}, {"step": 2}])
            destination_path = write_session(destination, relative_path, [{"step": 1}])
            original_verify = RECOVERY.verify_snapshot_unchanged
            expected_destination_root = (destination / "sessions").resolve()
            mutated = False

            def mutate_before_verify(snapshot: object) -> None:
                nonlocal mutated
                snapshot_root = getattr(snapshot, "root")
                if snapshot_root == expected_destination_root and not mutated:
                    write_session(destination, relative_path, [{"raced": True}])
                    mutated = True
                original_verify(snapshot)

            with mock.patch.object(
                RECOVERY,
                "verify_snapshot_unchanged",
                side_effect=mutate_before_verify,
            ):
                exit_code, _, stderr = run_cli(
                    [
                        "--source-home",
                        str(source),
                        "--destination-home",
                        str(destination),
                        "--report",
                        str(root / "merge.json"),
                        "--backup-dir",
                        str(root / "backup"),
                        "--confirm-all-homes-inactive",
                        "--apply",
                    ]
                )

            self.assertEqual(RECOVERY.ERROR_EXIT_CODE, exit_code)
            self.assertIn("changed after audit", stderr)
            self.assertEqual(
                [{"raced": True}],
                [
                    json.loads(line)
                    for line in destination_path.read_text().splitlines()
                ],
            )
            self.assertFalse(
                (root / "backup" / "replaced-prefix" / relative_path).exists()
            )

    def test_added_file_is_removed_when_post_link_fsync_fails(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source = make_home(root, "source")
            destination = make_home(root, "destination")
            relative_path = "2026/07/01/rollout-add.jsonl"
            source_path = write_session(source, relative_path, [{"event": 1}])
            destination_path = destination / "sessions" / relative_path
            destination_parent = destination_path.parent.resolve()
            expected_payload = source_path.read_bytes()
            original_fsync = RECOVERY.fsync_directory
            failed = False

            def fail_after_link(directory: Path) -> None:
                nonlocal failed
                if (
                    directory.resolve() == destination_parent
                    and destination_path.exists()
                    and destination_path.read_bytes() == expected_payload
                    and not failed
                ):
                    failed = True
                    raise OSError("simulated post-link fsync failure")
                original_fsync(directory)

            with mock.patch.object(
                RECOVERY,
                "fsync_directory",
                side_effect=fail_after_link,
            ):
                exit_code, _, stderr = run_cli(
                    [
                        "--source-home",
                        str(source),
                        "--destination-home",
                        str(destination),
                        "--report",
                        str(root / "merge.json"),
                        "--backup-dir",
                        str(root / "backup"),
                        "--confirm-all-homes-inactive",
                        "--apply",
                    ]
                )

            self.assertTrue(failed)
            self.assertEqual(RECOVERY.ERROR_EXIT_CODE, exit_code)
            self.assertIn("rolled back", stderr)
            self.assertFalse(destination_path.exists())

    def test_extended_file_is_restored_when_post_replace_fsync_fails(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source = make_home(root, "source")
            destination = make_home(root, "destination")
            relative_path = "2026/07/01/rollout-extend.jsonl"
            source_path = write_session(
                source,
                relative_path,
                [{"step": 1}, {"step": 2}],
            )
            destination_path = write_session(destination, relative_path, [{"step": 1}])
            original_payload = destination_path.read_bytes()
            extended_payload = source_path.read_bytes()
            destination_parent = destination_path.parent.resolve()
            original_fsync = RECOVERY.fsync_directory
            failed = False

            def fail_after_replace(directory: Path) -> None:
                nonlocal failed
                if (
                    directory.resolve() == destination_parent
                    and destination_path.read_bytes() == extended_payload
                    and not failed
                ):
                    failed = True
                    raise OSError("simulated post-replace fsync failure")
                original_fsync(directory)

            with mock.patch.object(
                RECOVERY,
                "fsync_directory",
                side_effect=fail_after_replace,
            ):
                exit_code, _, stderr = run_cli(
                    [
                        "--source-home",
                        str(source),
                        "--destination-home",
                        str(destination),
                        "--report",
                        str(root / "merge.json"),
                        "--backup-dir",
                        str(root / "backup"),
                        "--confirm-all-homes-inactive",
                        "--apply",
                    ]
                )

            self.assertTrue(failed)
            self.assertEqual(RECOVERY.ERROR_EXIT_CODE, exit_code)
            self.assertIn("rolled back", stderr)
            self.assertEqual(original_payload, destination_path.read_bytes())

    def test_prefix_open_failure_closes_first_descriptor(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source = make_home(root, "source")
            shorter_path = write_session(source, "short.jsonl", [{"step": 1}])
            longer_path = write_session(
                source,
                "long.jsonl",
                [{"step": 1}, {"step": 2}],
            )
            shorter = RECOVERY.ObservedFile(
                home=source,
                path=shorter_path,
                evidence=RECOVERY.validate_jsonl(shorter_path),
            )
            longer = RECOVERY.ObservedFile(
                home=source,
                path=longer_path,
                evidence=RECOVERY.validate_jsonl(longer_path),
            )

            with (
                mock.patch.object(
                    RECOVERY.os,
                    "open",
                    side_effect=[123, OSError("second open failed")],
                ),
                mock.patch.object(RECOVERY.os, "close") as close_descriptor,
            ):
                with self.assertRaisesRegex(OSError, "second open failed"):
                    RECOVERY.is_prefix(shorter, longer)

            close_descriptor.assert_called_once_with(123)

    def test_destination_only_missing_sessions_and_output_boundaries(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source = make_home(root, "source")
            destination = root / "destination"
            destination.mkdir()
            write_session(source, "2026/07/01/rollout-add.jsonl", [{"event": 1}])

            exit_code, _, stderr = run_cli(
                [
                    "--source-home",
                    str(source),
                    "--destination-home",
                    str(destination),
                    "--report",
                    str(root / "merge.json"),
                    "--backup-dir",
                    str(root / "backup"),
                    "--confirm-all-homes-inactive",
                    "--apply",
                ]
            )

            self.assertEqual(0, exit_code, stderr)
            self.assertTrue(
                (destination / "sessions/2026/07/01/rollout-add.jsonl").is_file()
            )

            output_inside_sessions = source / "sessions" / "audit.json"
            exit_code, _, stderr = run_cli(
                [
                    "--source-home",
                    str(source),
                    "--destination-home",
                    str(destination),
                    "--report",
                    str(output_inside_sessions),
                ]
            )

            self.assertEqual(RECOVERY.ERROR_EXIT_CODE, exit_code)
            self.assertIn("outside sessions trees", stderr)
            self.assertFalse(output_inside_sessions.exists())

    def test_duplicate_homes_missing_backup_and_empty_jsonl_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source = make_home(root, "source")
            destination = make_home(root, "destination")
            write_session(source, "valid.jsonl", [{"event": 1}])

            exit_code, _, stderr = run_cli(
                [
                    "--source-home",
                    str(source),
                    "--source-home",
                    str(source),
                    "--destination-home",
                    str(destination),
                    "--report",
                    str(root / "duplicate.json"),
                ]
            )
            self.assertEqual(RECOVERY.ERROR_EXIT_CODE, exit_code)
            self.assertIn("source homes must be unique", stderr)

            exit_code, _, stderr = run_cli(
                [
                    "--source-home",
                    str(source),
                    "--destination-home",
                    str(destination),
                    "--report",
                    str(root / "missing-backup.json"),
                    "--confirm-all-homes-inactive",
                    "--apply",
                ]
            )
            self.assertEqual(RECOVERY.ERROR_EXIT_CODE, exit_code)
            self.assertIn("--backup-dir", stderr)

            empty_source = make_home(root, "empty-source")
            (empty_source / "sessions" / "empty.jsonl").touch()
            exit_code, _, stderr = run_cli(
                [
                    "--source-home",
                    str(empty_source),
                    "--destination-home",
                    str(destination),
                    "--report",
                    str(root / "empty.json"),
                ]
            )
            self.assertEqual(RECOVERY.ERROR_EXIT_CODE, exit_code)
            self.assertIn("empty JSONL session", stderr)


if __name__ == "__main__":
    unittest.main()
