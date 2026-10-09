# Crowned Connections — V1 implementation prompt

Act as a senior full-stack engineer, Flutter engineer, PostgreSQL/PostGIS engineer, security engineer and QA engineer.

Build **Crowned Connections V1**, a South African salon/beauty marketplace.

## Non-negotiable V1 scope

Include only:
- authentication
- customer and salon-owner roles
- salon profiles
- services/hairstyles
- Google Maps
- location-aware search
- availability
- booking
- salon-owner accept/decline

Do not implement in V1:
- messaging
- reviews
- push notifications
- admin web panel
- analytics
- payment processing

Keep payment fields in the appointment schema:
`payment_status`, `payment_method`, `amount_cents`, `deposit_amount_cents`, `transaction_reference`.

Use **one Flutter app**. The app must switch experience by authenticated role. Do not create separate customer and owner mobile apps. The admin panel is a later small web application.

## Required stack

- Flutter/Dart
- Java 17/Spring Boot
- PostgreSQL
- PostGIS
- REST API
- Docker Compose

## Hard technical requirements

### PostGIS
Store salon coordinates as PostGIS `geography(Point,4326)`.

Distance/radius search MUST use PostGIS:
- `ST_DWithin`
- `ST_Distance`

Do not calculate geographic distance in application code.

### Double booking
The database is the final authority.

Enable:
```sql
CREATE EXTENSION IF NOT EXISTS btree_gist;
```

Use a PostgreSQL exclusion constraint:
```sql
EXCLUDE USING gist (
  stylist_id WITH =,
  tstzrange(start_time, end_time, '[)') WITH &&
)
```

Apply it only to active appointment states such as:
`PENDING`, `CONFIRMED`, `RESCHEDULED`.

Booking MUST also run inside a transaction with server-side validation. Application checks alone are not acceptable.

### Time
Store all appointment timestamps as UTC using PostgreSQL `timestamptz`.

Render customer-facing times in:
`Africa/Johannesburg`.

### POPIA
Apply privacy-by-design:
- explicit consent before location use
- manual location alternative
- do not persist precise customer location in V1
- data minimisation
- account deletion
- password hashing
- authenticated/authorized access
- no secrets in Git
- payment provider references only; no raw card data

## V1 build order

### Stage 1
Database schema, migrations and seed data:
- 10 South African salons
- 20+ services/hairstyles

Run tests and stop for review.

### Stage 2
Auth and roles.

Run tests and stop for review.

### Stage 3
Salon and service management endpoints.

Run tests and stop for review.

### Stage 4
Search by hairstyle, distance and filters with ranking.

Run tests and stop for review.

### Stage 5
Availability and booking with double-booking protection.

Run tests and stop for review.

### Stage 6
Flutter app:
- onboarding
- login/register
- search
- results
- salon profile
- booking
- my appointments
- Google Maps

Run tests and stop for review.

### Stage 7
Salon-owner dashboard:
- appointments
- calendar-ready structure
- accept/decline

Run tests and stop for review.

### Stage 8
Tests and Docker.

Run tests and stop for final review.

## Delivery rule

After every stage:
1. run that stage's tests
2. inspect changed files
3. report what passed/failed
4. stop and wait for review

Do not silently continue into the next stage.

## Definition of done

The customer can:
Register -> log in -> search a hairstyle -> see nearby salons -> open a salon -> choose a service -> see real availability -> request a booking.

The salon owner can:
Log in -> see pending booking -> accept/decline it.

A second concurrent booking for the same stylist/time cannot succeed.

Provide:
- source code
- migrations
- seed data
- API docs
- Flutter source
- Docker
- `.env.example`
- tests
- README
- stage-by-stage Git push list.
