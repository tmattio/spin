open Jingoo;

[@deriving of_sexp]
type postInstall = {
  command: string,
  args: list(string),
  [@sexp.option]
  description: option(string),
};

[@deriving of_sexp]
type cst =
  | Post_install(postInstall)
  | Cfg_string(ConfigFile__Common.stringCfg)
  | Cfg_list(ConfigFile__Common.listCfg)
  | Cfg_confirm(ConfigFile__Common.confirmCfg);

type t = {
  models: list((string, Jg_types.tvalue)),
  postInstalls: list(postInstall),
};

let path = Utils.Filename.concat("template", "spin");

let t_of_cst = (~useDefaults, ~models, cst: list(cst)) => {
  let newModels =
    ConfigFile__CstUtils.get(
      cst,
      ~f=
        fun
        | Cfg_string(v) => Some(ConfigFile__Common.String(v))
        | Cfg_list(v) => Some(ConfigFile__Common.List(v))
        | Cfg_confirm(v) => Some(ConfigFile__Common.Confirm(v))
        | _ => None,
    )
    |> ConfigFile__Common.promptConfigs(~useDefaults);

  let models = List.concat([models, newModels]);

  {
    models,
    postInstalls:
      ConfigFile__CstUtils.get(
        cst,
        ~f=
          fun
          | Post_install(v) => Some(v)
          | _ => None,
      ),
  };
};
