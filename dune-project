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
  (dune
   (>= 2.7))
  (alcotest :with-test)
  (odoc :with-doc)
  (crunch :build)
  base
  fmt
  fpath
  cmdliner
  logs
  sexplib
  (lwt
   (>= 5.3.0))
  jingoo
  (inquire
   (>= 0.2.1))))
