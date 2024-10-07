open Cmdliner

(* List of available commands *)
let cmds = [ Cmd_new.cmd ]

(* Main run function for default command *)
let run () =
  let message =
    {|
Spin: Generate and manage OCaml projects with ease.

Usage:
  spin COMMAND [OPTIONS]

Available Commands:
  config      Update the current user's configuration
  ls          List the official templates
  new         Generate a new project from a template
  hello       Generate the tutorial project

Useful options:
       --help      Show manual page
  -v, --verbose    Increase verbosity
       --version   Show spin version

Examples:
  spin new cli my-cli            Create a new CLI project named 'my-cli'
  spin ls                        List available official templates
  spin config set author "John Doe"  Set the author name in the configuration

For complete documentation, run `spin --help`.
Use `spin COMMAND --help` for help on a single command.|}
  in
  print_endline message;
  0

(* Command line interface *)

let doc = "Generate and manage OCaml projects"

let sdocs = Manpage.s_common_options

let exits = Common.exits

let envs = Common.envs

let man =
  [ `S Manpage.s_description
  ; `P "$(mname) is a powerful tool for generating and managing OCaml projects."
  ; `P
      "It can generate new projects from local or remote templates, and \
       generate components in existing projects. Spin streamlines the setup \
       process and encourages best practices in OCaml development."
  ; `P
      "$(mname) comes with a set of official templates that have been crafted \
       with developer experience in mind. They all include a CI/CD pipeline \
       and projects that are deployable (e.g. libraries, web servers) also \
       come with automated release scripts."
  ; `P "You can list the official templates with `$(mname) ls`"
  ; `S Manpage.s_commands
  ; `P "Here's a brief overview of the available commands:"
  ; `I ("config", "Update the current user's configuration")
  ; `I ("ls", "List the official templates")
  ; `I ("new", "Generate a new project from a template")
  ; `I ("hello", "Generate the tutorial project")
  ; `P "Use `$(mname) $(i,COMMAND) --help' for help on a single command."
  ; `S Manpage.s_examples
  ; `P "Here are some common usage scenarios:"
  ; `Pre {|
    # Create a new CLI project
    $ spin new cli my-cli
    $ cd my-cli
    $ make build

    # List available templates
    $ spin ls

    # Set up user configuration
    $ spin config set author "John Doe"
    $ spin config set email "john.doe@example.com"

    # Generate a tutorial project
    $ spin hello my-tutorial|}
  ; `S "CONFIGURATION"
  ; `P
      "$(mname) uses a configuration file to store user preferences. You can \
       view and modify this configuration using the `config` command."
  ; `S Manpage.s_common_options
  ; `S Manpage.s_exit_status
  ; `S Manpage.s_environment
  ; `P "These environment variables affect the execution of $(mname):"
  ; `S Manpage.s_bugs
  ; `P "File bug reports at $(i,%%PKG_ISSUES%%)"
  ; `S Manpage.s_authors
  ; `P "Thibaut Mattio, $(i,https://github.com/tmattio)"
  ]

(* Default command setup *)
let default_cmd, default_info =
  let term =
    let open Common.Syntax in
    let+ _term = Common.term in
    run ()
  in
  let info = Cmd.info "spin" ~version:"%%VERSION%%" ~doc ~sdocs ~exits ~envs ~man in
  term, info

(* Group all commands *)
let group = Cmd.group ~default:default_cmd default_info cmds

(* Main entry point *)
let () = 
  try
    exit @@ Cmd.eval' group
  with
  | exn ->
      prerr_endline ("Error: " ^ Printexc.to_string exn);
      exit 1
  