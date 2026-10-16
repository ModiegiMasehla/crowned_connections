#!/bin/sh
# Wipes the DEVELOPMENT database and rebuilds it from the migration and seed.
# This deletes all data in the pgdata volume. Run from the project root.
#
#   sh scripts/reset-db.sh        asks for confirmation
#   sh scripts/reset-db.sh -y     no prompt

set -eu

COMPOSE="${COMPOSE:-docker compose}"

if [ "${1:-}" != "-y" ]; then
  printf 'This deletes the development database volume and re-seeds it. Continue? [y/N] '
  read -r answer
  case "$answer" in
    y|Y|yes|YES) ;;
    *) printf 'Cancelled.\n'; exit 1 ;;
  esac
fi

$COMPOSE down -v
$COMPOSE up --build -d --wait
printf 'Database reset and API healthy.\n'
