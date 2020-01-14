open Jingoo;

[@deriving sexp]
type cst =
  | Name(string)
  | Email(string)
  | Github_username(string)
  | Npm_username(string);

type t = {
  name: option(string),
  email: option(string),
  github_username: option(string),
  npm_username: option(string),
};

type doc = t;

let path = "default";

let doc_of_cst = (cst: list(cst)): doc => {
  {
    name:
      Config_file_cst_utils.get_unique(
        cst,
        ~f=
          fun
          | Name(v) => Some(v)
          | _ => None,
      ),
    email:
      Config_file_cst_utils.get_unique(
        cst,
        ~f=
          fun
          | Email(v) => Some(v)
          | _ => None,
      ),
    github_username:
      Config_file_cst_utils.get_unique(
        cst,
        ~f=
          fun
          | Github_username(v) => Some(v)
          | _ => None,
      ),
    npm_username:
      Config_file_cst_utils.get_unique(
        cst,
        ~f=
          fun
          | Npm_username(v) => Some(v)
          | _ => None,
      ),
  };
};

let t_of_cst = (~use_defaults, ~models, ~global_context, cst: list(cst)): t => {
  let doc = doc_of_cst(cst);

  {
    name: doc.name,
    email: doc.email,
    github_username: doc.github_username,
    npm_username: doc.npm_username,
  };
};

let cst_of_t = (~models, t: t): list(cst) => {
  let acc = [];
  let acc =
    Option.map(t.name, v => [Name(v), ...acc]) |> Option.value(~default=acc);
  let acc =
    Option.map(t.email, v => [Email(v), ...acc])
    |> Option.value(~default=acc);
  let acc =
    Option.map(t.github_username, v => [Github_username(v), ...acc])
    |> Option.value(~default=acc);
  let acc =
    Option.map(t.npm_username, v => [Npm_username(v), ...acc])
    |> Option.value(~default=acc);
  acc;
};

let save = (data: t, ~from_dir: string) => {
  let destination = Utils.Filename.concat(from_dir, path);
  let parent_dir = Utils.Filename.dirname(destination);
  Utils.Filename.mkdir(parent_dir, ~parent=true);

  let sexp_string =
    cst_of_t(data, ~models=[])
    |> List.map(~f=cst => cst |> sexp_of_cst |> Sexp.to_string)
    |> Utils.String.join(~sep="\n");
  Stdio.Out_channel.write_all(destination, ~data=sexp_string);
};
