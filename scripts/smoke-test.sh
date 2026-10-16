#!/bin/sh
# API smoke test for the seeded development stack.
#
# Run it against a stack started with docker-compose.yml:
#   docker compose --profile smoke run --rm smoke        (inside Docker)
#   API_URL=http://localhost:5000 sh scripts/smoke-test.sh   (needs curl and jq)
#
# It walks the whole booking journey: sign-in, role checks, PostGIS search,
# availability, booking, double-booking rejection, owner decision, and a
# declined slot becoming free again. It finishes with one CONFIRMED booking left
# in the development database; scripts/reset-db.sh clears it.

set -eu

API_URL="${API_URL:-http://localhost:5000}"
SALON_ID="${SALON_ID:-20000000-0000-0000-0000-000000000001}"
PASSWORD="${SMOKE_PASSWORD:-Password123!}"
CUSTOMER_EMAIL="${SMOKE_CUSTOMER_EMAIL:-customer@example.com}"
OWNER_EMAIL="${SMOKE_OWNER_EMAIL:-owner@example.com}"

PASSED=0
FAILED=0
STATUS=""
BODY=""

pass() { PASSED=$((PASSED + 1)); printf '  ok    %s\n' "$1"; }
fail() { FAILED=$((FAILED + 1)); printf '  FAIL  %s\n' "$1"; }

# check "description" expected actual
check() {
  if [ "$2" = "$3" ]; then pass "$1"; else fail "$1 (expected $2, got $3)"; fi
}

# req METHOD PATH [TOKEN] [JSON_BODY]  ->  sets STATUS and BODY
req() {
  method=$1
  path=$2
  token=${3:-}
  payload=${4:-}
  tmp=$(mktemp)
  set -- -sS -o "$tmp" -w '%{http_code}' -X "$method" "$API_URL$path" -H 'Content-Type: application/json'
  if [ -n "$token" ]; then
    set -- "$@" -H "Authorization: Bearer $token"
  fi
  if [ -n "$payload" ]; then
    set -- "$@" -d "$payload"
  fi
  STATUS=$(curl "$@")
  BODY=$(cat "$tmp")
  rm -f "$tmp"
}

# day_offset N  ->  the UTC date N days from now (works with GNU and BusyBox date)
day_offset() {
  date -u -d "@$(( $(date +%s) + $1 * 86400 ))" +%Y-%m-%d
}

printf 'Smoke test against %s\n\n' "$API_URL"

printf 'Waiting for the API...\n'
tries=0
until curl -fsS "$API_URL/health" >/dev/null 2>&1; do
  tries=$((tries + 1))
  if [ "$tries" -ge 60 ]; then
    printf 'The API did not become healthy within 60 seconds.\n'
    exit 1
  fi
  sleep 1
done

printf '\nHealth and docs\n'
req GET /health
check "GET /health returns 200" 200 "$STATUS"
check "health reports status ok" ok "$(printf '%s' "$BODY" | jq -r '.status')"
req GET /api/docs
check "GET /api/docs returns 200" 200 "$STATUS"

printf '\nAuthentication\n'
req POST /api/auth/login "" "{\"email\":\"$CUSTOMER_EMAIL\",\"password\":\"wrong-password\"}"
check "wrong password is rejected with 401" 401 "$STATUS"
req GET /api/appointments
check "appointments without a token is 401" 401 "$STATUS"

req POST /api/auth/login "" "{\"email\":\"$CUSTOMER_EMAIL\",\"password\":\"$PASSWORD\"}"
check "customer login returns 200" 200 "$STATUS"
CUSTOMER_TOKEN=$(printf '%s' "$BODY" | jq -r '.token')
req POST /api/auth/login "" "{\"email\":\"$OWNER_EMAIL\",\"password\":\"$PASSWORD\"}"
check "owner login returns 200" 200 "$STATUS"
OWNER_TOKEN=$(printf '%s' "$BODY" | jq -r '.token')

req GET /api/auth/me "$CUSTOMER_TOKEN"
check "customer /auth/me has role CUSTOMER" CUSTOMER "$(printf '%s' "$BODY" | jq -r '.user.role')"
req GET /api/auth/me "$OWNER_TOKEN"
check "owner /auth/me has role SALON_OWNER" SALON_OWNER "$(printf '%s' "$BODY" | jq -r '.user.role')"

printf '\nRole protection\n'
req POST /api/salons "$CUSTOMER_TOKEN" '{}'
check "customer cannot create a salon (403)" 403 "$STATUS"

printf '\nSearch (PostGIS)\n'
req GET "/api/search?q=Knotless%20Braids&lat=-25.7479&lng=28.2293&radiusKm=25"
check "search returns 200" 200 "$STATUS"
RESULTS=$(printf '%s' "$BODY" | jq '.results | length')
if [ "$RESULTS" -ge 1 ]; then pass "search found $RESULTS salon(s)"; else fail "search found no salons"; fi
check "results carry a PostGIS distance_km" true "$(printf '%s' "$BODY" | jq '[.results[] | .distance_km != null] | all')"
req GET "/api/search?q=Knotless%20Braids&radiusKm=1000"
check "radius over 100 km is rejected (400)" 400 "$STATUS"

printf '\nSalon profile and availability\n'
req GET "/api/salons/$SALON_ID"
check "salon profile returns 200" 200 "$STATUS"
SERVICE_ID=$(printf '%s' "$BODY" | jq -r '.services[] | select(.name == "Knotless Braids") | .id')
if [ -n "$SERVICE_ID" ]; then pass "salon offers Knotless Braids"; else fail "salon does not offer Knotless Braids"; exit 1; fi

SLOT_DATE=""
SLOT_START=""
SLOT_STYLIST=""
for offset in 1 2 3 4 5 6 7 8; do
  candidate=$(day_offset "$offset")
  req GET "/api/availability?salonId=$SALON_ID&serviceId=$SERVICE_ID&date=$candidate"
  if [ "$STATUS" = "200" ] && [ "$(printf '%s' "$BODY" | jq '.slots | length')" -ge 1 ]; then
    SLOT_DATE=$candidate
    SLOT_START=$(printf '%s' "$BODY" | jq -r '.slots[0].startTime')
    SLOT_STYLIST=$(printf '%s' "$BODY" | jq -r '.slots[0].stylistId')
    break
  fi
done
if [ -n "$SLOT_DATE" ]; then pass "free slot found on $SLOT_DATE at $SLOT_START"; else fail "no free slot in the next 8 days"; exit 1; fi

BOOKING="{\"salonId\":\"$SALON_ID\",\"serviceId\":\"$SERVICE_ID\",\"stylistId\":\"$SLOT_STYLIST\",\"startTime\":\"$SLOT_START\"}"

printf '\nBooking and double-booking protection\n'
req POST /api/appointments "" "$BOOKING"
check "booking without a token is 401" 401 "$STATUS"
req POST /api/appointments "$OWNER_TOKEN" "$BOOKING"
check "an owner cannot book as a customer (403)" 403 "$STATUS"

req POST /api/appointments "$CUSTOMER_TOKEN" "$BOOKING"
check "customer booking returns 201" 201 "$STATUS"
check "new booking is PENDING" PENDING "$(printf '%s' "$BODY" | jq -r '.appointment.status')"
APPOINTMENT_ID=$(printf '%s' "$BODY" | jq -r '.appointment.id')

req POST /api/appointments "$CUSTOMER_TOKEN" "$BOOKING"
check "the same slot again is rejected by the database (409)" 409 "$STATUS"

req GET "/api/availability?salonId=$SALON_ID&serviceId=$SERVICE_ID&date=$SLOT_DATE"
check "the booked slot is no longer offered" false \
  "$(printf '%s' "$BODY" | jq --arg s "$SLOT_START" --arg st "$SLOT_STYLIST" '[.slots[] | select(.startTime == $s and .stylistId == $st)] | length > 0')"

printf '\nOwner decision\n'
req POST "/api/appointments/$APPOINTMENT_ID/decision" "$CUSTOMER_TOKEN" '{"decision":"CONFIRMED"}'
check "a customer cannot decide a booking (403)" 403 "$STATUS"
req POST "/api/appointments/$APPOINTMENT_ID/decision" "$OWNER_TOKEN" '{"decision":"MAYBE"}'
check "an invalid decision is rejected (400)" 400 "$STATUS"

req POST "/api/appointments/$APPOINTMENT_ID/decision" "$OWNER_TOKEN" '{"decision":"DECLINED"}'
check "owner can decline (200)" 200 "$STATUS"
check "booking is now DECLINED" DECLINED "$(printf '%s' "$BODY" | jq -r '.appointment.status')"
req POST "/api/appointments/$APPOINTMENT_ID/decision" "$OWNER_TOKEN" '{"decision":"CONFIRMED"}'
check "a decided booking cannot be decided again (404)" 404 "$STATUS"

req GET "/api/availability?salonId=$SALON_ID&serviceId=$SERVICE_ID&date=$SLOT_DATE"
check "a declined slot is offered again" true \
  "$(printf '%s' "$BODY" | jq --arg s "$SLOT_START" --arg st "$SLOT_STYLIST" '[.slots[] | select(.startTime == $s and .stylistId == $st)] | length > 0')"

req POST /api/appointments "$CUSTOMER_TOKEN" "$BOOKING"
check "the freed slot can be booked again (201)" 201 "$STATUS"
SECOND_ID=$(printf '%s' "$BODY" | jq -r '.appointment.id')
req POST "/api/appointments/$SECOND_ID/decision" "$OWNER_TOKEN" '{"decision":"CONFIRMED"}'
check "owner can accept (200)" 200 "$STATUS"
check "booking is now CONFIRMED" CONFIRMED "$(printf '%s' "$BODY" | jq -r '.appointment.status')"

req GET /api/appointments "$CUSTOMER_TOKEN"
check "the customer sees the confirmed booking" CONFIRMED \
  "$(printf '%s' "$BODY" | jq -r --arg id "$SECOND_ID" '.appointments[] | select(.id == $id) | .status')"
req GET /api/appointments "$OWNER_TOKEN"
check "the owner sees the confirmed booking" CONFIRMED \
  "$(printf '%s' "$BODY" | jq -r --arg id "$SECOND_ID" '.appointments[] | select(.id == $id) | .status')"

printf '\n%d passed, %d failed\n' "$PASSED" "$FAILED"
if [ "$FAILED" -gt 0 ]; then exit 1; fi
