type t =
  | Official(string)
  | Git(string)
  | LocalDir(string);

type local = string;

let toLocalPath: t => local =
  fun
  | Official(s) => Utils.Filename.concat(Template_official.path, s)
  | LocalDir(s) => s
  | Git(s) => {
      let tempdir = Utils.Sys.get_tempdir("spin");
      let _ = Lwt_main.run(Vcs.gitClone(s, ~destination=tempdir));
      tempdir;
    };

let ofString = (s: string) =>
  if (Utils.Filename.test(Utils.Filename.Exists, s)) {
    LocalDir(s);
  } else if (Vcs.isGitUrl(s)) {
    Git(s);
  } else {
    Template_official.ensureDownloaded();
    let templates = Template_official.all();
    if (List.exists(templates, ~f=el => String.equal(s, el.name))) {
      Official(s);
    } else {
      raise(Errors.IncorrectTemplateName(s));
    };
  };

let toString =
  fun
  | Official(s) => s
  | Git(s) => s
  | LocalDir(s) => s;
