# Crowned Connections API: multi-stage build.
#
#   deps     - Maven plus the downloaded dependencies (cached while pom.xml is unchanged)
#   test     - runs the backend unit tests:  docker build --target test --progress=plain backend
#   build    - packages the Spring Boot jar
#   runtime  - small JRE image, non-root user, health check (the default target)

FROM maven:3.9-eclipse-temurin-17 AS deps
WORKDIR /app
COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 mvn -B -q dependency:go-offline

FROM deps AS test
COPY src ./src
RUN --mount=type=cache,target=/root/.m2 mvn -B test

FROM deps AS build
COPY src ./src
RUN --mount=type=cache,target=/root/.m2 mvn -B -q -DskipTests package \
 && find target -maxdepth 1 -name '*.jar' ! -name '*.original' -exec cp {} /app/app.jar \;

FROM eclipse-temurin:17-jre AS runtime
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd --system --gid 10001 app \
 && useradd --system --uid 10001 --gid app --no-create-home --shell /usr/sbin/nologin app
WORKDIR /app
COPY --from=build --chown=app:app /app/app.jar /app/app.jar

ENV PORT=5000 \
    JAVA_OPTS="-XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError"
USER app
EXPOSE 5000

# The API answers GET /health once Spring and the database connection are up.
HEALTHCHECK --interval=15s --timeout=5s --start-period=40s --retries=5 \
  CMD curl -fsS "http://127.0.0.1:${PORT}/health" > /dev/null || exit 1

# exec so the JVM is PID 1 and receives SIGTERM for a clean shutdown.
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
