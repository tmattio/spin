(lang dune 2.4)
(name spin)
(source (github tmattio/spin))
(documentation "https://github.com/tmattio/spin")
(license MIT)
(authors "Thibaut Mattio")
(maintainers "Thibaut Mattio")

(generate_opam_files true)

(using mdx 0.1)

(package
 (name spin)
 (synopsis "A project generator for Reason and OCaml")
 (description "\
A project generator for Reason and OCaml
")
 (depends
  (ocaml (>= 4.08.0))
  (dune (>= 2.4))
  (mdx :with-test)
  (alcotest :with-test)
  (odoc :with-doc)
  (crunch :build)
  base
  fmt
  fpath
  cmdliner
  logs
  sexplib
  (lwt (>= 5.3.0))
  jingoo
  reason
  (inquire (>= 0.2.0))))
