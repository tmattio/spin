#!/bin/bash

version=main

set -e -o pipefail

TMP="$(mktemp -d)"
trap "rm -rf $TMP" EXIT

rm -rf ocaml-ansi
mkdir -p ocaml-ansi/src

(
  cd "$TMP"
  git clone https://github.com/tmattio/ocaml-ansi.git
  cd ocaml-ansi
  git checkout $version
)

SRC=$TMP/ocaml-ansi

cp -v "$SRC"/LICENSE ocaml-ansi
cp -v "$SRC"/lib/*.{ml,mli,c} ocaml-ansi/src
# git checkout ocaml-ansi/src/dune
