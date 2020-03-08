let path =
  Utils.Filename.concat(Config.SPIN_CACHE_DIR.get(), "spin-templates");

let branch = "master";

let url = "https://github.com/tmattio/spin-templates.git";

let download_if_absent = () =>
  if (!Utils.Filename.test(Utils.Filename.Exists, path)) {
    Stdio.print_endline("📡  Downloading official templates.");
    let status_code =
      Vcs.git_clone(url, ~destination=path, ~branch) |> Lwt_main.run;

    switch (status_code) {
    | WEXITED(0) =>
      Pastel.make(~color=Pastel.GreenBright, ~bold=true, ["Done!\n"])
      |> Stdio.print_endline
    | _ => raise(Errors.Cannot_access_remote_repository(url))
    };
  };

let update_if_present = () =>
  if (Utils.Filename.test(Utils.Filename.Is_dir, path)) {
    Stdio.print_endline("📡  Updating official templates.");
    let status_code = Vcs.git_pull(path) |> Lwt_main.run;

    switch (status_code) {
    | WEXITED(0) =>
      Pastel.make(~color=Pastel.GreenBright, ~bold=true, ["Done!\n"])
      |> Stdio.print_endline
    | _ =>
      Pastel.make(
        ~color=Pastel.Yellow,
        ~bold=true,
        ["Failed. Using your current version of the official templates.\n"],
      )
      |> Stdio.print_endline
    };
  };

let all = (): list(Config_file.Doc.doc) => {
  Caml.Sys.readdir(path)
  |> Array.to_list
  |> List.filter(~f=el =>
       Caml.Sys.is_directory(Utils.Filename.concat(path, el))
     )
  |> List.filter(~f=el =>
       switch (Caml.String.get(el, 0)) {
       | '.'
       | '_' => false
       | _ => true
       }
     )
  |> List.map(~f=el =>
       Config_file.Doc.parse_doc(Utils.Filename.concat(path, el))
     );
};
