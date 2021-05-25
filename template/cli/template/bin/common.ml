open Cmdliner

module Syntax = struct
  let ( let+ ) t f = Term.(const f $ t)

  let ( and+ ) a b = Term.(const (fun x y -> x, y) $ a $ b)
end

open Syntax

let envs =
  [ Term.env_info
      "{{ project_snake | upper }}_CACHE_DIR"
      ~doc:
        "The directory where the application data is stored."
  ; Term.env_info
      "{{ project_snake | upper }}_CONFIG_DIR"
      ~doc:"The directory where the configuration files are stored."
  ]

let term =
  let+ log_level =
    let env = Arg.env_var "{{ project_snake | upper }}_VERBOSITY" in
    Logs_cli.level ~docs:Manpage.s_common_options ~env ()
  in
  Fmt_tty.setup_std_outputs ();
  Logs.set_level log_level;
  Logs.set_reporter (Logs_fmt.reporter ~app:Fmt.stdout ());
  0

let error_to_code = function `Missing_env_var _ -> 4

let handle_errors = function
  | Ok () ->
    if Logs.err_count () > 0 then 3 else 0
  | Error err ->
    Logs.err (fun m -> m "%s" ({{ project_snake | capitalize }}.{{ project_snake | capitalize }}_error.to_string err));
    error_to_code err

let exits =
  Term.exit_info 3 ~doc:"on indiscriminate errors reported on stderr."
  :: Term.exit_info 4 ~doc:"on missing required environment variable."
  :: Term.default_exits
