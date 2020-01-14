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

type t =
  | String(string_cfg)
  | List(list_cfg)
  | Confirm(confirm_cfg);

let get_context_or_prompt =
    (~global_context: option(Global_context.t), prompt_cfgs: Base.List.t(t)) => {
  List.fold(
    prompt_cfgs, ~init=([], []), ~f=((context_acc, cfg_acc), prompt_cfg) => {
    switch (prompt_cfg, global_context) {
    | (String({name: "author_name"}), Some({name: Some(name)})) => (
        [("author_name", Jg_types.Tstr(name)), ...context_acc],
        cfg_acc,
      )
    | (String({name: "author_email"}), Some({email: Some(email)})) => (
        [("author_email", Jg_types.Tstr(email)), ...context_acc],
        cfg_acc,
      )
    | (
        String({name: "github_username"}),
        Some({github_username: Some(github_username)}),
      ) => (
        [
          ("github_username", Jg_types.Tstr(github_username)),
          ...context_acc,
        ],
        cfg_acc,
      )
    | (
        String({name: "npm_username"}),
        Some({npm_username: Some(npm_username)}),
      ) => (
        [("npm_username", Jg_types.Tstr(npm_username)), ...context_acc],
        cfg_acc,
      )
    | _ => (context_acc, [prompt_cfg, ...cfg_acc])
    }
  });
};

let prompt_config = (~use_defaults=false, cfg) => {
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

let apply_template_to_cst = (cst: t, ~models): t =>
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

let prompt_configs =
    (
      ~use_defaults=false,
      ~global_context: option(Global_context.t)=None,
      configs: list(t),
    ) => {
  let (context_models, filtered_prompt_cfgs) =
    get_context_or_prompt(configs, ~global_context);

  let models =
    List.fold(
      List.rev(filtered_prompt_cfgs),
      ~init=[],
      ~f=(acc, el) => {
        let el = apply_template_to_cst(el, ~models=acc);
        [prompt_config(el, ~use_defaults), ...acc];
      },
    );

  List.concat([context_models, models]);
};
