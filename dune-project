(lang dune 3.17)

(name spin)

(source
 (github tmattio/spin))

(authors "Thibaut Mattio")

(maintainers "Thibaut Mattio")

(license ISC)

(package
 (name spin)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends ocaml dune yaml jingoo))

(package
 (name spin-cli)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends spin cmdliner logs fmt))
