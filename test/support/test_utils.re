open Spin;

/** Create a new temporary directory.

    The directory name will be prefixed with "spin-test-" and will be suffixed with a timestamp. */
let get_tempdir = name => {
  Printf.sprintf(
    "spin-test-%s-%s",
    name,
    Unix.time() |> Float.to_int |> Int.to_string,
  )
  |> Utils.Filename.concat(Caml.Filename.get_temp_dir_name());
};

/** Run Spin binary with the given arguments and return the standard output.

    This requires that the build artifacts are generated in the `_build` directory.
    Make sure the configuration `esy.buildsInSource` is set to `_build` in your `esy.json` file */
let run = args => {
  let arguments =
    args |> Array.append([|"./_build/default/bin/spin_app.exe"|]);

  let env =
    Unix.environment()
    |> Array.append([|
         Printf.sprintf(
           "%s=%s",
           Spin.Config.SPIN_CACHE_DIR.name,
           get_tempdir("cache_dir"),
         ),
       |]);

  Lwt_process.pread_chars(~env, ("", arguments))
  |> Lwt_stream.to_string
  |> Lwt_main.run;
};