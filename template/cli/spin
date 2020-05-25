(inherit (official bin))

(name cli)
(description "Command Line Interface releasable on Opam")

(ignore
  (files esy.json)
  (enabled_if (neq :package_manager Esy)))

(ignore
  (files Makefile)
  (enabled_if (neq :package_manager Opam)))

(generator
  (name cmd)
  (description "Generate a subcommand for the CLI.")

  (config cmd_name
    (input (prompt "Name of the subcommand"))
    (rules
      ("The command name must be a slug."
        (eq :cmd_name (slugify :cmd_name)))))

  (message (concat 
    "You need to add `Cmd_"
    (snake_case :cmd_name)
    ".cmd` to your list of commands in bin/main."
    (if (eq OCaml :syntax) ml re)))

  (post_gen
    (actions
      (refmt (concat bin/commands/cmd_ (snake_case :cmd_name) .ml)))
    (enabled_if (eq :syntax Reason)))

  (files
    (main.ml (concat bin/commands/cmd_ (snake_case :cmd_name) .ml)))
)
