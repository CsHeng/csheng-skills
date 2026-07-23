#!/usr/bin/env python3
"""Report Homebrew gnubin commands that shadow macOS system commands."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
from collections import defaultdict
from collections.abc import Sequence
from pathlib import Path
from typing import TypedDict


DEFAULT_SYSTEM_DIRS = (
    Path("/usr/bin"),
    Path("/bin"),
    Path("/usr/sbin"),
    Path("/sbin"),
)
JSON_INDENT_SPACES = 2


class AuditError(RuntimeError):
    """Raised when a PATH directory cannot be inspected safely."""


class DirectoryRecord(TypedDict):
    """Summary of one Homebrew gnubin directory on PATH."""

    path: str
    formula: str
    command_count: int
    commands: list[str]


class CommandRecord(TypedDict):
    """Provider and shadow information for one command name."""

    name: str
    effective: str
    providers: list[str]
    system_candidates: list[str]
    shadows_system: bool


class AuditReport(TypedDict):
    """Machine-readable command-shadow audit report."""

    schema_version: int
    path_gnubin_dirs: int
    unique_commands: int
    system_shadow_count: int
    gnubin_only_count: int
    duplicate_provider_count: int
    directories: list[DirectoryRecord]
    duplicates: list[CommandRecord]
    system_shadows: list[CommandRecord]
    gnubin_only: list[CommandRecord]


def path_entries(path_value: str) -> list[Path]:
    """Return unique, non-empty PATH entries while preserving order."""

    entries: list[Path] = []
    for raw_entry in path_value.split(os.pathsep):
        if not raw_entry:
            continue
        candidate_dir = Path(raw_entry)
        if candidate_dir not in entries:
            entries.append(candidate_dir)
    return entries


def gnubin_directories(path_value: str) -> list[Path]:
    """Return Homebrew-style libexec/gnubin directories present on PATH."""

    return [
        candidate_dir
        for candidate_dir in path_entries(path_value)
        if candidate_dir.name == "gnubin" and candidate_dir.parent.name == "libexec"
    ]


def executable_commands(candidate_dir: Path) -> list[str]:
    """Return executable file names from a directory, or empty for a missing path."""

    if not candidate_dir.is_dir():
        return []
    try:
        return sorted(
            entry.name
            for entry in candidate_dir.iterdir()
            if entry.is_file() and os.access(entry, os.X_OK)
        )
    except OSError as exc:
        raise AuditError(
            f"cannot inspect PATH directory {candidate_dir}: {exc}"
        ) from exc


def system_candidates(command_name: str, system_dirs: Sequence[Path]) -> list[str]:
    """Return executable system commands with the requested name."""

    candidates: list[str] = []
    for system_dir in system_dirs:
        candidate_path = system_dir / command_name
        try:
            if candidate_path.is_file() and os.access(candidate_path, os.X_OK):
                candidates.append(str(candidate_path))
        except OSError as exc:
            raise AuditError(
                f"cannot inspect system candidate {candidate_path}: {exc}"
            ) from exc
    return candidates


def audit_path(
    path_value: str, system_dirs: Sequence[Path] = DEFAULT_SYSTEM_DIRS
) -> AuditReport:
    """Build a deterministic report for Homebrew gnubin commands on a PATH value."""

    gnubin_dirs = gnubin_directories(path_value)
    providers: dict[str, list[str]] = defaultdict(list)
    directory_records: list[DirectoryRecord] = []

    for candidate_dir in gnubin_dirs:
        command_names = executable_commands(candidate_dir)
        for command_name in command_names:
            providers[command_name].append(str(candidate_dir / command_name))
        directory_records.append(
            {
                "path": str(candidate_dir),
                "formula": candidate_dir.parent.parent.name,
                "command_count": len(command_names),
                "commands": command_names,
            }
        )

    command_records: list[CommandRecord] = []
    for command_name in sorted(providers):
        candidates = system_candidates(command_name, system_dirs)
        command_records.append(
            {
                "name": command_name,
                "effective": shutil.which(command_name, path=path_value) or "",
                "providers": providers[command_name],
                "system_candidates": candidates,
                "shadows_system": bool(candidates),
            }
        )

    duplicates = [record for record in command_records if len(record["providers"]) > 1]
    shadows = [record for record in command_records if record["shadows_system"]]
    gnubin_only = [record for record in command_records if not record["shadows_system"]]
    return {
        "schema_version": 1,
        "path_gnubin_dirs": len(gnubin_dirs),
        "unique_commands": len(command_records),
        "system_shadow_count": len(shadows),
        "gnubin_only_count": len(gnubin_only),
        "duplicate_provider_count": len(duplicates),
        "directories": directory_records,
        "duplicates": duplicates,
        "system_shadows": shadows,
        "gnubin_only": gnubin_only,
    }


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    """Parse command-line arguments."""

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--path",
        default=os.environ.get("PATH", ""),
        help="PATH value to audit (default: current PATH)",
    )
    parser.add_argument(
        "--system-dir",
        action="append",
        type=Path,
        help="System command directory; repeat to replace the macOS defaults",
    )
    parser.add_argument("--compact", action="store_true", help="Emit compact JSON")
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    """Run the command-shadow audit and write JSON to stdout."""

    args = parse_args(argv)
    selected_system_dirs = tuple(args.system_dir or DEFAULT_SYSTEM_DIRS)
    try:
        report = audit_path(args.path, selected_system_dirs)
    except AuditError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    json.dump(
        report,
        sys.stdout,
        indent=None if args.compact else JSON_INDENT_SPACES,
        sort_keys=True,
    )
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
