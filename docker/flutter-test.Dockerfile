# Runs the Flutter analyzer and test suite in a clean container.
# Build context is ./mobile (see the flutter-tests service in docker-compose.yml).
#
#   docker compose --profile test run --rm flutter-tests
#
# Pick the Flutter version with FLUTTER_VERSION in .env. The app needs Flutter
# 3.24 or newer (pubspec.yaml: Dart >=3.4, flutter_lints ^5).

ARG FLUTTER_VERSION=3.24.5
FROM ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION}

WORKDIR /app

# Resolve packages first so this layer is cached until pubspec changes.
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .
RUN flutter pub get

CMD ["sh", "-c", "flutter analyze && flutter test"]
