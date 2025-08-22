.PHONY: up down logs rebuild bash migrate seed

# Compose lives in infra/docker
COMPOSE = docker compose -f infra/docker/compose.yml

up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f --tail=200

rebuild:
	$(COMPOSE) build --no-cache

bash:
	$(COMPOSE) exec api bash

migrate:
	$(COMPOSE) exec api alembic upgrade head

seed:
	$(COMPOSE) exec api python -m app.scripts.seed
