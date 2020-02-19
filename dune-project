(lang dune 2.0)
(name spin)
(version 0.5.0)
(source (github tmattio/spin))
(documentation "https://tmattio.github.io/spin")
(license MIT)
(authors "Thibaut Mattio")
(maintainers "Thibaut Mattio")

(generate_opam_files true)

(package
 (name spin)
 (synopsis "Project scaffolding tool and set of templates for Reason and OCaml")
 (description "\
Project scaffolding tool and set of templates for Reason and OCaml
")
 (depends
  (ocaml (>= 4.06.0))
  (dune (>= 2.0))
  ; Add Rely when released on Opam
  ; (rely :with-test)
  (odoc :with-doc)
  (dune-release :dev)
  (merlin :dev)
  (utop :dev)
  (reason :build)
  base
  stdio
  cmdliner
  fileutils
  jingoo
  lwt
  ppx_sexp_conv
  sexplib))
