open Jingoo;

[@deriving of_sexp]
type post_install = {
  command: string,
  args: list(string),
  [@sexp.option]
  description: option(string),
  [@sexp.option]
  working_dir: option(string),
  [@sexp.option]
  condition: option(string),
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
  | Cfg_string(Prompt_cfg.string_cfg)
  | Cfg_list(Prompt_cfg.list_cfg)
  | Cfg_confirm(Prompt_cfg.confirm_cfg);

type t = {
  models: list((string, Jg_types.tvalue)),
  post_installs: list(post_install),
  ignore_files: list(string),
};

let path = Utils.Filename.concat("template", "spin");

type doc = unit;

let doc_of_cst = (cst: list(cst)): doc => ();

let t_of_cst = (~use_defaults, ~models, ~global_context, cst: list(cst)) => {
  /* TODO handle global context */
  let new_models =
    Config_file_cst_utils.get(
      cst,
      ~f=
        fun
        | Cfg_string(v) => Some(Prompt_cfg.String(v))
        | Cfg_list(v) => Some(Prompt_cfg.List(v))
        | Cfg_confirm(v) => Some(Prompt_cfg.Confirm(v))
        | _ => None,
    )
    |> Prompt_cfg.prompt_configs(~global_context, ~use_defaults);

  let models = List.concat([models, new_models]);

  {
    models,
    post_installs:
      Config_file_cst_utils.get(
        cst,
        ~f=
          fun
          | Post_install(v) => {
              let evaluated =
                Option.map(v.condition, ~f=condition => {
                  Jg_wrapper.from_string(condition, ~models) |> Bool.of_string
                })
                |> Option.value(~default=true);

              evaluated ? Some(v) : None;
            }

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
