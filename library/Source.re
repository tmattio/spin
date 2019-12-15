type t =
  | Official(string)
  | Git(string)
  | LocalDir(string);

type local = string;

let toLocalPath: t => local =
  fun
  | Official(s) => Utils.Filename.concat(TemplateOfficial.path, s)
  | LocalDir(s) => s
  | Git(s) => {
      let tempdir = Utils.Sys.get_tempdir("spin");
      let _ = Vcs.gitClone(s, ~destination=tempdir);
      tempdir;
    };

let ofString = (s: string) =>
  if (Utils.Filename.test(Utils.Filename.Exists, s)) {
    LocalDir(s);
  } else if (Vcs.isGitUrl(s)) {
    Git(s);
  } else if (TemplateOfficial.all() |> List.exists(~f=String.equal(s))) {
    Official(s);
  } else {
    raise(Errors.IncorrectTemplateName(s));
  };

let toString =
  fun
  | Official(s) => s
  | Git(s) => s
  | LocalDir(s) => s;
