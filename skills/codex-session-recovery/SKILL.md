---
name: codex-session-recovery
description: "Audit and safely merge Codex session JSONL history across multiple CODEX_HOME directories without reading or modifying SQLite state, configuration, authentication, memories, or logs."
---

# Codex Session Recovery

Recover or migrate Codex conversation history at the session-file layer. This skill is intentionally narrower than whole-home restoration: it owns only `sessions/**/*.jsonl` and never treats Codex SQLite state as a repair surface.

## Safety Contract

- Default to audit-only mode. Run `--apply` only after the user explicitly requests the merge.
- Treat every source home as read-only.
- Stop every Codex process using any named source or destination home before applying. The script requires `--confirm-all-homes-inactive` as an explicit assertion; it does not pretend to detect every possible writer.
- Never open, query, copy selectively, migrate, or edit `state_*.sqlite*`.
- Never merge `config.toml`, `auth.json`, `history.jsonl`, `memories/`, `logs/`, or other `CODEX_HOME` state through this tool.
- Reject malformed or empty JSONL, symlink or special-file entries, files that change after audit, and non-prefix content conflicts.
- A detected conflict blocks all destination session writes. Strict-prefix replacement preserves the shorter destination file under the declared backup directory first.
- Keep Time Machine or other whole-home activation as a separate, incident-specific recovery procedure. Do not generalize directory-swap scripts through this skill.

## Workflow

1. Resolve each named path as a Codex home; the script appends `sessions/` itself.
2. Choose an existing destination Codex home and an external report path.
3. Run the bundled script without `--apply` and inspect the action counts and every `conflict` decision.
4. If the audit is clean, stop all Codex processes using the named homes.
5. Re-run the same command with an external backup directory, `--confirm-all-homes-inactive`, and `--apply`.
6. Preserve the JSON report and backup directory until the recovered history has been verified through Codex.
7. Re-run audit-only mode if an idempotence check is useful; successfully merged paths should become `identical` or `destination_is_newer`.

## Script

Use the installed skill path appropriate to the current environment:

```bash
python3 /absolute/path/to/codex-session-recovery/scripts/merge-codex-sessions.py \
  --source-home /path/to/old/.codex \
  --source-home /path/to/another/.codex \
  --destination-home "$HOME/.codex" \
  --report /path/to/recovery/session-merge-audit.json
```

Apply only after reviewing a clean audit and stopping all relevant Codex processes:

```bash
python3 /absolute/path/to/codex-session-recovery/scripts/merge-codex-sessions.py \
  --source-home /path/to/old/.codex \
  --source-home /path/to/another/.codex \
  --destination-home "$HOME/.codex" \
  --report /path/to/recovery/session-merge-final.json \
  --backup-dir /path/to/recovery/session-backups \
  --confirm-all-homes-inactive \
  --apply
```

Exit codes are `0` for a clean audit or successful apply, `2` for content conflicts, and `1` for invalid input or an operational failure. Reports contain paths, hashes, sizes, and decisions but never session record contents.

## Merge Semantics

For each relative session path across all sources and the destination:

- `add`: the path exists only in a compatible source chain and may be added.
- `identical`: the selected source and destination bytes match.
- `extend_destination`: the destination is a strict byte prefix of the newest compatible source and may be replaced after backup.
- `destination_is_newer`: the source is a strict byte prefix of the destination; preserve the destination.
- `destination_only`: no source contains the destination path; preserve it.
- `conflict`: source variants branch or source and destination are not byte-prefix compatible; do not apply anything.

Identical duplicates and strictly increasing append-only variants across multiple source homes are compatible. Source ordering does not override a conflict.

## Rollback Boundary

The apply path stages selected source files before installation and attempts an in-scope rollback if installation fails. Replaced destination files are retained under `BACKUP_DIR/replaced-prefix/<relative-session-path>`. Added paths remain identifiable by the machine-readable report. Do not delete or restore files from the report without rechecking hashes and confirming Codex is stopped.
