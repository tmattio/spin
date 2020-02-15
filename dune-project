(lang dune 1.11)
(name spin)
(version 0.1.0)
(source (github tmattio/spin))
(documentation "https://tmattio.github.io/spin")
(license MIT)
(authors "Thibaut Mattio")
(maintainers "Thibaut Mattio")

(using fmt 1.2)
(generate_opam_files true)

(package
 (name spin)
 (synopsis "Project scaffolding tool and set of templates for Reason and OCaml")
 (description "Project scaffolding tool and set of templates for Reason and OCaml")
 (depends
  (ocaml (>= 4.06.0))
  (alcotest :with-test)
  (dune (and :build (>= 1.6.0)))
  (dune-release :dev)
  base
  cmdliner
  fileutils
  jingoo
  lwt
  lwt_ppx
  ppx_let
  ppx_sexp_conv
  sexplib))
