open Spin

let run ~path =
  let open Result.Syntax in
  let path = Option.value path ~default:Filename.current_dir_name in
  let* () =
    try
      match Sys.readdir path with
      | [||] ->
        Ok ()
      | _ ->
        Error
          (Spin_error.failed_to_generate "The output directory is not empty.")
    with
    | Sys_error _ ->
      Sys.mkdir_p path;
      Ok ()
  in
  try
    let* template = Template.read (Template.Official Spin_template.hello) in
    Template.generate ~path template
  with
  | Sys.Break | Failure _ ->
    exit 1
  | e ->
    raise e

(* Command line interface *)

open Cmdliner

let doc = "Generate a tutorial project in the given directory"

let sdocs = Manpage.s_common_options

let exits = Common.exits

let envs = Common.envs

let man_xrefs = [ `Main; `Cmd "new" ]

let man =
  [ `S Manpage.s_description
  ; `P
      "$(tname) generates a tutorial project. This is useful if this is your \
       first project with OCaml and you want to learn by example."
  ; `P
      "If you are already familiar with the typical OCaml development \
       environment, use spin-new(1) instead."
  ]

let info = Term.info "hello" ~doc ~sdocs ~exits ~envs ~man ~man_xrefs

let term =
  let open Common.Syntax in
  let+ _term = Common.term
  and+ path =
    let doc =
      "The path where the project will be generated. If absent, the project \
       will be generated in the current working directory."
    in
    let docv = "PATH" in
    Arg.(value & pos 0 (some string) None & info [] ~doc ~docv)
  in
  run ~path |> Common.handle_errors

let cmd = term, info
