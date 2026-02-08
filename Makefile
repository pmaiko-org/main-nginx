COMPOSE_BASE = docker-compose.yaml
NETWORK_NAME = shared_network


.PHONY: build down rebuild logs ps

build: create-network
	docker compose --env-file .env -f $(COMPOSE_BASE) up --build -d --remove-orphans

down:
	docker compose --env-file .env -f $(COMPOSE_BASE) down

rebuild:
	docker compose --env-file .env -f $(COMPOSE_BASE) build --no-cache

logs:
	docker compose --env-file .env -f $(COMPOSE_BASE) logs -f

ps:
	docker compose ps

create-network:
	@docker network inspect $(NETWORK_NAME) > /dev/null 2>&1 || \
	docker network create $(NETWORK_NAME)
	@echo "Network '$(NETWORK_NAME)' is ready"

remove-network:
	@docker network rm $(NETWORK_NAME) 2>/dev/null || \
	echo "Network '$(NETWORK_NAME)' does not exist"
	@echo "Network '$(NETWORK_NAME)' removed"

list-networks:
	@docker network ls
