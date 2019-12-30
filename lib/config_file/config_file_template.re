open Jingoo;

[@deriving of_sexp]
type postInstall = {
  command: string,
  args: list(string),
  [@sexp.option]
  description: option(string),
};

[@deriving of_sexp]
type ignore = {
  files: list(string),
  condition: string,
};

[@deriving of_sexp]
type cst =
  | Post_install(postInstall)
  | Ignore(ignore)
  | Cfg_string(Config_file_common.stringCfg)
  | Cfg_list(Config_file_common.listCfg)
  | Cfg_confirm(Config_file_common.confirmCfg);

type t = {
  models: list((string, Jg_types.tvalue)),
  postInstalls: list(postInstall),
  ignoreFiles: list(string),
};

let path = Utils.Filename.concat("template", "spin");

type doc = unit;

let doc_of_cst = (cst: list(cst)): doc => ();

let t_of_cst = (~useDefaults, ~models, cst: list(cst)) => {
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

  {
    models,
    postInstalls:
      Config_file_cst_utils.get(
        cst,
        ~f=
          fun
          | Post_install(v) => Some(v)
          | _ => None,
      ),
    ignoreFiles:
      Config_file_cst_utils.get(
        cst,
        ~f=
          fun
          | Ignore(v) => {
              let evaluated = Jg_wrapper.from_string(v.condition, ~models);
              Bool.of_string(evaluated) ? Some(v.files) : None;
            }
          | _ => None,
      )
      |> Caml.List.flatten,
  };
};
