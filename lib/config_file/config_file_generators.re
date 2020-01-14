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
  | Message(string)
  | Cfg_string(Prompt_cfg.string_cfg)
  | Cfg_list(Prompt_cfg.list_cfg)
  | Cfg_confirm(Prompt_cfg.confirm_cfg)
  | File(file);

type t = {
  name: string,
  description: string,
  [@sexp.option]
  message: option(string),
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
      Config_file_cst_utils.get_unique_exn(
        cst,
        ~f=
          fun
          | Name(v) => Some(v)
          | _ => None,
      ),
    description:
      Config_file_cst_utils.get_unique_exn(
        cst,
        ~f=
          fun
          | Description(v) => Some(v)
          | _ => None,
      ),
  };
};

let t_of_cst = (~use_defaults, ~models, ~global_context, cst: list(cst)): t => {
  /* TODO handle global context */
  let newModels =
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
    message:
      Config_file_cst_utils.get_unique(
        cst,
        ~f=
          fun
          | Message(v) => Some(Jg_wrapper.from_string(v, ~models))
          | _ => None,
      ),
  };
};
