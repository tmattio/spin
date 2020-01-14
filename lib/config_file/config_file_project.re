open Jingoo;

[@deriving sexp]
type cst =
  | Source(string)
  | Cfg_str(string, string)
  | Cfg_int(string, int)
  | Cfg_float(string, float)
  | Cfg_list(string, list(string))
  | Cfg_bool(string, bool);

type t = {
  models: list((string, Jg_types.tvalue)),
  source: string,
};

type doc = {source: string};

let path = ".spin";

let doc_of_cst = (cst: list(cst)): doc => {
  {
    source:
      Config_file_cst_utils.get_unique_exn(
        cst,
        ~f=
          fun
          | Source(v) => Some(v)
          | _ => None,
      ),
  };
};

let t_of_cst = (~use_defaults, ~models, ~global_context, cst: list(cst)): t => {
  let newModels =
    Config_file_cst_utils.get(
      cst,
      ~f=
        fun
        | Cfg_str(name, v) => Some((name, Jg_types.Tstr(v)))
        | Cfg_int(name, v) => Some((name, Jg_types.Tint(v)))
        | Cfg_float(name, v) => Some((name, Jg_types.Tfloat(v)))
        | Cfg_list(name, v) => {
            let strs = List.map(v, ~f=s => Jg_types.Tstr(s));
            Some((name, Jg_types.Tlist(strs)));
          }
        | Cfg_bool(name, v) => Some((name, Jg_types.Tbool(v)))
        | Source(_) => None,
    );

  let doc = doc_of_cst(cst);

  {source: doc.source, models: newModels};
};

let cst_of_t = (~models, t: t): list(cst) => {
  let prepend = (~l, a) => [a, ...l];

  let cst =
    List.fold(models, ~init=[], ~f=(acc, (name, value)) => {
      switch (value) {
      | Jg_types.Tstr(v) => Cfg_str(name, v) |> prepend(~l=acc)
      | Jg_types.Tint(v) => Cfg_int(name, v) |> prepend(~l=acc)
      | Jg_types.Tbool(v) => Cfg_bool(name, v) |> prepend(~l=acc)
      | Jg_types.Tfloat(v) => Cfg_float(name, v) |> prepend(~l=acc)
      | Jg_types.Tlist(v) =>
        let strs =
          List.fold(v, ~init=[], ~f=acc =>
            (
              fun
              | Jg_types.Tstr(v) => [v, ...acc]
              | _ => acc
            )
          );
        Cfg_list(name, strs) |> prepend(~l=acc);
      | _ => acc
      }
    });

  [Source(t.source), ...cst];
};

let save = (data: t, ~from_dir: string) => {
  let destination = Utils.Filename.concat(from_dir, path);
  let parent_dir = Utils.Filename.dirname(destination);
  Utils.Filename.mkdir(parent_dir, ~parent=true);

  let sexp_string =
    cst_of_t(data, ~models=data.models)
    |> List.map(~f=cst => cst |> sexp_of_cst |> Sexp.to_string)
    |> Utils.String.join(~sep="\n");
  Stdio.Out_channel.write_all(destination, ~data=sexp_string);
};
