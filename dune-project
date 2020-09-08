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
   (and (>= 4.08.0) (< 4.11.0)))
  (dune
   (>= 2.7))
  (alcotest :with-test)
  (odoc :with-doc)
  (crunch :build)
  base
  stdio
  fmt
  fpath
  cmdliner
  logs
  sexplib
  (lwt
   (>= 5.3.0))
  jingoo
  reason
  ; Vendored zed
  base-bytes
  uucd
  uutf
  uuseg
  react
  ; Vendored lambda-term
  lwt_log
  lwt_react
  (mew_vi
   (= 0.3.0))
  uucp
  uunf
  uchar))
