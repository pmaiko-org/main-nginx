COMPOSE_BASE = docker-compose.yaml

.PHONY: build down rebuild logs ps

build:
	docker compose --env-file .env -f $(COMPOSE_BASE) up --build --remove-orphans

down:
	docker compose --env-file .env -f $(COMPOSE_BASE) down

rebuild:
	docker compose --env-file .env -f $(COMPOSE_BASE) build --no-cache

logs:
	docker compose --env-file .env -f $(COMPOSE_BASE) logs -f

ps:
	docker compose ps
