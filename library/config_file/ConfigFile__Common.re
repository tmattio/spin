open Jingoo;

[@deriving of_sexp]
type stringCfg = {
  name: string,
  prompt: string,
  [@sexp.option]
  default: option(string),
};

[@deriving of_sexp]
type listCfg = {
  name: string,
  prompt: string,
  values: list(string),
  [@sexp.option]
  default: option(string),
};

[@deriving of_sexp]
type confirmCfg = {
  name: string,
  prompt: string,
  [@sexp.option]
  default: option(bool),
};

type promptCfg =
  | String(stringCfg)
  | List(listCfg)
  | Confirm(confirmCfg);

let promptConfig = (~useDefaults=false, cfg) => {
  switch (useDefaults, cfg) {
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

let applyTemplateToCst = (cst: promptCfg, ~models): promptCfg =>
  switch (cst) {
  | String(cfg) =>
    String({
      ...cfg,
      default:
        Option.map(cfg.default, ~f=default =>
          Jg_template.from_string(
            default,
            ~models,
            ~env={...Jg_types.std_env, filters: TemplateFilter.filters},
          )
        ),
    })
  | List(cfg) =>
    List({
      ...cfg,
      default:
        Option.map(cfg.default, ~f=default =>
          Jg_template.from_string(
            default,
            ~models,
            ~env={...Jg_types.std_env, filters: TemplateFilter.filters},
          )
        ),
    })
  | _ as cfg => cfg
  };

let promptConfigs = (~useDefaults=false, configs: list(promptCfg)) =>
  List.fold(
    configs,
    ~init=[],
    ~f=(acc, el) => {
      let el = applyTemplateToCst(el, ~models=acc);
      [promptConfig(el, ~useDefaults), ...acc];
    },
  );
