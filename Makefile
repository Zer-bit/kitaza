.DEFAULT_GOAL := help
.PHONY: help setup check test fmt lint run-api run-app stack stack-down clean

help: ## Show this help
	@grep -E '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

setup: ## Install dependencies for both codebases
	cd backend && cargo fetch
	cd frontend && flutter pub get

check: lint test ## Everything CI runs

test: ## Run all tests
	cd backend && cargo test
	cd frontend && flutter test

lint: ## Analyse and check formatting
	cd backend && cargo clippy --all-targets -- -D warnings && cargo fmt --check
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
