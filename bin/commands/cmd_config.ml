open Spin

let run () =
  let open Result.Let_syntax in
  let* user_config = User_config.read () in
  let* new_config =
    let result = User_config.prompt ?default:user_config () in
    try Ok (Lwt_main.run result) with
    | Caml.Sys.Break ->
      Caml.exit 1
    | e ->
      raise e
  in
  User_config.save new_config

(* Command line interface *)

open Cmdliner

let doc = "Update the current user's configuration"

let sdocs = Manpage.s_common_options

let exits = Common.exits

let envs = Common.envs

let man_xrefs = [ `Main; `Cmd "new"; `Cmd "gen" ]

let man =
  [ `S Manpage.s_description
  ; `P
      "The $(tname) command prompts the user for global configuration values \
       that will be saved in `\\$SPIN_CONFIG_DIR/config` \
       (`~/.config/spin/config` by default)."
  ; `P
      "Unless `--ignore-config` is used, the configuration values stored in \
       `\\$SPIN_CONFIG_DIR/config` will be used when creating new projects \
       (with spin-new(1)) or components (with spin-gen(2)) and the user will \
       not be prompted for configuration that have been saved."
  ]

let info = Term.info "config" ~doc ~sdocs ~exits ~envs ~man ~man_xrefs

let term =
  let open Common.Let_syntax in
  let+ _term = Common.term in
  run () |> Common.handle_errors

let cmd = term, info
