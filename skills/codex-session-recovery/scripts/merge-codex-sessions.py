#!/usr/bin/env python3
"""Audit or merge Codex session JSONL across homes without touching SQLite."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import hashlib
import json
import os
from pathlib import Path
import stat
import sys
import tempfile


BUFFER_BYTES = 1024 * 1024
SUCCESS_EXIT_CODE = 0
ERROR_EXIT_CODE = 1
CONFLICT_EXIT_CODE = 2
REPORT_SCHEMA_VERSION = 1


class SessionRecoveryError(RuntimeError):
    """Raised when Codex session history cannot be merged safely."""


@dataclass(frozen=True)
class FileEvidence:
    """Content and stable filesystem evidence for one validated JSONL file."""

    device: int
    inode: int
    size: int
    mtime_ns: int
    records: int
    sha256: str


@dataclass(frozen=True)
class ObservedFile:
    """A session file observed in one Codex home."""

    home: Path
    path: Path
    evidence: FileEvidence


@dataclass(frozen=True)
class SessionSnapshot:
    """Validated session files from one Codex home."""

    home: Path
    root: Path
    root_existed: bool
    files: dict[Path, ObservedFile]


@dataclass(frozen=True)
class SourceVariantEvidence:
    """Content evidence for one source-home variant in the audit report."""

    home: str
    size: int
    sha256: str


@dataclass(frozen=True)
class MergeDecision:
    """One path-level decision in a multi-home merge audit."""

    relative_path: str
    action: str
    source_homes: tuple[str, ...]
    source_variants: tuple[SourceVariantEvidence, ...]
    selected_source: str | None
    selected_size: int | None
    selected_sha256: str | None
    destination_size: int | None
    destination_sha256: str | None


@dataclass(frozen=True)
class AuditResult:
    """Complete conflict classification and selected source files."""

    decisions: tuple[MergeDecision, ...]
    selected_sources: dict[Path, ObservedFile]


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    """Parse the command-line interface."""

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source-home",
        action="append",
        required=True,
        type=Path,
        help="Source CODEX_HOME; repeat for multiple homes.",
    )
    parser.add_argument(
        "--destination-home",
        required=True,
        type=Path,
        help="Existing destination CODEX_HOME.",
    )
    parser.add_argument(
        "--report",
        required=True,
        type=Path,
        help="Machine-readable audit report path outside every sessions tree.",
    )
    parser.add_argument(
        "--backup-dir",
        type=Path,
        help="Backup root required by --apply and kept outside sessions trees.",
    )
    parser.add_argument(
        "--confirm-all-homes-inactive",
        action="store_true",
        help="Assert no Codex process is using any named home.",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Apply a conflict-free audit after staging and destination backup.",
    )
    return parser.parse_args(argv)


def validate_home(home_path: Path, label: str) -> Path:
    """Resolve and validate an existing Codex home directory."""

    try:
        resolved = home_path.expanduser().resolve(strict=True)
    except FileNotFoundError as error:
        raise SessionRecoveryError(f"{label} does not exist: {home_path}") from error
    if not resolved.is_dir():
        raise SessionRecoveryError(f"{label} is not a directory: {resolved}")
    return resolved


def path_exists_without_following(path: Path) -> bool:
    """Return whether a path entry exists, including a broken symlink."""

    return os.path.lexists(path)


def validate_sessions_root(home: Path, *, required: bool) -> tuple[Path, bool]:
    """Return a real sessions directory, or a missing destination path."""

    sessions_root = home / "sessions"
    if not path_exists_without_following(sessions_root):
        if required:
            raise SessionRecoveryError(
                f"source Codex home has no sessions directory: {sessions_root}"
            )
        return sessions_root, False
    root_stat = sessions_root.lstat()
    if stat.S_ISLNK(root_stat.st_mode):
        raise SessionRecoveryError(
            f"sessions root must not be a symlink: {sessions_root}"
        )
    if not stat.S_ISDIR(root_stat.st_mode):
        raise SessionRecoveryError(f"sessions root is not a directory: {sessions_root}")
    return sessions_root, True


def relative_jsonl_files(root: Path) -> dict[Path, Path]:
    """List regular JSONL files while rejecting symlinks and special entries."""

    if not path_exists_without_following(root):
        return {}
    result: dict[Path, Path] = {}

    def raise_walk_error(error: OSError) -> None:
        raise error

    for current_root, directory_names, file_names in os.walk(
        root, topdown=True, followlinks=False, onerror=raise_walk_error
    ):
        current_path = Path(current_root)
        directory_names.sort()
        file_names.sort()
        for directory_name in directory_names:
            directory_path = current_path / directory_name
            directory_stat = directory_path.lstat()
            if stat.S_ISLNK(directory_stat.st_mode):
                raise SessionRecoveryError(
                    f"session tree contains a symlink directory: {directory_path}"
                )
            if not stat.S_ISDIR(directory_stat.st_mode):
                raise SessionRecoveryError(
                    f"session tree contains a non-directory entry: {directory_path}"
                )
        for file_name in file_names:
            file_path = current_path / file_name
            file_stat = file_path.lstat()
            if stat.S_ISLNK(file_stat.st_mode):
                raise SessionRecoveryError(
                    f"session tree contains a symlink file: {file_path}"
                )
            if not stat.S_ISREG(file_stat.st_mode):
                raise SessionRecoveryError(
                    f"session tree contains a special file: {file_path}"
                )
            if file_path.suffix != ".jsonl":
                continue
            relative_path = file_path.relative_to(root)
            result[relative_path] = file_path
    return result


def stable_stat_fields(file_stat: os.stat_result) -> tuple[int, int, int, int]:
    """Return fields that detect replacement, truncation, or append writes."""

    return (
        file_stat.st_dev,
        file_stat.st_ino,
        file_stat.st_size,
        file_stat.st_mtime_ns,
    )


def readonly_flags() -> int:
    """Return read-only flags that reject symlink traversal when supported."""

    return os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)


def validate_jsonl(file_path: Path) -> FileEvidence:
    """Parse every record and return stable content evidence."""

    descriptor = os.open(file_path, readonly_flags())
    try:
        before = os.fstat(descriptor)
        if not stat.S_ISREG(before.st_mode):
            raise SessionRecoveryError(f"session entry is not regular: {file_path}")
        digest = hashlib.sha256()
        record_count = 0
        with os.fdopen(descriptor, "rb", closefd=False) as session_file:
            for line_number, line in enumerate(session_file, start=1):
                if not line.strip():
                    raise SessionRecoveryError(
                        f"blank JSONL record: {file_path}:{line_number}"
                    )
                try:
                    json.loads(line)
                except (json.JSONDecodeError, UnicodeDecodeError) as error:
                    raise SessionRecoveryError(
                        f"invalid JSONL record: {file_path}:{line_number}: {error}"
                    ) from error
                digest.update(line)
                record_count += 1
        after = os.fstat(descriptor)
    finally:
        os.close(descriptor)

    if record_count == 0:
        raise SessionRecoveryError(f"empty JSONL session: {file_path}")
    path_after = file_path.lstat()
    if stable_stat_fields(before) != stable_stat_fields(after) or stable_stat_fields(
        after
    ) != stable_stat_fields(path_after):
        raise SessionRecoveryError(f"session changed during validation: {file_path}")
    return FileEvidence(
        device=after.st_dev,
        inode=after.st_ino,
        size=after.st_size,
        mtime_ns=after.st_mtime_ns,
        records=record_count,
        sha256=digest.hexdigest(),
    )


def collect_snapshot(home: Path, *, required_sessions: bool) -> SessionSnapshot:
    """Validate and snapshot one home session tree."""

    root, root_existed = validate_sessions_root(home, required=required_sessions)
    observed: dict[Path, ObservedFile] = {}
    for relative_path, file_path in relative_jsonl_files(root).items():
        observed[relative_path] = ObservedFile(
            home=home,
            path=file_path,
            evidence=validate_jsonl(file_path),
        )
    return SessionSnapshot(
        home=home,
        root=root,
        root_existed=root_existed,
        files=observed,
    )


def verify_observed_metadata(observed: ObservedFile) -> None:
    """Fail if an observed path changed since content validation."""

    try:
        current = observed.path.lstat()
    except FileNotFoundError as error:
        raise SessionRecoveryError(
            f"session changed after audit: removed {observed.path}"
        ) from error
    if stat.S_ISLNK(current.st_mode) or not stat.S_ISREG(current.st_mode):
        raise SessionRecoveryError(
            f"session changed after audit: entry type changed {observed.path}"
        )
    if stable_stat_fields(current) != (
        observed.evidence.device,
        observed.evidence.inode,
        observed.evidence.size,
        observed.evidence.mtime_ns,
    ):
        raise SessionRecoveryError(
            f"session changed after audit: metadata mismatch {observed.path}"
        )


def verify_snapshot_unchanged(snapshot: SessionSnapshot) -> None:
    """Fail if a home gained, lost, or changed session paths after audit."""

    root_exists = path_exists_without_following(snapshot.root)
    if root_exists != snapshot.root_existed:
        raise SessionRecoveryError(
            f"sessions tree changed after audit: {snapshot.root}"
        )
    current_paths = relative_jsonl_files(snapshot.root)
    expected_paths = set(snapshot.files)
    if set(current_paths) != expected_paths:
        added = sorted(path.as_posix() for path in set(current_paths) - expected_paths)
        removed = sorted(
            path.as_posix() for path in expected_paths - set(current_paths)
        )
        raise SessionRecoveryError(
            "sessions tree changed after audit: "
            f"{snapshot.root}; added={added[:3]}, removed={removed[:3]}"
        )
    for observed in snapshot.files.values():
        verify_observed_metadata(observed)


def same_content(left: FileEvidence, right: FileEvidence) -> bool:
    """Return whether two validated files contain the same bytes."""

    return left.size == right.size and left.sha256 == right.sha256


def is_prefix(shorter: ObservedFile, longer: ObservedFile) -> bool:
    """Return whether a complete validated file is a byte prefix of another."""

    remaining = shorter.evidence.size
    shorter_descriptor: int | None = None
    longer_descriptor: int | None = None
    try:
        shorter_descriptor = os.open(shorter.path, readonly_flags())
        longer_descriptor = os.open(longer.path, readonly_flags())
        with (
            os.fdopen(shorter_descriptor, "rb", closefd=False) as shorter_file,
            os.fdopen(longer_descriptor, "rb", closefd=False) as longer_file,
        ):
            while remaining:
                chunk_size = min(BUFFER_BYTES, remaining)
                shorter_chunk = shorter_file.read(chunk_size)
                longer_chunk = longer_file.read(chunk_size)
                if not shorter_chunk or shorter_chunk != longer_chunk:
                    return False
                remaining -= len(shorter_chunk)
    finally:
        if longer_descriptor is not None:
            os.close(longer_descriptor)
        if shorter_descriptor is not None:
            os.close(shorter_descriptor)
    return True


def newest_compatible_source(
    variants: list[ObservedFile],
) -> tuple[ObservedFile | None, bool]:
    """Select the longest append-only source or report a branched conflict."""

    if not variants:
        return None, False
    ordered = sorted(
        variants,
        key=lambda item: (
            item.evidence.size,
            item.evidence.sha256,
            item.home.as_posix(),
        ),
    )
    selected = ordered[0]
    for candidate in ordered[1:]:
        if same_content(selected.evidence, candidate.evidence):
            continue
        if selected.evidence.size < candidate.evidence.size and is_prefix(
            selected, candidate
        ):
            selected = candidate
            continue
        if candidate.evidence.size < selected.evidence.size and is_prefix(
            candidate, selected
        ):
            continue
        return None, True
    return selected, False


def build_decision(
    relative_path: Path,
    source_variants: list[ObservedFile],
    destination: ObservedFile | None,
) -> tuple[MergeDecision, ObservedFile | None]:
    """Classify one relative path across all sources and the destination."""

    ordered_variants = sorted(
        source_variants,
        key=lambda item: (
            item.home.as_posix(),
            item.evidence.size,
            item.evidence.sha256,
        ),
    )
    source_homes = tuple(str(item.home) for item in ordered_variants)
    source_evidence = tuple(
        SourceVariantEvidence(
            home=str(item.home),
            size=item.evidence.size,
            sha256=item.evidence.sha256,
        )
        for item in ordered_variants
    )
    selected, source_conflict = newest_compatible_source(source_variants)
    if selected is None:
        action = "conflict" if source_conflict else "destination_only"
    elif destination is None:
        action = "add"
    elif same_content(selected.evidence, destination.evidence):
        action = "identical"
    elif destination.evidence.size < selected.evidence.size and is_prefix(
        destination, selected
    ):
        action = "extend_destination"
    elif selected.evidence.size < destination.evidence.size and is_prefix(
        selected, destination
    ):
        action = "destination_is_newer"
    else:
        action = "conflict"

    decision = MergeDecision(
        relative_path=relative_path.as_posix(),
        action=action,
        source_homes=source_homes,
        source_variants=source_evidence,
        selected_source=str(selected.home) if selected is not None else None,
        selected_size=selected.evidence.size if selected is not None else None,
        selected_sha256=selected.evidence.sha256 if selected is not None else None,
        destination_size=(
            destination.evidence.size if destination is not None else None
        ),
        destination_sha256=(
            destination.evidence.sha256 if destination is not None else None
        ),
    )
    return decision, selected


def audit_snapshots(
    sources: list[SessionSnapshot], destination: SessionSnapshot
) -> AuditResult:
    """Build deterministic decisions for all relative session paths."""

    all_paths = set(destination.files)
    for source in sources:
        all_paths.update(source.files)

    decisions: list[MergeDecision] = []
    selected_sources: dict[Path, ObservedFile] = {}
    for relative_path in sorted(all_paths):
        variants = [
            source.files[relative_path]
            for source in sources
            if relative_path in source.files
        ]
        decision, selected = build_decision(
            relative_path,
            variants,
            destination.files.get(relative_path),
        )
        decisions.append(decision)
        if selected is not None:
            selected_sources[relative_path] = selected
    return AuditResult(tuple(decisions), selected_sources)


def decision_counts(decisions: tuple[MergeDecision, ...]) -> dict[str, int]:
    """Count decisions by action in stable key order."""

    counts: dict[str, int] = {}
    for decision in decisions:
        counts[decision.action] = counts.get(decision.action, 0) + 1
    return dict(sorted(counts.items()))


def fsync_directory(directory: Path) -> None:
    """Persist a directory entry update where the platform supports it."""

    descriptor = os.open(directory, os.O_RDONLY)
    try:
        os.fsync(descriptor)
    finally:
        os.close(descriptor)


def write_report(
    report_path: Path,
    source_homes: list[Path],
    destination: SessionSnapshot,
    audit: AuditResult,
    *,
    status: str,
    applied: bool,
    backup_root: Path | None,
    error: str | None = None,
) -> None:
    """Atomically write a content-free machine-readable merge report."""

    payload: dict[str, object] = {
        "schema_version": REPORT_SCHEMA_VERSION,
        "status": status,
        "applied": applied,
        "source_homes": [str(home) for home in source_homes],
        "destination_home": str(destination.home),
        "destination_sessions": str(destination.root),
        "backup_dir": str(backup_root) if backup_root is not None else None,
        "counts": decision_counts(audit.decisions),
        "decisions": [asdict(decision) for decision in audit.decisions],
    }
    if error is not None:
        payload["error"] = error
    report_path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{report_path.name}.", dir=report_path.parent
    )
    temporary_path = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as report_file:
            json.dump(payload, report_file, indent=2, sort_keys=True)
            report_file.write("\n")
            report_file.flush()
            os.fsync(report_file.fileno())
        os.replace(temporary_path, report_path)
        fsync_directory(report_path.parent)
    finally:
        temporary_path.unlink(missing_ok=True)


def copy_observed_file(observed: ObservedFile, destination_path: Path) -> None:
    """Copy validated bytes through a sibling temporary file and fsync them."""

    verify_observed_metadata(observed)
    source_descriptor = os.open(observed.path, readonly_flags())
    temporary_descriptor: int | None = None
    temporary_path: Path | None = None
    try:
        destination_path.parent.mkdir(parents=True, exist_ok=True)
        temporary_descriptor, temporary_name = tempfile.mkstemp(
            prefix=f".{destination_path.name}.recovery-", dir=destination_path.parent
        )
        temporary_path = Path(temporary_name)
        source_before = os.fstat(source_descriptor)
        if stable_stat_fields(source_before) != (
            observed.evidence.device,
            observed.evidence.inode,
            observed.evidence.size,
            observed.evidence.mtime_ns,
        ):
            raise SessionRecoveryError(
                f"session changed before staging: {observed.path}"
            )
        digest = hashlib.sha256()
        copied_bytes = 0
        with (
            os.fdopen(source_descriptor, "rb", closefd=False) as source_file,
            os.fdopen(temporary_descriptor, "wb", closefd=False) as destination_file,
        ):
            while True:
                chunk = source_file.read(BUFFER_BYTES)
                if not chunk:
                    break
                destination_file.write(chunk)
                digest.update(chunk)
                copied_bytes += len(chunk)
            destination_file.flush()
            os.fsync(destination_file.fileno())
        source_after = os.fstat(source_descriptor)
        if stable_stat_fields(source_before) != stable_stat_fields(source_after):
            raise SessionRecoveryError(
                f"session changed during staging: {observed.path}"
            )
        if (
            copied_bytes != observed.evidence.size
            or digest.hexdigest() != observed.evidence.sha256
        ):
            raise SessionRecoveryError(
                f"staged content does not match audit: {observed.path}"
            )
        os.fchmod(temporary_descriptor, stat.S_IMODE(source_before.st_mode))
        os.utime(
            temporary_path,
            ns=(source_before.st_atime_ns, source_before.st_mtime_ns),
            follow_symlinks=False,
        )
        os.replace(temporary_path, destination_path)
        fsync_directory(destination_path.parent)
    finally:
        os.close(source_descriptor)
        if temporary_descriptor is not None:
            os.close(temporary_descriptor)
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)


def validate_output_locations(
    report_path: Path,
    backup_root: Path | None,
    session_roots: list[Path],
) -> None:
    """Keep reports and backups out of every session tree."""

    output_paths = [report_path]
    if backup_root is not None:
        output_paths.append(backup_root)
    for output_path in output_paths:
        for sessions_root in session_roots:
            if output_path == sessions_root or sessions_root in output_path.parents:
                raise SessionRecoveryError(
                    f"output path must stay outside sessions trees: {output_path}"
                )


def prepare_backup(
    destination_file: ObservedFile,
    relative_path: Path,
    backup_root: Path,
) -> Path:
    """Preserve a destination prefix, accepting only an identical old backup."""

    backup_path = backup_root / "replaced-prefix" / relative_path
    if path_exists_without_following(backup_path):
        backup_stat = backup_path.lstat()
        if stat.S_ISLNK(backup_stat.st_mode) or not stat.S_ISREG(backup_stat.st_mode):
            raise SessionRecoveryError(
                f"backup collision is not regular: {backup_path}"
            )
        backup_evidence = validate_jsonl(backup_path)
        if not same_content(backup_evidence, destination_file.evidence):
            raise SessionRecoveryError(f"backup collision differs: {backup_path}")
        return backup_path
    copy_observed_file(destination_file, backup_path)
    backup_evidence = validate_jsonl(backup_path)
    if not same_content(backup_evidence, destination_file.evidence):
        raise SessionRecoveryError(f"backup verification failed: {backup_path}")
    return backup_path


def install_new_file(staged_path: Path, destination_path: Path) -> None:
    """Install a staged add atomically without overwriting an appearing path."""

    destination_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        os.link(staged_path, destination_path)
    except FileExistsError as error:
        raise SessionRecoveryError(
            f"destination appeared after audit: {destination_path}"
        ) from error
    try:
        fsync_directory(destination_path.parent)
    except OSError as error:
        try:
            destination_path.unlink()
            fsync_directory(destination_path.parent)
        except OSError as cleanup_error:
            raise SessionRecoveryError(
                "post-link durability check failed and the added path could not be "
                f"removed: {destination_path}: {cleanup_error}"
            ) from cleanup_error
        raise error


def restore_backup(backup_path: Path, destination_path: Path) -> None:
    """Restore a validated backup through the durable copy path."""

    backup_observed = ObservedFile(
        home=backup_path,
        path=backup_path,
        evidence=validate_jsonl(backup_path),
    )
    copy_observed_file(backup_observed, destination_path)


def rollback_installed(
    installed: list[MergeDecision],
    destination: SessionSnapshot,
    backup_root: Path,
) -> list[str]:
    """Best-effort rollback of files installed by the current transaction."""

    rollback_errors: list[str] = []
    for decision in reversed(installed):
        relative_path = Path(decision.relative_path)
        destination_path = destination.root / relative_path
        try:
            if decision.action == "add":
                installed_evidence = validate_jsonl(destination_path)
                if (
                    installed_evidence.size != decision.selected_size
                    or installed_evidence.sha256 != decision.selected_sha256
                ):
                    raise SessionRecoveryError(
                        f"refusing to remove changed added path: {destination_path}"
                    )
                destination_path.unlink()
                fsync_directory(destination_path.parent)
            elif decision.action == "extend_destination":
                backup_path = backup_root / "replaced-prefix" / relative_path
                restore_backup(backup_path, destination_path)
        except (OSError, SessionRecoveryError) as error:
            rollback_errors.append(f"{destination_path}: {error}")
    return rollback_errors


def apply_audit(
    audit: AuditResult,
    sources: list[SessionSnapshot],
    destination: SessionSnapshot,
    backup_root: Path,
) -> None:
    """Stage, back up, install, verify, and rollback a clean audit."""

    for snapshot in [*sources, destination]:
        verify_snapshot_unchanged(snapshot)

    backup_root.mkdir(parents=True, exist_ok=True)
    if backup_root.is_symlink() or not backup_root.is_dir():
        raise SessionRecoveryError(
            f"backup root is not a real directory: {backup_root}"
        )

    actionable = tuple(
        decision
        for decision in audit.decisions
        if decision.action in {"add", "extend_destination"}
    )
    installed: list[MergeDecision] = []
    with tempfile.TemporaryDirectory(
        prefix=".codex-session-recovery-", dir=destination.home
    ) as temporary_dir:
        staging_root = Path(temporary_dir) / "staged"
        staged_paths: dict[Path, Path] = {}
        for decision in actionable:
            relative_path = Path(decision.relative_path)
            selected = audit.selected_sources[relative_path]
            staged_path = staging_root / relative_path
            copy_observed_file(selected, staged_path)
            staged_evidence = validate_jsonl(staged_path)
            if not same_content(staged_evidence, selected.evidence):
                raise SessionRecoveryError(
                    f"staged verification failed: {selected.path}"
                )
            staged_paths[relative_path] = staged_path

        for snapshot in [*sources, destination]:
            verify_snapshot_unchanged(snapshot)

        for decision in actionable:
            if decision.action != "extend_destination":
                continue
            relative_path = Path(decision.relative_path)
            destination_file = destination.files[relative_path]
            prepare_backup(destination_file, relative_path, backup_root)

        verify_snapshot_unchanged(destination)

        try:
            for decision in actionable:
                relative_path = Path(decision.relative_path)
                staged_path = staged_paths[relative_path]
                destination_path = destination.root / relative_path
                if decision.action == "add":
                    install_new_file(staged_path, destination_path)
                else:
                    verify_observed_metadata(destination.files[relative_path])
                    destination_path.parent.mkdir(parents=True, exist_ok=True)
                    os.replace(staged_path, destination_path)
                    installed.append(decision)
                    fsync_directory(destination_path.parent)
                    continue
                installed.append(decision)

            for decision in actionable:
                relative_path = Path(decision.relative_path)
                installed_evidence = validate_jsonl(destination.root / relative_path)
                if (
                    installed_evidence.size != decision.selected_size
                    or installed_evidence.sha256 != decision.selected_sha256
                ):
                    raise SessionRecoveryError(
                        f"installed content verification failed: {relative_path}"
                    )
        except (OSError, SessionRecoveryError) as error:
            rollback_errors = rollback_installed(installed, destination, backup_root)
            if rollback_errors:
                raise SessionRecoveryError(
                    f"apply failed: {error}; rollback failed: {rollback_errors}"
                ) from error
            raise SessionRecoveryError(
                f"apply failed and installed files were rolled back: {error}"
            ) from error


def run(args: argparse.Namespace) -> int:
    """Audit named homes and optionally apply a conflict-free session merge."""

    source_homes = [
        validate_home(source_home, f"source home {index}")
        for index, source_home in enumerate(args.source_home, start=1)
    ]
    if len(set(source_homes)) != len(source_homes):
        raise SessionRecoveryError("source homes must be unique")
    destination_home = validate_home(args.destination_home, "destination home")
    if destination_home in source_homes:
        raise SessionRecoveryError(
            "destination home must differ from every source home"
        )
    if args.apply and not args.confirm_all_homes_inactive:
        raise SessionRecoveryError(
            "--apply requires --confirm-all-homes-inactive after stopping Codex"
        )
    if args.apply and args.backup_dir is None:
        raise SessionRecoveryError("--apply requires --backup-dir")

    report_path = args.report.expanduser().resolve(strict=False)
    backup_root = (
        args.backup_dir.expanduser().resolve(strict=False)
        if args.backup_dir is not None
        else None
    )
    sources = [collect_snapshot(home, required_sessions=True) for home in source_homes]
    destination = collect_snapshot(destination_home, required_sessions=False)
    validate_output_locations(
        report_path,
        backup_root,
        [snapshot.root for snapshot in [*sources, destination]],
    )

    audit = audit_snapshots(sources, destination)
    for snapshot in [*sources, destination]:
        verify_snapshot_unchanged(snapshot)

    conflicts = [
        decision for decision in audit.decisions if decision.action == "conflict"
    ]
    if conflicts:
        write_report(
            report_path,
            source_homes,
            destination,
            audit,
            status="conflict",
            applied=False,
            backup_root=backup_root,
        )
        print(
            f"merge blocked: {len(conflicts)} non-prefix content conflicts",
            file=sys.stderr,
        )
        return CONFLICT_EXIT_CODE

    write_report(
        report_path,
        source_homes,
        destination,
        audit,
        status="clean",
        applied=False,
        backup_root=backup_root,
    )
    if args.apply:
        assert backup_root is not None
        try:
            apply_audit(audit, sources, destination, backup_root)
        except (OSError, SessionRecoveryError) as error:
            write_report(
                report_path,
                source_homes,
                destination,
                audit,
                status="apply_failed",
                applied=False,
                backup_root=backup_root,
                error=str(error),
            )
            raise
        write_report(
            report_path,
            source_homes,
            destination,
            audit,
            status="applied",
            applied=True,
            backup_root=backup_root,
        )

    status = "applied" if args.apply else "clean"
    print(
        json.dumps(
            {
                "applied": bool(args.apply),
                "counts": decision_counts(audit.decisions),
                "status": status,
            },
            sort_keys=True,
        )
    )
    return SUCCESS_EXIT_CODE


def main(argv: list[str] | None = None) -> int:
    """CLI boundary with concise, actionable failures."""

    try:
        return run(parse_args(argv))
    except (OSError, SessionRecoveryError) as error:
        print(f"session recovery failed: {error}", file=sys.stderr)
        return ERROR_EXIT_CODE


if __name__ == "__main__":
    raise SystemExit(main())
