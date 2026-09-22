.DEFAULT_GOAL := help
.PHONY: help setup check test test-integration test-contract brand backup restore fmt lint run-api run-app stack stack-down clean

help: ## Show this help
	@grep -E '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

setup: ## Install dependencies for both codebases
	cd backend && cargo fetch
	cd frontend && flutter pub get

check: lint test ## Everything CI runs

test: ## Run all tests
	cd backend && cargo test
	cd frontend && flutter test

# Integration tests create a fresh database per test, so the user needs
# CREATEDB. The default points at the docker-compose Postgres.
TEST_DATABASE_URL ?= postgres://kitaza:kitaza@localhost:5432/kitaza

test-integration: ## Backend tests against a real Postgres (TEST_DATABASE_URL)
	cd backend && DATABASE_URL=$(TEST_DATABASE_URL) cargo test --features integration

CONTRACT_API ?= http://localhost:8080/api/v1

test-contract: ## Two simulated phones syncing through a running API (CONTRACT_API)
	cd frontend && KITAZA_CONTRACT_API=$(CONTRACT_API) flutter test test/contract

brand: ## Regenerate logo, launcher icons and splash from the source glyph
	cd frontend && ./tool/generate_brand_assets.sh

backup: ## Take a database backup now into ./backups
	docker compose run --rm backup /scripts/backup.sh

restore: ## Restore a dump over the database: make restore DUMP=backups/<file>
	@test -n "$(DUMP)" || (echo "usage: make restore DUMP=backups/kitaza-....dump" && exit 2)
	@# One quoted string: the container's entrypoint is `sh -c`, which runs only
	@# its first argument, so separate words would never reach the script.
	docker compose run --rm -v "$(CURDIR)/$(DUMP):/restore.dump:ro" backup \
		"/scripts/restore.sh /restore.dump postgres://kitaza:kitaza@postgres:5432/kitaza --yes-replace-everything"

lint: ## Analyse and check formatting
	cd backend && cargo clippy --all-targets --features integration -- -D warnings && cargo fmt --check
	cd frontend && flutter analyze && dart format --set-exit-if-changed lib test

fmt: ## Format both codebases
	cd backend && cargo fmt
	cd frontend && dart format lib test

stack: ## Start Postgres, Redis and the API
	docker compose up --build -d

stack-down: ## Stop the stack
	docker compose down

run-api: ## Run the API against a local Postgres and Redis
	cd backend && cargo run

run-app: ## Run the Flutter app against a local API
	cd frontend && flutter run \
		--dart-define=KITAZA_API_URL=http://10.0.2.2:8080/api/v1 \
		--dart-define=KITAZA_WS_URL=ws://10.0.2.2:8080

clean: ## Remove build artefacts
	cd backend && cargo clean
	cd frontend && flutter clean
