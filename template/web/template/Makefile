.DEFAULT_GOAL := all

define BROWSER_PYSCRIPT
import os, webbrowser, sys

from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

BROWSER := python -c "$$BROWSER_PYSCRIPT"

ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(ARGS):;@:)

.PHONY: help
help: ## Print this help message
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(ARGS):;@:)

.PHONY: all
all:
	opam exec -- dune build --root . @install

.PHONY: dev
dev: ## Install development dependencies
	cd asset && npm install
	opam pin add -y ocaml-lsp-server https://github.com/ocaml/ocaml-lsp.git
	opam pin add -y opium_kernel https://github.com/rgrinberg/opium.git
	opam pin add -y opium https://github.com/rgrinberg/opium.git
	opam pin add -y opium-testing https://github.com/rgrinberg/opium.git
	opam install -y dune-release merlin ocamlformat utop ocaml-lsp-server omigrate

.PHONY: build
build: ## Build the project, including non installable libraries and executables
	opam exec -- dune build --root .

.PHONY: install
install: all ## Install the packages on the system
	opam exec -- dune install --root .

.PHONY: start
start: all ## Run the produced executable
	opam exec -- ./script/start-watch.sh $(ARGS)

.PHONY: migrate
migrate: ## Run database migrations
	OMIGRATE_DATABASE=postgres://localhost:5432/demo_dev \
	OMIGRATE_SOURCE=./migration \
	omigrate $(ARGS) -vv

.PHONY: migrate
migrate-test: ## Run database migrations for the test environment
	OMIGRATE_DATABASE=postgres://localhost:5432/demo_test \
	OMIGRATE_SOURCE=./migration \
	omigrate $(ARGS) -vv

.PHONY: test
test: ## Run the unit tests
	DEMO_ENV=test opam exec -- dune build --root . @test/runtest -f -j 1 $(ARGS)

.PHONY: clean
clean: ## Clean build artifacts and other generated files
	opam exec -- dune clean --root .

.PHONY: doc
doc: ## Generate odoc documentation
	opam exec -- dune build --root . @doc

.PHONY: servedoc
servedoc: doc ## Open odoc documentation with default web browser
	$(BROWSER) _build/default/_doc/_html/index.html

.PHONY: format
format: ## Format the codebase with ocamlformat
	opam exec -- dune build --root . --auto-promote @fmt

.PHONY: watch
watch: ## Watch for the filesystem and rebuild on every change
	opam exec -- dune build --root . --watch

.PHONY: utop
utop: ## Run a REPL and link with the project's libraries
	opam exec -- dune utop --root . lib -- -implicit-bindings
