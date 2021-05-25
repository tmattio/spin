open Dec_template

exception Failed_rule_eval of Spin_error.t

let validate_of_rule ~context ~config_name (rule : Configuration.rule) =
  let context_with_config = Hashtbl.copy context in
  fun (v : string) ->
    Hashtbl.add context_with_config config_name v;
    let result =
      Template_expr.to_result
        Template_expr.to_bool
        rule.expr
        ~context:context_with_config
    in
    match result with
    | Error e ->
      raise (Failed_rule_eval e)
    | Ok result ->
      if result then
        Ok v
      else
        let error_message = Template_expr.eval rule.message ~context in
        Error error_message

let prompt_config ?(use_defaults = false) ~context (config : Configuration.t) =
  let open Result.Syntax in
  let* default =
    match config.default with
    | None ->
      Ok None
    | Some default ->
      let+ result =
        Template_expr.to_result Template_expr.eval default ~context
      in
      Some result
  in
  let validate =
    List.fold_left
      (fun acc rule v ->
        let f = validate_of_rule ~context ~config_name:config.name rule in
        Result.bind (acc v) f)
      (fun v -> Result.ok v)
      config.rules
  in
  match use_defaults, config.prompt, default with
  | true, _, Some default ->
    Result.ok (Some default)
  | _, Some (Configuration.Input input_t), _ ->
    let v = Inquire.input input_t.message ?default ~validate in
    Ok (Some v)
  | _, Some (Configuration.Select select_t), _ ->
    let default_v =
      (* Find the index of the default value if provided. *)
      Option.map
        (fun default -> List.index (String.equal default) select_t.values)
        default
    in
    let v =
      Inquire.select
        select_t.message
        ~options:select_t.values
        ?default:default_v
    in
    Ok (Some v)
  | _, Some (Configuration.Confirm confirm_t), _ ->
    let+ default =
      match default with
      | None ->
        Result.ok None
      | Some default ->
        let+ result =
          Template_expr.to_result
            Template_expr.to_bool
            (Expr.String default)
            ~context
        in
        Some result
    in
    let v = Inquire.confirm confirm_t.message ?default in
    Some (Bool.to_string v)
  | _, None, _ ->
    Ok default

let populate_context
    ?(use_defaults = false)
    ~context
    (configurations : Dec_template.Configuration.t list)
  =
  let open Result.Syntax in
  Result.List.fold_left
    (fun _ (config : Configuration.t) ->
      if Hashtbl.mem context config.name then
        Result.ok ()
      else
        let env_var_name =
          Printf.sprintf "SPIN_%s" (String.uppercase_ascii config.name)
        in
        match Sys.getenv_opt env_var_name with
        | Some data ->
          Hashtbl.add context config.name data;
          Result.ok ()
        | None ->
          let+ data_opt =
            try prompt_config config ~context ~use_defaults with
            | Failed_rule_eval e ->
              Error e
            | exn ->
              raise exn
          in
          (match data_opt with
          | Some data ->
            Hashtbl.add context config.name data;
            ()
          | None ->
            ()))
    ()
    configurations
