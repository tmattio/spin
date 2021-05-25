(lang dune 2.7)

(name spin)

(source
 (github tmattio/spin))

(documentation "https://tmattio.github.io/spin/")

(license MIT)

(authors "Thibaut Mattio")

(maintainers "Thibaut Mattio")

(generate_opam_files true)

(cram enable)

(package
 (name spin)
 (synopsis "A project generator for Reason and OCaml")
 (description "A project generator for Reason and OCaml\n")
 (depends
  (ocaml
   (>= 4.08.0))
  dune
  (alcotest :with-test)
  (reason :with-test)
  (odoc :with-doc)
  (crunch :build)
  (sexplib0
   (>= v0.13))
  (inquire
   (>= 0.3.0))
  (spawn
   (>= v0.13))
  fmt
  fpath
  cmdliner
  logs
  jingoo))
