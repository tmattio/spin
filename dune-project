(lang dune 2.7)

(name spin)

(source
 (github tmattio/spin))

(documentation "https://tmattio.github.io/spin/")

(license ISC)

(authors "Thibaut Mattio")

(maintainers "Thibaut Mattio")

(generate_opam_files true)

(cram enable)

(package
 (name spin)
 (synopsis "OCaml project generator")
 (description "OCaml project generator")
 (depends
  (ocaml
   (>= 4.08.0))
  dune
  (alcotest :with-test)
  (js_of_ocaml :with-test)
  (js_of_ocaml-ppx :with-test)
  (ppxlib :with-test)
  (ctypes :with-test)
  (odoc :with-doc)
  (crunch :build)
  (sexplib
   (>= v0.13))
  (spawn
   (>= v0.13))
  fmt
  fpath
  cmdliner
  logs
  jingoo))
