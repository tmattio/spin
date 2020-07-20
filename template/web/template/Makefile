ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(ARGS):;@:)

.PHONY: all
all:
	opam exec -- dune build --root . @install

.PHONY: clean
clean:
	opam exec -- dune clean --root .

.PHONY: dev
dev:
	cd asset && npm install
	opam pin add -y ocaml-lsp-server https://github.com/ocaml/ocaml-lsp.git
	opam pin add -y opium_kernel https://github.com/rgrinberg/opium.git
	opam pin add -y opium https://github.com/rgrinberg/opium.git
	opam install -y dune-release merlin ocamlformat utop ocaml-lsp-server omigrate
	opam install --deps-only --with-test --with-doc -y .

.PHONY: build
build:
	opam exec -- dune build --root .

.PHONY: build-prod
build-prod: clean
	DEMO_ENV=production opam exec -- dune build --root . -f --profile release

.PHONY: start
start: all
	opam exec -- ./script/start-watch.sh $(ARGS)


.PHONY: migrate
migrate:
	OMIGRATE_DATABASE=postgres://localhost:5432/demo_dev \
	OMIGRATE_SOURCE=./migration \
	omigrate $(ARGS) -vv

.PHONY: migrate
migrate-test:
	OMIGRATE_DATABASE=postgres://localhost:5432/demo_test \
	OMIGRATE_SOURCE=./migration \
	omigrate $(ARGS) -vv

.PHONY: install
install:
	opam exec -- dune install --root .

.PHONY: uninstall
uninstall:
	opam exec -- dune uninstall --root .

.PHONY: test
test:
	DEMO_ENV=test opam exec -- dune build --root . @test/runtest -f -j 1 $(ARGS)

.PHONY: doc
doc:
	opam exec -- dune build --root . @doc

.PHONY: doc-path
doc-path:
	@echo "_build/default/_doc/_html/index.html"

.PHONY: format
format:
	opam exec -- dune build --root . @fmt --auto-promote

.PHONY: watch
watch:
	opam exec -- dune build --root . --watch

.PHONY: utop
utop:
	opam exec -- dune utop --root . lib -- -implicit-bindings
