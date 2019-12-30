open Jingoo;

[@deriving of_sexp]
type string_cfg = {
  name: string,
  prompt: string,
  [@sexp.option]
  default: option(string),
};

[@deriving of_sexp]
type list_cfg = {
  name: string,
  prompt: string,
  values: list(string),
  [@sexp.option]
  default: option(string),
};

[@deriving of_sexp]
type confirm_cfg = {
  name: string,
  prompt: string,
  [@sexp.option]
  default: option(bool),
};

type prompt_cfg =
  | String(string_cfg)
  | List(list_cfg)
  | Confirm(confirm_cfg);

let promptConfig = (~use_defaults=false, cfg) => {
  switch (use_defaults, cfg) {
  | (true, String({name, default: Some(default)}))
  | (true, List({name, default: Some(default)})) => (
      name,
      Jg_types.Tstr(default),
    )
  | (true, Confirm({name, default: Some(default)})) => (
      name,
      Jg_types.Tbool(default),
    )
  | (_, String(cfg)) => (
      cfg.name,
      Jg_types.Tstr(Prompt.input(cfg.prompt, ~default=?cfg.default)),
    )
  | (_, List(cfg)) => (
      cfg.name,
      Jg_types.Tstr(
        Prompt.list(cfg.prompt, cfg.values, ~default=?cfg.default),
      ),
    )
  | (_, Confirm(cfg)) => (
      cfg.name,
      Jg_types.Tbool(Prompt.confirm(cfg.prompt, ~default=?cfg.default)),
    )
  };
};

let apply_template_to_cst = (cst: prompt_cfg, ~models): prompt_cfg =>
  switch (cst) {
  | String(cfg) =>
    String({
      ...cfg,
      default:
        Option.map(cfg.default, ~f=default =>
          Jg_wrapper.from_string(default, ~models)
        ),
    })
  | List(cfg) =>
    List({
      ...cfg,
      default:
        Option.map(cfg.default, ~f=default =>
          Jg_wrapper.from_string(default, ~models)
        ),
    })
  | _ as cfg => cfg
  };

let prompt_configs = (~use_defaults=false, configs: list(prompt_cfg)) =>
  List.fold(
    configs,
    ~init=[],
    ~f=(acc, el) => {
      let el = apply_template_to_cst(el, ~models=acc);
      [promptConfig(el, ~use_defaults), ...acc];
    },
  );
