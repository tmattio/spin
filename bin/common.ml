open Cmdliner

module Syntax = struct
  let ( let+ ) t f = Term.(const f $ t)
  let ( and+ ) a b = Term.(const (fun x y -> (x, y)) $ a $ b)
end

open Syntax

let envs =
  [
    Cmd.Env.info "SPIN_CACHE_DIR"
      ~doc:
        "The directory where Spin will save cache artefacts. Typically the \
         official template directory and other remote templates will be stored \
         in the cache directory.";
    Cmd.Env.info "SPIN_CONFIG_DIR"
      ~doc:"The directory where Spin will store configuration files.";
  ]

let term =
  let+ log_level =
    let env = Cmd.Env.info "SPIN_VERBOSITY" in
    Logs_cli.level ~docs:Manpage.s_common_options ~env ()
  in
  Fmt_tty.setup_std_outputs ();
  Logs.set_level log_level;
  Logs.set_reporter (Logs_fmt.reporter ~app:Fmt.stdout ());
  0

  let exits =
    Cmd.Exit.info 3 ~doc:"on indiscriminate errors reported on stderr."
    ::
    Cmd.Exit.info 4 ~doc:"on missing required environment variable."
    ::
    Cmd.Exit.info 5 ~doc:"on failure to parse a file."
    ::
    Cmd.Exit.info 6 ~doc:"on invalid spin template."
    ::
    Cmd.Exit.info 7 ~doc:"on failure to generate project." :: Cmd.Exit.defaults
  