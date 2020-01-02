module type Config_file = {
  type t;
  type doc;
  type cst;

  let path: string;

  let cst_of_sexp: Sexp.t => cst;
  let t_of_cst:
    (
      ~use_defaults: bool,
      ~models: list((string, Jingoo.Jg_types.tvalue)),
      list(cst)
    ) =>
    t;
  let doc_of_cst: list(cst) => doc;
};

module Make = (C: Config_file) => {
  open Sexplib;

  type t = C.t;
  type doc = C.doc;

  let path = dirname => Utils.Filename.concat(dirname, C.path);

  let parse = (~use_defaults=false, ~models=[], dirname: string): t => {
    path(dirname)
    |> Sexp.load_sexps
    |> List.map(~f=C.cst_of_sexp)
    |> C.t_of_cst(~use_defaults, ~models);
  };

  let parse_doc = (dirname: string): doc => {
    path(dirname)
    |> Sexp.load_sexps
    |> List.map(~f=C.cst_of_sexp)
    |> C.doc_of_cst;
  };
};

module Doc = Make(Config_file_doc);
module Generators = Make(Config_file_generators);
module Template = Make(Config_file_template);
module Project = Make(Config_file_project);
