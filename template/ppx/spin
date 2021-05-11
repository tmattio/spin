(inherit (official bin))

(name ppx)
(description "PPX library")

(ignore 
  (files (concat "test/" :package_snake "_test.ml")))

(ignore
  (files esy.json)
  (enabled_if (neq :package_manager Esy)))

(ignore
  (files Makefile)
  (enabled_if (neq :package_manager Opam)))
