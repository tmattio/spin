open Spin;

/** Create a new temporary directory.

    The directory name will be prefixed with "spin-test-" and will be suffixed with a timestamp. */
let get_tempdir = name => {
  let filename =
    Printf.sprintf(
      "spin-test-%s-%s",
      name,
      Unix.time() |> Float.to_int |> Int.to_string,
    )
    |> Utils.Filename.concat(Caml.Filename.get_temp_dir_name());
  Utils.Filename.mkdir(filename, ~parent=true);
  filename;
};

/** Run Spin binary with the given arguments and return the standard output. */
let run = args => {
  let arguments = args |> Array.append([|"esy", "start"|]);

  let env =
    Unix.environment()
    |> Array.append([|
         Printf.sprintf(
           "%s=%s",
           Spin.Config.SPIN_CACHE_DIR.name,
           get_tempdir("cache_dir"),
         ),
         Printf.sprintf(
           "%s=%s",
           Spin.Config.SPIN_CONFIG_DIR.name,
           get_tempdir("config_dir"),
         ),
       |]);

  Lwt_process.pread_chars(~env, ("", arguments))
  |> Lwt_stream.to_string
  |> Lwt_main.run;
};

/** Run Spin binary with the given arguments and return the exit status. */
let exec = (~dir=?, args) => {
  let arguments = args |> Array.append([|"start"|]);

  let env =
    Unix.environment()
    |> Array.append([|
         Printf.sprintf(
           "%s=%s",
           Spin.Config.SPIN_CACHE_DIR.name,
           get_tempdir("cache_dir"),
         ),
         Printf.sprintf(
           "%s=%s",
           Spin.Config.SPIN_CONFIG_DIR.name,
           get_tempdir("config_dir"),
         ),
       |]);

  let status =
    switch (dir) {
    | Some(dir) =>
      Spin.Utils.Sys.exec_in_dir(~dir, ~env, ~args=arguments, "esy")
      |> Lwt_main.run
    | None =>
      Spin.Utils.Sys.exec(~env, ~args=arguments, "esy") |> Lwt_main.run
    };

  let status_code =
    switch (status) {
    | Unix.WEXITED(s)
    | Unix.WSIGNALED(s)
    | Unix.WSTOPPED(s) => s
    };

  status_code;
};
