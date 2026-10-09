# V1 smoke tests

## Health

```bash
curl http://localhost:5000/health
```

Expected:

```json
{"status":"ok","service":"crowned-connections-api"}
```

## Login

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"customer@example.com","password":"Password123!"}'
```

Copy the returned token.

## Search

```bash
curl "http://localhost:5000/api/search?q=Knotless%20Braids&lat=-25.7479&lng=28.2293&radiusKm=25"
```

The response includes `distance_km` produced by PostGIS.

## Salon profile

```bash
curl http://localhost:5000/api/salons/20000000-0000-0000-0000-000000000001
```

## Availability

Use a service ID returned by the salon profile:

```bash
curl "http://localhost:5000/api/availability?salonId=20000000-0000-0000-0000-000000000001&serviceId=YOUR_SERVICE_ID&date=2026-10-08"
```

## Booking

```bash
curl -X POST http://localhost:5000/api/appointments \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"salonId":"20000000-0000-0000-0000-000000000001","serviceId":"YOUR_SERVICE_ID","startTime":"2026-10-08T08:00:00+02:00"}'
```

Expected status: `201`.

The appointment is initially `PENDING`.

## Owner decision

Log in as the owner and use:

```bash
curl -X POST http://localhost:5000/api/appointments/APPOINTMENT_ID/decision \
  -H "Authorization: Bearer OWNER_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"decision":"CONFIRMED"}'
```
