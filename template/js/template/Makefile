.DEFAULT_GOAL := all

ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(ARGS):;@:)

.PHONY: all
all:
	opam exec -- dune build --root . @install

.PHONY: deps
deps: ## Install development dependencies
	opam install -y dune-release ocamlformat utop ocaml-lsp-server
	{%- if test_framework == 'Rely' %}
	opam pin add -y pastel https://github.com/facebookexperimental/reason-native.git
	opam pin add -y cli https://github.com/facebookexperimental/reason-native.git
	opam pin add -y file-context-printer https://github.com/facebookexperimental/reason-native.git
	opam pin add -y rely https://github.com/facebookexperimental/reason-native.git
	{%- endif %}
	npm install
	opam install --deps-only --with-test --with-doc -y .

.PHONY: create_switch
create_switch:
	{%- if syntax == 'Reason' %}
	opam switch create . 4.10.0 --no-install
	{%- else %}
	opam switch create . --no-install
	{%- endif %}

.PHONY: switch
switch: ## Create an opam switch and install development dependencies
	opam install . --deps-only --with-doc --with-test
	opam install -y dune-release ocamlformat utop ocaml-lsp-server

.PHONY: lock
lock: ## Generate a lock file
	opam lock -y .

.PHONY: build
build: ## Build the project, including non installable libraries and executables
	opam exec -- dune build --root .

.PHONY: install
install: all ## Install the packages on the system
	opam exec -- dune install --root .

.PHONY: start
start: all ## Run the produced executable
	cd _build/default && npm start

.PHONY: test
test: ## Run the unit tests
	opam exec -- dune runtest --root .

.PHONY: clean
clean: ## Clean build artifacts and other generated files
	opam exec -- dune clean --root .

.PHONY: doc
doc: ## Generate odoc documentation
	opam exec -- dune build --root . @doc

.PHONY: servedoc
servedoc: doc ## Open odoc documentation with default web browser
	open _build/default/_doc/_html/index.html

.PHONY: fmt
fmt: ## Format the codebase with ocamlformat
	opam exec -- dune build --root . --auto-promote @fmt

.PHONY: watch
watch: ## Watch for the filesystem and rebuild on every change
	opam exec -- dune build --root . --watch

.PHONY: utop
utop: ## Run a REPL and link with the project's libraries
	opam exec -- dune utop --root . lib -- -implicit-bindings
