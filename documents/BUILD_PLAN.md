# Crowned Connections V1 build order

The implementation is intentionally split into eight review gates.

## Stage 1 — Database schema, migrations and seed data

Goal:
- PostgreSQL + PostGIS
- `btree_gist`
- users/roles
- salons/services/stylists/availability
- appointments
- payment-ready appointment fields
- 10 South African development salons
- 20+ services/hairstyles

Tests:
- migration starts
- seed loads
- PostGIS works
- exclusion constraint exists

STOP for review.

## Stage 2 — Authentication and roles

Goal:
- registration
- login
- JWT
- password hashing
- customer/salon-owner authorization
- account deletion

Tests:
- valid login
- invalid login
- role-protected routes
- deletion

STOP for review.

## Stage 3 — Salon and service management endpoints

Goal:
- salon CRUD
- service CRUD
- staff and service relationships
- operating data

Tests:
- owner can create/update own salon
- customer cannot manage salons
- service pricing/duration validation

STOP for review.

## Stage 4 — Search

Goal:
- hairstyle/service search
- distance/radius
- price/rating filters
- ranking
- PostGIS distance queries

Tests:
- exact service match
- radius filter
- price/rating filters
- no application-side distance calculations

STOP for review.

## Stage 5 — Availability and booking

Goal:
- dynamic slots
- UTC storage
- Africa/Johannesburg rendering
- transaction
- PostgreSQL exclusion constraint
- owner accept/decline

Tests:
- slot generation
- blocked dates
- concurrent overlap protection
- owner decision

STOP for review.

## Stage 6 — Flutter app

Goal:
- one app
- role-based experience
- onboarding/login
- customer search/results/profile/booking/my appointments
- owner dashboard/booking decision
- Google Maps

Tests:
- login/register
- search
- salon profile
- booking
- owner decision

STOP for review.

## Stage 7 — Owner experience

Goal:
- owner-facing appointment dashboard
- salon/service management screens as needed
- accept/decline

STOP for review.

## Stage 8 — Tests and Docker

Goal:
- automated backend tests
- mobile tests
- Docker Compose
- documentation
- production-hardening checklist

STOP for release review.

## Explicitly later

- Messaging
- Reviews
- Push notifications
- Admin web panel
- Analytics
- Payments processing

The schema already contains payment status/method/deposit/reference fields.
