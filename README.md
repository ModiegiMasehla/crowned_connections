WTC-FY8EXSCD-Verification code

# Crowned Connections Phase 1


Crowned Connections is a South African salon/beauty marketplace MVP. V1 deliberately focuses on:

1. Database schema, migrations and seed data
2. Authentication and roles
3. Salon and service management
4. Hairstyle/service/location search
5. Availability and double-booking-safe booking
6. One Flutter app with customer and salon-owner experiences
7. Salon-owner booking acceptance/decline
8. Tests and Docker

Messaging, reviews, push notifications, analytics and the admin web panel are **later phases**. 
Payment fields are already present in the schema so adding payments later does not require a destructive migration.

## Architecture

```text
Flutter mobile app
       |
       | REST/JSON
       v
Node.js + TypeScript + Express
       |
       v
PostgreSQL + PostGIS
       |
       +-- geospatial search (ST_DWithin/ST_Distance)
       +-- appointment exclusion constraint (btree_gist + tstzrange)
```

All appointment timestamps are stored as `timestamptz`/UTC. The Flutter UI renders appointment times in `Africa/Johannesburg`.

Customer precise location is not persisted. 
A latitude/longitude pair may be sent to a search request and is used only for that query.

## V1 stack

- Flutter/Dart
- Node.js/TypeScript
- Express
- PostgreSQL + PostGIS
- `pg`
- `zod`
- `bcryptjs`
- JWT
- Google Maps Flutter
- Docker Compose

## Requirements

- Docker
- Docker Compose plugin (`docker compose`)
- Node.js 20+
- npm
- Flutter 3.24+ (or a compatible current Flutter SDK)
- Android Studio or Xcode for mobile builds
- Google Maps API key for real map rendering

## Quick start

### 1. Clone and configure

```bash
cp .env.example .env
```

Set at least:

```env
JWT_SECRET=replace-with-a-long-random-secret
```

For production, use a proper secret manager.

### 2. Start PostgreSQL + PostGIS + API

```bash
docker compose up --build
```

The API is available at:

```text
http://localhost:5000
http://localhost:5000/health
http://localhost:5000/api/docs
```

The database is initialized by the migration and seed containers.

### 3. Run the Flutter app

```bash
cd mobile
flutter pub get
flutter run
```

For Android, add the Google Maps API key described in `mobile/android/app/src/main/AndroidManifest.xml`.

For iOS, add the key to `mobile/ios/Runner/AppDelegate.swift` as described in `docs/GOOGLE_MAPS.md`.

## Development API

Default API base URL for Android emulator:

```text
http://10.0.2.2:5000/api
```

For iOS simulator:

```text
http://127.0.0.1:5000/api
```

For a physical phone, use your computer's LAN IP, for example:

```text
http://192.168.1.20:5000/api
```

## Seed accounts

The seed script creates development accounts only. Passwords are deliberately obvious development credentials and **must not be reused in production**.

Customer:

```text
customer@example.com
Password123!
```

Salon owner:

```text
owner@example.com
Password123!
```

See `database/seed/seed.sql` for the complete development dataset.

## Core API

### Authentication

- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/auth/me`

### Salons/services

- `GET /api/salons`
- `GET /api/salons/:id`
- `POST /api/salons`
- `PUT /api/salons/:id`
- `GET /api/services`
- `POST /api/services`

### Search

`GET /api/search`

Example:

```text
/api/search?q=knotless&lat=-25.7479&lng=28.2293&radiusKm=10
```

PostGIS performs the distance filter and ordering. Distance is not calculated in application code.

### Availability

```text
GET /api/availability?salonId=<uuid>&serviceId=<uuid>&date=2026-10-08&stylistId=<uuid>
```

### Booking

```text
POST /api/appointments
GET /api/appointments
POST /api/appointments/:id/decision
```

A customer creates a `PENDING` booking. A salon owner accepts or declines it.

## Double-booking protection

The database is the final authority.

The migration creates the `btree_gist` extension and an exclusion constraint using:

```sql
EXCLUDE USING gist (
  stylist_id WITH =,
  tstzrange(start_time, end_time, '[)') WITH &&
)
```

Only active booking statuses participate. A transaction rechecks/creates the appointment, but the PostgreSQL constraint is what makes concurrent double booking impossible.

## POPIA

The MVP applies privacy-by-design principles:

- explicit location permission
- manual location entry alternative
- no persistent storage of precise customer location
- password hashing
- authenticated/authorized endpoints
- account deletion endpoint
- data minimisation
- no secrets in Git
- privacy notice/consent screen
- audit-friendly timestamps

The production launch still requires a legal/privacy review for your exact business model and POPIA obligations.



## Future phases

After phase 1:

- messaging
- reviews
- push notifications
- admin web panel
- analytics
- payments
- advanced portfolios/media storage
- richer search ranking
- production observability
