(inherit (official bin))

(name js)
(description "Javascript application with Js_of_ocaml")

(ignore
  (files esy.json)
  (enabled_if (neq :package_manager Esy)))

(ignore
  (files package.json)
  (enabled_if (eq :package_manager Esy)))

(ignore
  (files Makefile)
  (enabled_if (neq :package_manager Opam)))
