open Cmdliner

let () = Printexc.record_backtrace true

let cmds = [ Cmd_config.cmd; Cmd_ls.cmd; Cmd_new.cmd; Cmd_hello.cmd ]

let run () =
  let message =
    {|
Generate OCaml projects.

Usage:
  spin COMMAND

Available Commands:
  config      Update the current user's configuration
  ls          List the official templates
  new         Generate a new project from a template
  hello       Generate the tutorial project

Useful options:
       --help      Show manual page
  --v, --verbose   Increase verbosity
       --version   Show spin version

For a complete documentation, refer to the manual with `spin --help`.

Use `spin COMMAND --help` for help on a single command.|}
  in
  print_endline message;
  0

(* Command line interface *)

let doc = "Generate OCaml projects"

let sdocs = Manpage.s_common_options

let exits = Common.exits

let envs = Common.envs

let man =
  [ `S Manpage.s_description
  ; `P "$(mname) helps to bootstrap OCaml projects."
  ; `P
      "It can generate new projects from local or remote templates, and \
       generate components in existing projects."
  ; `P
      "$(mname) comes with a set of official templates that have been crafted \
       with developer experience in mind. They all include a CI/CD pipeline \
       and projects that are deployable (e.g. libraries, web servers) also \
       come with automated release scripts."
  ; `P "You can list the official templates with `$(mname) ls`"
  ; `P "Use `$(mname) $(i,COMMAND) --help' for help on a single command."
  ; `S Manpage.s_commands
  ; `S Manpage.s_examples
  ; `P
      "The following commands will create a new command line interface and \
       generate a subcommand $(b,my-cmd) in it."
  ; `Noblank
  ; `Pre {|
    \$ spin new cli my-cli
    \$ cd my-cli
    \$ make build|}
  ; `S Manpage.s_common_options
  ; `S Manpage.s_exit_status
  ; `S Manpage.s_environment
  ; `P "These environment variables affect the execution of $(mname):"
  ; `S Manpage.s_bugs
  ; `P "File bug reports at $(i,%%PKG_ISSUES%%)"
  ; `S Manpage.s_authors
  ; `P "Thibaut Mattio, $(i,https://github.com/tmattio)"
  ]

let default_cmd =
  let term =
    let open Common.Syntax in
    let+ _term = Common.term in
    run ()
  in
  let info = Term.info "spin" ~version:"%%VERSION%%" in
  term, info

let main =
  ( fst default_cmd
  , Term.info "spin" ~version:"%%VERSION%%" ~doc ~sdocs ~exits ~man ~envs )

let () = Term.(exit_status @@ eval_choice main cmds)
