#!/usr/bin/env bash
# Backup script for the application data directory.
# Creates a timestamped tar archive and removes archives older than RETENTION_DAYS.
set -euo pipefail

BACKUP_SOURCE="${1:-}"
BACKUP_DEST="${2:-}"
RETENTION_DAYS="${3:-7}"

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

[[ -n "$BACKUP_SOURCE" ]] || die "Usage: $0 <source-dir> <dest-dir> [retention-days]"
[[ -n "$BACKUP_DEST" ]]   || die "Usage: $0 <source-dir> <dest-dir> [retention-days]"
[[ -d "$BACKUP_SOURCE" ]] || die "source directory does not exist: $BACKUP_SOURCE"

mkdir -p -- "$BACKUP_DEST"

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
ARCHIVE_NAME="backup-${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="${BACKUP_DEST}/${ARCHIVE_NAME}"

printf 'Creating archive: %s\n' "$ARCHIVE_PATH"
tar -czf "$ARCHIVE_PATH" -C "$(dirname -- "$BACKUP_SOURCE")" "$(basename -- "$BACKUP_SOURCE")"

printf 'Archive created: %s (%s bytes)\n' "$ARCHIVE_PATH" "$(wc -c < "$ARCHIVE_PATH")"

printf 'Removing archives older than %s days from %s\n' "$RETENTION_DAYS" "$BACKUP_DEST"
find "$BACKUP_DEST" -maxdepth 1 -name 'backup-*.tar.gz' -mtime +"$RETENTION_DAYS" -delete

printf 'Backup complete.\n'
