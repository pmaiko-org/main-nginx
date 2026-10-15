COMPOSE_BASE = docker-compose.yaml
NETWORK_NAME = shared_network
VOLUME_NAMES = \
	main-nginx-netdata-config \
	main-nginx-netdata-lib \
	main-nginx-netdata-cache \
	main-nginx-portainer-data
HTPASSWD_FILE = secrets/.htpasswd


.PHONY: build down rebuild logs ps reload check-config \
	create-network remove-network list-networks \
	create-volumes list-volumes \
	check-htpasswd htpasswd

build: check-htpasswd create-network create-volumes down
	docker compose --env-file .env -f $(COMPOSE_BASE) up --build -d --remove-orphans

down:
	docker compose --env-file .env -f $(COMPOSE_BASE) down --remove-orphans --volumes

rebuild:
	docker compose --env-file .env -f $(COMPOSE_BASE) build --no-cache

logs:
	docker compose --env-file .env -f $(COMPOSE_BASE) logs -f

ps:
	docker compose ps

check-config:
	docker compose exec -T nginx nginx -t

reload: check-config
	docker compose exec -T nginx nginx -s reload

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

create-volumes:
	@for volume in $(VOLUME_NAMES); do \
		docker volume inspect $$volume > /dev/null 2>&1 || \
		docker volume create $$volume > /dev/null; \
		echo "Volume '$$volume' is ready"; \
	done

list-volumes:
	@docker volume ls --filter name=main-nginx-

check-htpasswd:
	@test -s $(HTPASSWD_FILE) || { \
		echo "Error: '$(HTPASSWD_FILE)' is missing or empty."; \
		echo "Run 'make htpasswd HTPASSWD_USER=<name>' to create it."; \
		exit 1; \
	}
	@echo "Basic auth file '$(HTPASSWD_FILE)' is ready"

htpasswd:
	@test -n "$(HTPASSWD_USER)" || { \
		echo "Usage: make htpasswd HTPASSWD_USER=<name>"; \
		exit 1; \
	}
	@mkdir -p $(dir $(HTPASSWD_FILE))
	@printf "Password for '%s': " "$(HTPASSWD_USER)"; \
	stty -echo 2>/dev/null; read -r password; stty echo 2>/dev/null; echo; \
	test -n "$$password" || { echo "Error: empty password"; exit 1; }; \
	printf '%s' "$$password" | \
	docker run --rm -i httpd:2.4-alpine htpasswd -niB "$(HTPASSWD_USER)" | \
	sed '/^$$/d' >> $(HTPASSWD_FILE)
	@echo "User '$(HTPASSWD_USER)' added to '$(HTPASSWD_FILE)'"
