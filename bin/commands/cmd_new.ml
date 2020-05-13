open Spin

let run ~ignore_config ~use_defaults ~template ~path =
  let open Result.Let_syntax in
  let path = Option.value path ~default:Filename.current_dir_name in
  let* context =
    if ignore_config then
      Ok None
    else
      let* user_config = User_config.read () in
      match user_config with
      | None ->
        Logs.app (fun m ->
            m
              "\n\
               ⚠️ No config file found. To save some time in the future, \
               create one with %a"
              Pp.pp_blue
              "spin config");
        Ok None
      | Some user_config ->
        let context = User_config.to_context user_config in
        Ok (Some context)
  in
  match Template.source_of_string template with
  | Some source ->
    let result =
      let open Lwt_result.Syntax in
      let* template = Template.read ?context ~use_defaults source in
      Template.generate ~path template
    in
    let+ _ = Lwt_main.run result in
    ()
  | None ->
    Logs.err (fun m -> m "This template does not exist");
    Ok ()

(* Command line interface *)

open Cmdliner

let doc = "Generate a new project from a template"

let sdocs = Manpage.s_common_options

let exits = Common.exits

let envs = Common.envs

let man_xrefs = [ `Main; `Cmd "ls" ]

let man =
  [ `S Manpage.s_description
  ; `P
      "$(tname) generates projects from templates. The template can be either \
       a native template, local directory or a remote git repository."
  ; `P "You can use spin-ls(1) to list the official templates."
  ]

let info = Term.info "new" ~doc ~sdocs ~exits ~envs ~man ~man_xrefs

let term =
  let open Common.Let_syntax in
  let+ _term = Common.term
  and+ ignore_config = Common.ignore_config_arg
  and+ use_defaults = Common.use_defaults_arg
  and+ template =
    let doc =
      "The template to use. The template can be the name of an official \
       template, a local directory or a remote git repository."
    in
    let docv = "TEMPLATE" in
    Arg.(required & pos 0 (some string) None & info [] ~doc ~docv)
  and+ path =
    let doc =
      "The path where the project will be generated. If absent, the project \
       will be generated in the current working directory."
    in
    let docv = "PATH" in
    Arg.(value & pos 1 (some string) None & info [] ~doc ~docv)
  in
  run ~ignore_config ~use_defaults ~template ~path |> Common.handle_errors

let cmd = term, info
