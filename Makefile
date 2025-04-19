.PHONY: help
help: ## List all the command helps.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: init-pre-commit
init-pre-commit: ## Init pre-commit.
	@pre-commit install
	@pre-commit install --hook-type commit-msg

.PHONY: test
test: ## Run tests.
	@mix dialyzer
	@mix test

.PHONY: format
format: ## Format code.
	@mix format

.PHONY: lint
lint: ## Check linter (Credo).
	@mix credo --strict

.PHONY: coverage
coverage: ## Run tests with coverage.
	@mix test --cover

.PHONY: deps
deps: ## Get dependencies.
	@mix deps.get

.PHONY: compile
compile: ## Compile project.
	@mix compile

.PHONY: clean
clean: ## Clean build artifacts.
	@mix clean

.PHONY: ci
ci: format lint test ## Run CI.

.PHONY: run
run: ## Run the application.
	@mix run --no-halt

.PHONY: iex
iex: ## Start interactive Elixir shell with project loaded.
	@iex -S mix

.PHONY: bump-version
bump-version: check-version ## Bump version, define target version with "VERSION=*.*.*".
	@sed -i '' "s/version: \".*\"/version: \"$(VERSION)\"/" mix.exs
	@echo "Version replaced by $(VERSION) in 'mix.exs'"

check-version:
ifndef VERSION
	$(error VERSION is undefined)
endif

.PHONY: release
release: ## Create a release build.
	@MIX_ENV=prod mix release

.DEFAULT_GOAL := help
