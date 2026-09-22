#!/usr/bin/env sh
# Dumps the Kitaza database and keeps a rolling window of dumps.
#
#   DATABASE_URL      postgres connection string (required)
#   BACKUP_DIR        where dumps go            (default /backups)
#   RETENTION_DAYS    how long to keep them     (default 14)
#
# Works against the compose Postgres and against Supabase alike: pg_dump only
# needs a connection string.
set -eu

: "${DATABASE_URL:?DATABASE_URL must be set}"
BACKUP_DIR="${BACKUP_DIR:-/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

mkdir -p "$BACKUP_DIR"
stamp="$(date -u +%Y%m%d-%H%M%S)"
target="$BACKUP_DIR/kitaza-$stamp.dump"
partial="$target.partial"

# Written under a temporary name and renamed only once complete, so a crash
# mid-dump never leaves a file that looks like a finished backup.
pg_dump --format=custom --no-owner --no-privileges --file="$partial" "$DATABASE_URL"

# A dump that pg_restore cannot list is not a backup.
pg_restore --list "$partial" > /dev/null
mv "$partial" "$target"

find "$BACKUP_DIR" -name 'kitaza-*.dump' -type f -mtime +"$RETENTION_DAYS" -delete
find "$BACKUP_DIR" -name 'kitaza-*.dump.partial' -type f -mmin +120 -delete

echo "backup written: $target ($(du -h "$target" | cut -f1))"
