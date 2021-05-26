open Cmdliner

module Syntax = struct
  let ( let+ ) t f = Term.(const f $ t)

  let ( and+ ) a b = Term.(const (fun x y -> x, y) $ a $ b)
end

open Syntax

let ignore_config_arg =
  let doc =
    "Prompt for values regardless of whether they are in the user's \
     configuration file."
  in
  Arg.(value & flag & info [ "ignore-config" ] ~doc)

let use_defaults_arg =
  let doc =
    "Use default values without prompting when the configuration has a default \
     value."
  in
  Arg.(value & flag & info [ "d"; "default" ] ~doc)

let envs =
  [ Term.env_info
      "SPIN_CACHE_DIR"
      ~doc:
        "The directory where Spin will save cache artefacts. Typically the \
         official template directory and other remote templates will be stored \
         in the cache directory."
  ; Term.env_info
      "SPIN_CONFIG_DIR"
      ~doc:"The directory where Spin will store configuration files."
  ]

let rec set_current_dir dir =
  try Ok (Unix.chdir dir) with
  | Unix.Unix_error (Unix.EINTR, _, _) ->
    set_current_dir dir
  | Unix.Unix_error (e, _, _) ->
    Error (Unix.error_message e)

let term =
  let+ log_level =
    let env = Arg.env_var "SPIN_VERBOSITY" in
    Logs_cli.level ~docs:Manpage.s_common_options ~env ()
  and+ dir =
    let doc =
      "Run as if $(mname) was started in $(docv) instead of the current \
       directory."
    in
    Arg.(value & opt (some string) None & info [ "C" ] ~docv:"PATH" ~doc)
  in
  Fmt_tty.setup_std_outputs ();
  Logs.set_level log_level;
  Logs.set_reporter (Logs_fmt.reporter ~app:Fmt.stdout ());
  match dir with
  | None ->
    0
  | Some dir ->
    (match set_current_dir dir with
    | Ok () ->
      0
    | Error msg ->
      Logs.err (fun m -> m "%s" msg);
      1)

let spin_error_to_code = function
  | `Missing_env_var _ ->
    4
  | `Failed_to_parse _ ->
    5
  | `Invalid_template _ ->
    6
  | `Failed_to_generate _ ->
    7

let handle_errors = function
  | Ok () ->
    if Logs.err_count () > 0 then 3 else 0
  | Error err ->
    Logs.err (fun m -> m "%s" (Spin.Spin_error.to_string err));
    spin_error_to_code err

let exits =
  Term.exit_info 3 ~doc:"on indiscriminate errors reported on stderr."
  ::
  Term.exit_info 4 ~doc:"on missing required environment variable."
  ::
  Term.exit_info 5 ~doc:"on failure to parse a file."
  ::
  Term.exit_info 6 ~doc:"on invalid spin template."
  ::
  Term.exit_info 7 ~doc:"on failure to generate project." :: Term.default_exits
