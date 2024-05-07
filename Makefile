.DEFAULT_GOAL := help
SHELL := $(shell which bash)

# Load .env variable
-include .env.dist
-include .env

.env: ## Create .env file if it's does not exist
	cp .env.dist .env

.PHONY: sync-env
sync-env: .env ## Add variables who did not exist in .env (from .env.dist)
	@while IFS='=' read -r k v; do \
	  if [[ ! -z "$$k" && ! -z "$$v" && $${k:0:1} != '#' ]]; then \
	    grep -q "^$$k=" .env; \
	    if [[ $$? -ne 0 ]]; then \
	      echo "Warning : $$k is declared in .env.dist but was not in .env (auto fixed)" >&2; \
	      echo "# Added by autofix :" >> .env; echo "$$k=$$v" >> .env; \
	    fi; \
	  fi; \
	done < .env.dist

.PHONY: bbash
bbash: sync-env ## connect to the back container
	docker compose exec back bash;

.PHONY: fbash
fbash: sync-env ## connect to the front container
	docker compose exec front bash;

.PHONY: migrate
migrate: sync-env ## Launch migration
	docker compose exec back composer -- run  console  doctrine:migrations:migrate -n

.PHONY: db-dev-mig
db-dev-mig: sync-env ## Force doctrine update from entities
	docker compose exec back composer -- run console doctrine\:schema\:update -f

db-mig-diff: sync-env ## Launch generate migration (recommended) from database diff
	# doctrine:schema:validate --skip-sync  is used to check the database mapping before generating the migration,
	# skip-sync is used to skip database and mapping sync validation
	docker compose exec back composer -- run console  doctrine:schema:validate --skip-sync
	docker compose exec back composer -- run console make:migration

.PHONY: migrate-diff
db-migrate-diff: sync-env ## Launch generate migration (not recommended)
	docker compose exec back composer -- run  console  doctrine:migrations:diff -n

.PHONY: blogs
blogs: ## Display logs of back
	docker compose logs back -f

.PHONY: flogs
flogs: sync-env ## Display logs of front
	docker compose logs front -f
.PHONY: init-dev
## We add `; \` to ignore error. `cp -n .env.dist .env;` could not work if .env exist already, it wont be replaced
init-dev: sync-env ## Init dev env
	cp -n .env.dist .env; \
	cp -n compose.override.yaml.template compose.override.yaml; \
	if uname | grep -iq "linux\|darwin"; then \
		echo "Add $(BASE_DOMAIN) and $(API_DOMAIN)  mail.${BASE_DOMAIN} and samltest.$(BASE_DOMAIN) to your /etc/hosts"; \
		if  grep -q $(BASE_DOMAIN) /etc/hosts ; then echo "not adding to /etc/hosts" ; else printf "\n127.0.0.1 $(BASE_DOMAIN) $(API_DOMAIN) samltest.$(BASE_DOMAIN) mail.${BASE_DOMAIN}\n" | sudo tee -a /etc/hosts ; fi \
    fi
#
# Theses are usefull when you use docker
#
.PHONY: down
down: sync-env ## down docker compose
	docker compose down

.PHONY: up
up: sync-env ## up docker compose
	DOCKER_BUILDKIT=1 docker compose up -d
	docker compose logs initback back front -f

.PHONY: fdown
fdown: sync-env ## stronger down (remove volume / image / orphans)
	docker compose down -v --remove-orphans

fup: sync-env ## stronger up (recreate all container and rebuild the image)
	DOCKER_BUILDKIT=1 docker compose up -d --force-recreate --build


.PHONY: restart
restart: down up ## Soft Restart

.PHONY: frestart
frestart: fdown fup ## Hard restart


.PHONY: fe-stop
fe-stop: sync-env ## stop front container
	DOCKER_BUILDKIT=1 docker compose stop front

.PHONY: fe-rm
fe-rm: sync-env ## remove front container
	DOCKER_BUILDKIT=1 docker compose rm front -f

.PHONY: fe-start
fe-start: sync-env ## start front container
	DOCKER_BUILDKIT=1 docker compose up  front -d

.PHONY: fe-restart
fe-restart: fe-stop fe-rm fe-start ## reset front container

.PHONY: dumpautoload
dumpautoload: sync-env ## dump the composer autoloader
	docker compose exec back composer -- dumpautoload

#
# Theses are static analyses + tests
#

.PHONY: phpmd
phpmd: sync-env ## phpMD
	docker compose exec back composer -- run phpmd

.PHONY: cs-fix
cs-fix: sync-env ## cs-fix
	docker compose exec back composer -- run cs-fix


.PHONY: cs-check
cs-check: sync-env ## cs-check
	docker compose exec back composer -- run cs-check

.PHONY: phpstan
phpstan: sync-env ## phpstan
	docker compose exec back composer -- run phpstan

be-yaml:
	docker compose exec back console -- bin/console lint:yaml config

.PHONY: fe-lint
fe-lint: sync-env ## lint front (fix)
	docker compose exec front yarn lint --fix

.PHONY: frontcheck
fe-check: sync-env ## lint front (check)
	docker compose exec front yarn lint

.PHONY: ci
ci: cs-fix phpstan phpmd cs-check fe-lint ## Run all CI tools

.PHONY: drop-db-dev
drop-db-dev: ## Drop database
	docker compose exec back bin/console doctrine:schema:drop --full-database --force

.PHONY: reset-db
reset-db: drop-db-dev migrate ## reset database and load fixtures
	docker compose exec back bin/console doctrine:fixtures:load -n --append

.PHONY: dump
dump: ## dump database in apps/back/dump/dump.sql (use git lfs)
	docker compose exec mysql mysqldump -u $(DATABASE_USERNAME) -p$(DATABASE_PASSWORD) $(DATABASE_NAME) > apps/back/dump/dump.sql
	gzip -f apps/back/dump/dump.sql
	git lfs track ./apps/back/dump/dump.sql.gz


.PHONY: network-prune
network-prune: ## Prune networks
	docker network prune
.PHONY: image-prune
image-prune: ## Prune images
	docker image prune -a
.PHONY: system-prune
system-prune: ## Prune system
	docker system prune -a
.PHONY: system-prune
system-prune-volumes: ## Prune system with --volumes /!\ Data will be lost
	docker system prune -a --volumes
prune: system-prune image-prune network-prune


.PHONY: help
help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
