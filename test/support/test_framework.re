open Spin;

let projectDir = Caml.Sys.getcwd();
let tmpDir = Utils.Filename.concat(projectDir, ".tmp");

include Rely.Make({
  let config =
    Rely.TestFrameworkConfig.initialize({
      snapshotDir: Caml.Filename.concat(Caml.Sys.getcwd(), "_snapshots"),
      projectDir: Caml.Sys.getcwd(),
    });
});

let run = args => {
  let arguments =
    args |> Array.append([|"./_build/default/bin/spin_app.exe"|]);
  let env =
    Unix.environment()
    |> Array.append([|
         Printf.sprintf("%s=%s", Spin.Config.SPIN_CACHE_DIR.name, tmpDir),
       |]);
  let result =
    Lwt_process.pread_chars(~env, ("", arguments)) |> Lwt_stream.to_string;
  Lwt_main.run(result);
};