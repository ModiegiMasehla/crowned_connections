#!/bin/sh
# Checks the running development database against docs/DELIVERY_CHECKLIST.md:
# extensions, the no-overlap constraint, and the seed data counts.
#
#   sh scripts/db-check.sh        (run from the project root, stack already up)

set -eu

COMPOSE="${COMPOSE:-docker compose}"
DB_USER="${POSTGRES_USER:-crowned}"
DB_NAME="${POSTGRES_DB:-crowned_connections}"

PASSED=0
FAILED=0

query() {
  $COMPOSE exec -T db psql -U "$DB_USER" -d "$DB_NAME" -At -c "$1"
}

check() {
  if [ "$2" = "$3" ]; then
    PASSED=$((PASSED + 1)); printf '  ok    %s\n' "$1"
  else
    FAILED=$((FAILED + 1)); printf '  FAIL  %s (expected %s, got %s)\n' "$1" "$2" "$3"
  fi
}

at_least() {
  if [ "$3" -ge "$2" ]; then
    PASSED=$((PASSED + 1)); printf '  ok    %s (%s)\n' "$1" "$3"
  else
    FAILED=$((FAILED + 1)); printf '  FAIL  %s (need at least %s, got %s)\n' "$1" "$2" "$3"
  fi
}

printf 'Database checks\n'
check "postgis extension installed" 1 "$(query "SELECT count(*) FROM pg_extension WHERE extname = 'postgis'")"
check "btree_gist extension installed" 1 "$(query "SELECT count(*) FROM pg_extension WHERE extname = 'btree_gist'")"
check "pgcrypto extension installed" 1 "$(query "SELECT count(*) FROM pg_extension WHERE extname = 'pgcrypto'")"
check "no-overlap exclusion constraint exists" 1 \
  "$(query "SELECT count(*) FROM pg_constraint WHERE conname = 'appointments_stylist_no_overlap' AND contype = 'x'")"
at_least "seeded salons" 10 "$(query "SELECT count(*) FROM salon_profiles WHERE deleted_at IS NULL")"
at_least "seeded services" 20 "$(query "SELECT count(*) FROM services WHERE deleted_at IS NULL")"
check "seeded development users" 2 "$(query "SELECT count(*) FROM users WHERE email IN ('customer@example.com','owner@example.com')")"
check "appointment times are timestamptz" timestamptz \
  "$(query "SELECT data_type FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'start_time'" | sed 's/timestamp with time zone/timestamptz/')"

printf '\n%d passed, %d failed\n' "$PASSED" "$FAILED"
if [ "$FAILED" -gt 0 ]; then exit 1; fi
