# Crowned Connections Java API

Backend migrated from TypeScript/Express to Java 17 and Spring Boot. It exposes the same REST paths consumed by the Flutter app. PostgreSQL/PostGIS remains the data store.

## Run locally

1. Start the database from the project root: `docker compose up db -d`.
2. From `backend/`, run `mvn spring-boot:run`.
3. Health check: `curl http://localhost:5000/health`.

Or run the whole stack with `docker compose up --build`. The SQL migration and development seed run automatically only when the database volume is first initialized. To reset the development database (destructive): `docker compose down -v` then `docker compose up --build`.

Set `JWT_SECRET` to a unique secret of at least 32 bytes outside local development. Seed credentials are for local development only.
