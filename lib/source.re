type t =
  | Official(string)
  | Git(string)
  | Local_dir(string);

type local = string;

let to_local_path: t => local =
  fun
  | Official(s) => Utils.Filename.concat(Template_official.path, s)
  | Local_dir(s) => s
  | Git(s) => {
      let tempdir = Utils.Sys.get_tempdir("spin");
      Stdio.print_endline("📡  Downloading " ++ s ++ " to " ++ tempdir);
      let status_code =
        Vcs.git_clone(s, ~destination=tempdir) |> Lwt_main.run;

      switch (status_code) {
      | WEXITED(0) =>
        Pastel.make(~color=Pastel.GreenBright, ~bold=true, ["Done!\n"])
        |> Stdio.print_endline

      | _ => raise(Errors.Cannot_access_remote_repository(s))
      };
      tempdir;
    };

let of_string = (s: string) =>
  if (Utils.Filename.test(Utils.Filename.Exists, s)) {
    Local_dir(s);
  } else if (Vcs.is_git_url(s)) {
    Git(s);
  } else {
    Template_official.download_if_absent();
    Template_official.update_if_present();
    let templates = Template_official.all();
    if (List.exists(templates, ~f=el => String.equal(s, el.name))) {
      Official(s);
    } else {
      raise(Errors.Incorrect_template_name(s));
    };
  };

let to_string =
  fun
  | Official(s) => s
  | Git(s) => s
  | Local_dir(s) => s;
