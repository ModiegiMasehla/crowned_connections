# Delivery checklist

Before calling V1 complete:

- [ ] PostgreSQL starts with PostGIS
- [ ] `btree_gist` extension exists
- [ ] `pgcrypto` extension exists
- [ ] Seed has 10 salons and 20+ services
- [ ] Customer can register/login
- [ ] Owner can register/login
- [ ] Customer cannot call owner-only endpoints
- [ ] Owner can create/update a salon
- [ ] Owner can add a service
- [ ] Search uses `ST_DWithin` and `ST_Distance`
- [ ] Customer precise location is not stored
- [ ] Availability is generated from staff schedules and existing bookings
- [ ] Times are stored as UTC `timestamptz`
- [ ] Times are presented as `Africa/Johannesburg`
- [ ] Booking is transactional
- [ ] PostgreSQL exclusion constraint prevents overlapping active appointments per stylist
- [ ] Owner can accept/decline a pending booking
- [ ] Flutter customer flow reaches booking
- [ ] Flutter owner flow reaches accept/decline
- [ ] Google Maps configuration is supplied through secure platform configuration
- [ ] `.env` is not committed
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] backend build/tests pass
- [ ] Docker Compose starts the API and database
