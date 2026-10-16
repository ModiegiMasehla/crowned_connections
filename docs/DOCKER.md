# Docker guide

Everything needed to build, run, test and ship Crowned Connections with Docker.
It replaces the Docker notes scattered through `README.md` and `backend/README.md`.

## Quick start

```bash
cp .env.example .env
docker compose up --build --wait
```

`--wait` returns once the database and API are both healthy.

| Service | URL |
| --- | --- |
| API | http://localhost:5000 |
| Health check | http://localhost:5000/health |
| API docs | http://localhost:5000/api/docs |
| Database | `127.0.0.1:5432` (this machine only) |

Seed accounts (development only): `customer@example.com` and `owner@example.com`, both with `Password123!`.

Point the Flutter app at the API with `--dart-define=API_BASE_URL=...`:

- Android emulator: `http://10.0.2.2:5000/api` (the default)
- iOS simulator: `http://127.0.0.1:5000/api`
- Physical phone: `http://<your computer's LAN IP>:5000/api`

## What is in the box

| File | Purpose |
| --- | --- |
| `docker-compose.yml` | Development stack: PostGIS database plus API, seeded. Also holds the optional `smoke` and `flutter-tests` tools. |
| `docker-compose.prod.yml` | Production-style stack: no seed data, no default secrets, hardened API container. |
| `backend/Dockerfile` | Multi-stage build: `deps`, `test`, `build`, `runtime`. Non-root user and a health check. |
| `docker/flutter-test.Dockerfile` | Runs `flutter analyze` and `flutter test` in a clean container. |
| `.env.example`, `.env.prod.example` | Settings templates. Copy to `.env` and `.env.prod`. |
| `scripts/smoke-test.sh` | Walks the full booking journey against the running API. |
| `scripts/db-check.sh` | Checks extensions, the no-overlap constraint and the seed counts. |
| `scripts/reset-db.sh` | Wipes and re-seeds the development database. |
| `Makefile` | Shortcuts for all of the above (`make help`). |
| `backend/.dockerignore`, `mobile/.dockerignore` | Keep build output and IDE files out of the build context. |

## The final integration check

With the stack running, this covers the Docker items in `docs/DELIVERY_CHECKLIST.md`:

```bash
make integration
# or, step by step:
docker compose up --build -d --wait
sh scripts/db-check.sh
docker compose --profile smoke run --rm smoke
```

- `db-check.sh` confirms PostGIS, `btree_gist` and `pgcrypto`, the `appointments_stylist_no_overlap` constraint, at least 10 salons and 20 services, and that appointment times are `timestamptz`.
- `smoke-test.sh` signs in as both roles, checks role protection, runs a PostGIS search, books a slot, proves the same slot is rejected with `409`, declines the booking, sees the slot offered again, then books and confirms it.

The smoke test leaves one confirmed booking behind. Run `sh scripts/reset-db.sh` to clear it.

Run the test suites in Docker as well:

```bash
make test-backend     # docker build --target test --progress=plain backend
make test-mobile      # flutter analyze + flutter test
```

## Day-to-day commands

```bash
docker compose logs -f api        # follow the API log
docker compose down               # stop, keep data
sh scripts/reset-db.sh            # wipe data and re-seed (asks first)
docker compose exec db psql -U crowned -d crowned_connections
```

The migration and seed run only when the `pgdata` volume is created. Changing
`database/migrations/001_schema.sql` later does not change an existing
database: reset it, or apply the change by hand.

## Production-style run

```bash
cp .env.prod.example .env.prod          # set POSTGRES_PASSWORD and JWT_SECRET
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d --build --wait
```

- It refuses to start if `POSTGRES_PASSWORD` or `JWT_SECRET` is empty. Generate each with `openssl rand -base64 48`.
- No seed data is loaded, so there are no demo accounts. Register an owner through the app.
- The database port is not published. The API container is read-only, drops all capabilities, and is limited to 768 MB.
- Put a TLS reverse proxy in front of the API and point the mobile app at its `https` address.

Before a real launch, also tighten the API's CORS setting. It currently allows
every origin (`allowedOriginPatterns("*")` in `CrownedConnectionsApplication.java`).

## Troubleshooting

- **`password authentication failed` after changing `POSTGRES_PASSWORD`.** The password is stored in the existing volume. Reset the database or change the password inside Postgres.
- **The API is unhealthy.** Run `docker compose logs api`. The usual cause is a `JWT_SECRET` shorter than 32 bytes.
- **Port already in use.** Change `API_PORT` or `DB_PORT` in `.env`.
- **A script fails with `\r: command not found`.** Windows changed its line endings. `.gitattributes` prevents this on a fresh checkout; otherwise run `git add --renormalize .`.
- **The app cannot reach the API from a phone.** Use your computer's LAN IP, and allow port 5000 through its firewall.
