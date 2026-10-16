# Shortcuts for the Docker workflow. `make help` lists them.
# Recipes use tabs. On Windows run these through WSL or Git Bash.

COMPOSE ?= docker compose
PROD    := $(COMPOSE) -f docker-compose.prod.yml --env-file .env.prod

.PHONY: help up down logs ps reset smoke db-check test-backend test-mobile integration prod-up prod-down

help:
	@echo "make up            build and start the database and API (waits until healthy)"
	@echo "make down          stop the stack, keep the data"
	@echo "make logs          follow the API and database logs"
	@echo "make reset         wipe the dev database and re-seed it (asks first)"
	@echo "make smoke         API smoke test (full booking journey)"
	@echo "make db-check      check extensions, constraint and seed data"
	@echo "make test-backend  backend unit tests in Docker"
	@echo "make test-mobile   flutter analyze and flutter test in Docker"
	@echo "make integration   up + db-check + smoke: the final integration check"
	@echo "make prod-up       start the production-style stack (needs .env.prod)"
	@echo "make prod-down     stop the production-style stack"

up:
	$(COMPOSE) up --build -d --wait

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f api db

ps:
	$(COMPOSE) ps

reset:
	sh scripts/reset-db.sh

smoke:
	$(COMPOSE) --profile smoke run --rm smoke

db-check:
	sh scripts/db-check.sh

test-backend:
	docker build --target test --progress=plain backend

test-mobile:
	$(COMPOSE) --profile test run --rm --build flutter-tests

integration: up db-check smoke

prod-up:
	$(PROD) up -d --build --wait

prod-down:
	$(PROD) down
