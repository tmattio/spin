ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(ARGS):;@:)

.PHONY: all
all:
	opam exec -- dune build --root . @install

.PHONY: dev
dev:
	opam pin add ocaml-lsp-server https://github.com/ocaml/ocaml-lsp.git
	opam install -y dune-release merlin ocamlformat utop ocaml-lsp-server
	{%- if test_framework == 'Rely' %}
	opam pin add -y pastel https://github.com/facebookexperimental/reason-native.git
	opam pin add -y cli https://github.com/facebookexperimental/reason-native.git
	opam pin add -y file-context-printer https://github.com/facebookexperimental/reason-native.git
	opam pin add -y rely https://github.com/facebookexperimental/reason-native.git
	{%- endif %}
	opam install --deps-only --with-test --with-doc -y .

.PHONY: build
build:
	opam exec -- dune build --root .

.PHONY: start
start: all
	opam exec -- dune exec bin/main.exe $(ARGS)

.PHONY: install
install:
	opam exec -- dune install --root .

.PHONY: test
test:
	opam exec -- {% if test_framework == 'Rely' %}dune exec --root . test/test_runner.exe{% else %}dune build --root . @test/runtest -f{% endif %}

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
	opam exec -- dune build --root . --auto-promote @fmt

.PHONY: watch
watch:
	opam exec -- dune build --root . --watch

.PHONY: utop
utop:
	opam exec -- dune utop --root . lib -- -implicit-bindings

.PHONY: release
release:
	opam exec -- sh script/release.sh
