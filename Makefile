.DEFAULT_GOAL := help
.PHONY: help setup check test test-integration test-contract brand backup restore fmt lint run-api run-app release-apk release-bundle stack stack-down clean

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

# A release build has to be told where the API lives. Without it the app
# carries the developer default, which points at a machine the owner's phone
# cannot reach, and cloud mode simply never connects.
RELEASE_DEFINES = \
	--dart-define=KITAZA_API_URL=$(KITAZA_API_URL) \
	--dart-define=KITAZA_WS_URL=$(KITAZA_WS_URL)

check-release-config:
	@test -n "$(KITAZA_API_URL)" -a -n "$(KITAZA_WS_URL)" || { printf '%s\n' \
		"Tell the build where the API lives, for example:" \
		"  make $(MAKECMDGOALS) KITAZA_API_URL=https://api.kitaza.ph/api/v1 KITAZA_WS_URL=wss://api.kitaza.ph"; exit 2; }
	@test -f frontend/android/key.properties || { printf '%s\n' \
		"No frontend/android/key.properties, so the release could not be signed." \
		"Copy frontend/android/key.properties.example and fill it in."; exit 2; }

release-apk: check-release-config ## Signed APKs to hand out directly, one per processor
	cd frontend && flutter build apk --release --split-per-abi $(RELEASE_DEFINES)

release-bundle: check-release-config ## Signed app bundle to upload to Play
	cd frontend && flutter build appbundle --release $(RELEASE_DEFINES)

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
