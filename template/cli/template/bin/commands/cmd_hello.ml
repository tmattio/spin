open {{ project_snake | capitalize }}

let run ~name =
  let greeting = Utils.greet name in
  Logs.app (fun m -> m "%s" greeting);
  Ok ()

(* Command line interface *)

open Cmdliner

let doc = "Print \"Hello World!\""

let sdocs = Manpage.s_common_options

let exits = Common.exits

let envs = Common.envs

let man =
  [ `S Manpage.s_description
  ; `P "$(tname) prints a hello world message on the standard output."
  ]

let info = Term.info "hello" ~doc ~sdocs ~exits ~envs ~man

let term =
  let open Common.Syntax in
  let+ _term = Common.term
  and+ name =
    let doc = "The name to greet." in
    let docv = "NAME" in
    Arg.(required & pos 0 (some string) None & info [] ~doc ~docv)
  in
  run ~name |> Common.handle_errors

let cmd = term, info
