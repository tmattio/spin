open Jingoo;

[@deriving of_sexp]
type file = {
  source: string,
  destination: string,
};

[@deriving of_sexp]
type cst =
  | Name(string)
  | Description(string)
  | Cfg_string(Config_file_common.stringCfg)
  | Cfg_list(Config_file_common.listCfg)
  | Cfg_confirm(Config_file_common.confirmCfg)
  | File(file);

type t = {
  name: string,
  description: string,
  models: list((string, Jg_types.tvalue)),
  files: list(file),
};

type doc = {
  name: string,
  description: string,
};

let path = "spin";

let doc_of_cst = (cst: list(cst)): doc => {
  {
    name:
      Config_file_cst_utils.getUniqueExn(
        cst,
        ~f=
          fun
          | Name(v) => Some(v)
          | _ => None,
      ),
    description:
      Config_file_cst_utils.getUniqueExn(
        cst,
        ~f=
          fun
          | Description(v) => Some(v)
          | _ => None,
      ),
  };
};

let t_of_cst = (~useDefaults, ~models, cst: list(cst)): t => {
  let newModels =
    Config_file_cst_utils.get(
      cst,
      ~f=
        fun
        | Cfg_string(v) => Some(Config_file_common.String(v))
        | Cfg_list(v) => Some(Config_file_common.List(v))
        | Cfg_confirm(v) => Some(Config_file_common.Confirm(v))
        | _ => None,
    )
    |> Config_file_common.promptConfigs(~useDefaults);

  let models = List.concat([models, newModels]);

  let doc = doc_of_cst(cst);

  {
    name: doc.name,
    description: doc.description,
    files:
      Config_file_cst_utils.get(
        cst,
        ~f=
          fun
          | File(v) =>
            Some({
              source: Jg_wrapper.from_string(v.source, ~models),
              destination: Jg_wrapper.from_string(v.destination, ~models),
            })
          | _ => None,
      ),
    models,
  };
};
