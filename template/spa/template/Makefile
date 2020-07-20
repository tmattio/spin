ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(ARGS):;@:)

.PHONY: all
all:
	opam exec -- dune build --root . @install

.PHONY: dev
dev:
	opam install -y dune-release merlin ocamlformat utop
	opam install --deps-only --with-test --with-doc -y .

.PHONY: build
build:
	opam exec -- dune build --root .

.PHONY: install
install:
	opam exec -- dune install --root .

.PHONY: start
start: all
	opam exec -- dune exec --root . bin/main.exe $(ARGS)

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
