DOCKER_COMPOSE := $(shell command -v docker-compose >/dev/null 2>&1 && echo docker-compose || echo docker compose)

LIMA_NAME    ?= diploma-fix
LIMA_PROJECT := /Users/valerijpetrov/Documents/диплом/diploma-fix

.PHONY: help up down restart ps logs rebuild clean clean-all status sample \
        lima-up lima-shell lima-stack lima-down lima-clean lima-status

help:
	@echo "diploma-fix — простые команды управления"
	@echo ""
	@echo "  make up         — поднять весь стек (init-БД + сервисы) с автоматической сборкой"
	@echo "  make down       — остановить и удалить контейнеры (тома сохранены)"
	@echo "  make restart    — пересоздать сервисы без потери данных"
	@echo "  make rebuild    — полная пересборка без кэша"
	@echo "  make ps         — статус всех контейнеров"
	@echo "  make logs       — все логи (Ctrl+C для выхода)"
	@echo "  make clean      — down + удалить тома (внимание: данные стираются)"
	@echo "  make clean-all  — clean + prune builder cache"
	@echo "  make status     — проверить /health"
	@echo "  make sample     — отправить тестовый .c файл через API"
	@echo ""
	@echo "  Опционально, только если нужна cache-стадия на Apple Silicon"
	@echo "  (wine+qemu-user не запускает CacheSim.exe; внутри VM работает нативно):"
	@echo "  make lima-up     — поднять Ubuntu 22.04 amd64 VM с docker внутри"
	@echo "  make lima-shell  — открыть shell внутри VM"
	@echo "  make lima-stack  — внутри VM запустить весь стек (docker compose up -d)"
	@echo "  make lima-status — статус контейнеров внутри VM"
	@echo "  make lima-down   — остановить VM (диск и образы сохраняются)"
	@echo "  make lima-clean  — удалить VM полностью"

up:
	$(DOCKER_COMPOSE) up -d --build

down:
	$(DOCKER_COMPOSE) down

restart:
	$(DOCKER_COMPOSE) up -d --build --force-recreate

rebuild:
	$(DOCKER_COMPOSE) build --no-cache
	$(DOCKER_COMPOSE) up -d

ps:
	$(DOCKER_COMPOSE) ps

logs:
	$(DOCKER_COMPOSE) logs -f --tail=200

clean:
	$(DOCKER_COMPOSE) down -v

clean-all: clean
	docker builder prune -f

status:
	@echo "==> nginx /health"
	@curl -s http://localhost:$${NGINX_PORT:-8080}/health || true
	@echo ""
	@echo "==> core-api /health (через nginx)"
	@curl -s http://localhost:$${NGINX_PORT:-8080}/api/v1/auth -X OPTIONS -o /dev/null -w "auth route http: %{http_code}\n" || true
	@echo "==> Откройте http://localhost:$${NGINX_PORT:-8080}/"

sample:
	@if [ ! -f samples/loop.c ]; then echo "samples/loop.c не найден"; exit 1; fi
	@echo "Отправка примера для smoke-тестирования (нужен залогиненный токен в TOKEN)"
	@if [ -z "$$TOKEN" ]; then echo "Установите TOKEN=<jwt> в окружении"; exit 1; fi
	@curl -s -X POST http://localhost:$${NGINX_PORT:-8080}/api/v1/analysis/upload \
		-H "Authorization: Bearer $$TOKEN" \
		-F "project_id=$$PROJECT_ID" \
		-F "file=@samples/loop.c" | jq .

# ----------------------------------------------------------------------------
# Lima x86_64 VM — опция для Apple Silicon. Базовый `make up` ничего про Lima
# не знает; Lima нужен ровно тогда, когда требуется cache-стадия пайплайна,
# потому что CacheSim.exe (Win64 PE) под wine+qemu-user на ARM крашится.
# ----------------------------------------------------------------------------

lima-up:
	@command -v limactl >/dev/null || { echo "limactl не найден. Поставьте: brew install lima"; exit 1; }
	@if limactl list -q | grep -qx $(LIMA_NAME); then \
		echo "VM '$(LIMA_NAME)' уже создана — стартую"; \
		limactl start $(LIMA_NAME); \
	else \
		echo "Создаю VM '$(LIMA_NAME)' (первый запуск ~10-20 минут: качается образ + cloud-init)"; \
		limactl start --name=$(LIMA_NAME) --tty=false ./lima.yaml; \
	fi
	@echo ""
	@echo "VM поднята. Проверка docker внутри:"
	@limactl shell $(LIMA_NAME) -- sg docker -c 'docker version --format "{{.Server.Version}}"' || true

lima-shell:
	@limactl shell $(LIMA_NAME)

# sg docker -c "..." нужен из-за cloud-init: пользователь lima был добавлен в
# группу docker, но текущая shell-сессия limactl не перечитывает /etc/group.
# Без sg получаем "permission denied while trying to connect to docker.sock".
lima-stack:
	@echo "==> Поднимаю docker compose стек внутри VM (с override docker-compose.lima.yml)"
	@limactl shell $(LIMA_NAME) -- bash -lc 'cd $(LIMA_PROJECT)/diploma-infra && [ -f .env ] || cp .env.example .env && sg docker -c "docker compose --env-file .env -f docker-compose.yml -f docker-compose.lima.yml up -d --build"'
	@echo ""
	@echo "==> Статус:"
	@limactl shell $(LIMA_NAME) -- sg docker -c 'docker ps --format "table {{.Names}}\t{{.Status}}"'
	@echo ""
	@echo "Открывайте: http://localhost:$${NGINX_PORT:-8080}"

lima-status:
	@limactl shell $(LIMA_NAME) -- sg docker -c 'docker ps --format "table {{.Names}}\t{{.Status}}"'

lima-down:
	@limactl stop $(LIMA_NAME) || true

lima-clean:
	@limactl stop $(LIMA_NAME) || true
	@limactl delete $(LIMA_NAME) || true
