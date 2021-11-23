(lang dune 2.8)

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
   (>= 4.10.0))
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
  (stdio
   (>= v0.13))
  (jingoo
   (>= 1.4.0))
  (fmt
   (>= 0.8.9))
  fpath
  cmdliner
  logs))

(package
 (name opam-spin)
 (synopsis "Opam plugin for Spin, the OCaml project generator")
 (description "Opam plugin for Spin, the OCaml project generator")
 (depends
  (ocaml
   (>= 4.10.0))
  dune
  (spin
   (= :version))))
