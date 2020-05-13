let run ~ignore_config ~use_defaults ~generator =
  let _ = ignore_config, use_defaults, generator in
  Caml.print_endline "Hi";
  Ok ()

(* Command line interface *)

open Cmdliner

let doc = "Generate a new component in the current project"

let sdocs = Manpage.s_common_options

let exits = Common.exits

let envs = Common.envs

let man_xrefs = [ `Main; `Cmd "new" ]

let man =
  [ `S Manpage.s_description
  ; `P
      "$(tname) generates new files in the current project if a generator is \
       provided, or list the available generators for the current project if \
       not."
  ; `P
      "$(tname) assumes it is run in a project generated with spin-new(1), it \
       will read the source template of the project from the file `.spin` \
       located at the root of the project. If the source is not a local \
       directory and cannot be found in the cache, it will be downloaded \
       before the generator is run."
  ; `P
      "If the provided generator exists in the source template, the user will \
       be prompted for the configurations of the generator and the generator \
       will be run at the root of the project."
  ]

let info = Term.info "gen" ~doc ~sdocs ~exits ~envs ~man ~man_xrefs

let term =
  let open Common.Let_syntax in
  let+ _term = Common.term
  and+ ignore_config = Common.ignore_config_arg
  and+ use_defaults = Common.use_defaults_arg
  and+ generator =
    let doc =
      "The generator to use. If absent, list the available generators for the \
       current project."
    in
    let docv = "GENERATOR" in
    Arg.(value & pos 0 (some string) None & info [] ~doc ~docv)
  in
  run ~ignore_config ~use_defaults ~generator |> Common.handle_errors

let cmd = term, info
