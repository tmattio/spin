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
  | Cfg_string(ConfigFile__Common.stringCfg)
  | Cfg_list(ConfigFile__Common.listCfg)
  | Cfg_confirm(ConfigFile__Common.confirmCfg)
  | File(file);

type t = {
  name: string,
  description: string,
  models: list((string, Jg_types.tvalue)),
  files: list(file),
};

let path = "spin";

let t_of_cst = (~useDefaults, ~models, cst: list(cst)): t => {
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
    name:
      ConfigFile__CstUtils.getUniqueExn(
        cst,
        ~f=
          fun
          | Name(v) => Some(v)
          | _ => None,
      ),
    description:
      ConfigFile__CstUtils.getUniqueExn(
        cst,
        ~f=
          fun
          | Description(v) => Some(v)
          | _ => None,
      ),
    files:
      ConfigFile__CstUtils.get(
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
