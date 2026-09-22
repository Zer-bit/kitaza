#!/usr/bin/env sh
# Restores a Kitaza dump into a database, replacing what is there.
#
#   restore.sh <dump-file> <target-database-url> --yes-replace-everything
#
# Restoring over the live database destroys everything written since the dump
# was taken, so the confirmation flag is required rather than prompted for:
# it has to be typed on purpose.
set -eu

dump="${1:?usage: restore.sh <dump-file> <target-database-url> --yes-replace-everything}"
target="${2:?usage: restore.sh <dump-file> <target-database-url> --yes-replace-everything}"
confirm="${3:-}"

if [ "$confirm" != "--yes-replace-everything" ]; then
  echo "refusing to restore without --yes-replace-everything" >&2
  exit 2
fi

pg_restore --list "$dump" > /dev/null

pg_restore --clean --if-exists --no-owner --no-privileges \
  --single-transaction --exit-on-error \
  --dbname="$target" "$dump"

echo "restored $dump"
