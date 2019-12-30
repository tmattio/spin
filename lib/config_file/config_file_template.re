open Jingoo;

[@deriving of_sexp]
type post_install = {
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
  | Post_install(post_install)
  | Ignore(ignore)
  | Cfg_string(Config_file_common.string_cfg)
  | Cfg_list(Config_file_common.list_cfg)
  | Cfg_confirm(Config_file_common.confirm_cfg);

type t = {
  models: list((string, Jg_types.tvalue)),
  post_installs: list(post_install),
  ignore_files: list(string),
};

let path = Utils.Filename.concat("template", "spin");

type doc = unit;

let doc_of_cst = (cst: list(cst)): doc => ();

let t_of_cst = (~use_defaults, ~models, cst: list(cst)) => {
  let new_models =
    Config_file_cst_utils.get(
      cst,
      ~f=
        fun
        | Cfg_string(v) => Some(Config_file_common.String(v))
        | Cfg_list(v) => Some(Config_file_common.List(v))
        | Cfg_confirm(v) => Some(Config_file_common.Confirm(v))
        | _ => None,
    )
    |> Config_file_common.prompt_configs(~use_defaults);

  let models = List.concat([models, new_models]);

  {
    models,
    post_installs:
      Config_file_cst_utils.get(
        cst,
        ~f=
          fun
          | Post_install(v) => Some(v)
          | _ => None,
      ),
    ignore_files:
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
