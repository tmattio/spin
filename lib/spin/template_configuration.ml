open Dec_template

exception Failed_rule_eval of Spin_error.t

let validate_of_rule ~context ~config_name (rule : Configuration.rule) =
  let open Lwt.Syntax in
  let context_with_config = Hashtbl.copy context in
  fun v ->
    Hashtbl.set context_with_config ~key:config_name ~data:v;
    let* result =
      Template_expr.to_result
        rule.expr
        ~f:Template_expr.to_bool
        ~context:context_with_config
    in
    match result with
    | Error e ->
      raise (Failed_rule_eval e)
    | Ok result ->
      if result then
        Lwt.return (Ok v)
      else
        let+ error_message = Template_expr.eval rule.message ~context in
        Error error_message

let prompt_config ?(use_defaults = false) ~context (config : Configuration.t) =
  let open Lwt_result.Syntax in
  let* default =
    match config.default with
    | None ->
      Lwt.return (Ok None)
    | Some default ->
      let+ result =
        Template_expr.to_result default ~f:Template_expr.eval ~context
      in
      Some result
  in
  let validate =
    List.fold_left
      config.rules
      ~init:(fun v -> Lwt_result.return v)
      ~f:(fun acc rule v ->
        let f = validate_of_rule ~context ~config_name:config.name rule in
        Lwt_result.bind (acc v) f)
  in
  match use_defaults, config.prompt, default with
  | true, _, Some default ->
    Lwt_result.return (Some default)
  | _, Some (Configuration.Input input_t), _ ->
    let+ v =
      Inquire.input input_t.message ?default ~validate |> Lwt_result.ok
    in
    Some v
  | _, Some (Configuration.Select select_t), _ ->
    let+ v =
      Inquire.select select_t.message ~options:select_t.values ?default
      |> Lwt_result.ok
    in
    Some v
  | _, Some (Configuration.Confirm confirm_t), _ ->
    let* default =
      match default with
      | None ->
        Lwt_result.return None
      | Some default ->
        let+ result =
          Template_expr.to_result
            (Expr.String default)
            ~f:Template_expr.to_bool
            ~context
        in
        Some result
    in
    let+ v = Inquire.confirm confirm_t.message ?default |> Lwt_result.ok in
    Some (Bool.to_string v)
  | _, None, _ ->
    Lwt.return (Ok default)

let populate_context
    ?(use_defaults = false)
    ~context
    (configurations : Dec_template.Configuration.t list)
  =
  let open Lwt_result.Syntax in
  List.fold_left
    configurations
    ~init:(Lwt_result.return ())
    ~f:(fun acc config ->
      let* () = acc in
      if Hashtbl.mem context config.name then
        Lwt_result.return ()
      else
        let env_var_name =
          Printf.sprintf "SPIN_%s" (String.uppercase config.name)
        in
        match Sys.getenv env_var_name with
        | Some data ->
          let _ = Hashtbl.add context ~key:config.name ~data in
          Lwt_result.return ()
        | None ->
          let+ data_opt =
            let* result = prompt_config config ~context ~use_defaults in
            Lwt.catch
              (fun () -> Lwt_result.return result)
              (function
                | Failed_rule_eval e ->
                  Lwt.return (Error e)
                | exn ->
                  Lwt.fail exn)
          in
          (match data_opt with
          | Some data ->
            let _ = Hashtbl.add context ~key:config.name ~data in
            ()
          | None ->
            ()))
