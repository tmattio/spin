ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(ARGS):;@:)

.PHONY: all
all:
	opam exec -- dune build --root . @install

.PHONY: dev
dev:
	opam pin add -y ocaml-lsp-server https://github.com/ocaml/ocaml-lsp.git
	opam install -y dune-release merlin ocamlformat utop ocaml-lsp-server
	opam install --deps-only --with-test --with-doc -y .

.PHONY: build
build:
	opam exec -- dune build --root .

.PHONY: install
install:
	opam exec -- dune install --root .

.PHONY: start
start: build
	cd asset && npm start

.PHONY: test
test:
	opam exec -- dune build --root . @test/runtest -f

.PHONY: clean
clean:
	opam exec -- dune clean --root .

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
