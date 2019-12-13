module type ConfigFile = {
  type t;
  type cst;

  let path: string;

  let cst_of_sexp: Sexp.t => cst;
  let t_of_cst:
    (
      ~useDefaults: bool,
      ~models: list((string, Jingoo.Jg_types.tvalue)),
      list(cst)
    ) =>
    t;
};

module Make = (C: ConfigFile) => {
  open Sexplib;

  type t = C.t;

  let parse = (~useDefaults=false, ~models=[], filepath: string): t => {
    let configFile = Utils.Filename.concat(filepath, C.path);
    configFile
    |> Sexp.load_sexps
    |> List.map(~f=C.cst_of_sexp)
    |> C.t_of_cst(~useDefaults, ~models);
  };
};

module Doc = Make(ConfigFile__Doc);
module Generators = Make(ConfigFile__Generators);
module Template = Make(ConfigFile__Template);
