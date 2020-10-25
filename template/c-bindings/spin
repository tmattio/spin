(inherit (official lib))

(name c-bindings)
(description "Bindings to a C library")

(ignore
  (files esy.json)
  (enabled_if (neq :package_manager Esy)))

(ignore
  (files Makefile)
  (enabled_if (neq :package_manager Opam)))

(post_gen
  (actions
    (refmt example/*.ml example/*.mli))
  (enabled_if (eq :syntax Reason)))
