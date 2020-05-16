open Dec_template

type source =
  | Git of string
  | Local_dir of string
  | Official of (module Spin_template.Template)

type example_command =
  { name : string
  ; description : string
  }

type t =
  { name : string
  ; description : string
  ; template_files : (string, string) Hashtbl.t
  ; context : (string, string) Hashtbl.t
  ; pre_gen_actions : Template_actions.t list
  ; post_gen_actions : Template_actions.t list
  ; example_commands : example_command list
  }

let evaluate_expr_with ~context ~f expr =
  let open Lwt.Syntax in
  let+ result = f ~context expr in
  try Ok result with
  | Template_expr.Invalid_expr reason ->
    Error (Spin_error.failed_to_generate reason)
  | _ ->
    Error
      (Spin_error.failed_to_generate
         "Failed to evaluate an expression for unknown reason")

exception Failed_rule_eval of Spin_error.t

let validate_of_rule ~context ~config_name (rule : Configuration.rule) =
  let open Lwt.Syntax in
  let context_with_config = Hashtbl.copy context in
  fun v ->
    Hashtbl.set context_with_config ~key:config_name ~data:v;
    let* result =
      evaluate_expr_with
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
        Lwt.return (Error rule.message)

let prompt_config ?(use_defaults = false) ~context (config : Configuration.t) =
  let open Lwt_result.Syntax in
  let* default =
    match config.default with
    | None ->
      Lwt.return (Ok None)
    | Some default ->
      let+ result = evaluate_expr_with default ~f:Template_expr.eval ~context in
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
          evaluate_expr_with
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

let fold_with_enabled_if ~context ~expr ~f l =
  let open Lwt_result.Syntax in
  List.fold_right l ~init:(Lwt_result.return []) ~f:(fun el acc ->
      let* acc = acc in
      match expr el with
      | None ->
        Lwt_result.return (f el :: acc)
      | Some expr ->
        let+ result =
          evaluate_expr_with expr ~f:Template_expr.to_bool ~context
        in
        if result then
          f el :: acc
        else
          acc)

let populate_context ?(use_defaults = false) ~context (dec : Dec_template.t) =
  let open Lwt_result.Syntax in
  List.fold_left
    dec.configurations
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
            try Lwt_result.return result with
            | Failed_rule_eval e ->
              Lwt.return (Error e)
          in
          (match data_opt with
          | Some data ->
            let _ = Hashtbl.add context ~key:config.name ~data in
            ()
          | None ->
            ()))

let ignore_files files ~context ~(dec : Dec_template.t) =
  let open Lwt_result.Syntax in
  let+ ignores =
    fold_with_enabled_if
      dec.ignore_file_rules
      ~context
      ~expr:(fun el -> el.Ignore_rule.enabled_if)
      ~f:(fun x -> x)
  in
  let ignores =
    List.map ignores ~f:(fun ignore -> ignore.files) |> List.concat
  in
  files
  |> Hashtbl.to_alist
  |> List.filter_map ~f:(fun (path, content) ->
         if
           List.exists ignores ~f:(fun glob ->
               let normalized_path =
                 String.substr_replace_all path ~pattern:"\\" ~with_:"/"
               in
               Glob.matches_glob normalized_path ~glob)
         then
           None
         else
           Some (path, content))
  |> Hashtbl.of_alist_exn (module String)

let populate_template_files files =
  files
  |> Hashtbl.to_alist
  |> List.filter_map ~f:(fun (path, content) ->
         let fpath = Fpath.v path in
         let root = Fpath.v "template" in
         match Fpath.rem_prefix root fpath with
         | Some fpath ->
           let path = Fpath.to_string fpath in
           Some (path, content)
         | None ->
           None)
  |> Hashtbl.of_alist_exn (module String)

let populate_pre_gen_actions ~context (dec : Dec_template.t) =
  fold_with_enabled_if
    dec.pre_gen_actions
    ~context
    ~expr:(fun el -> el.Actions.enabled_if)
    ~f:Template_actions.of_dec

let populate_post_gen_actions ~context (dec : Dec_template.t) =
  fold_with_enabled_if
    dec.post_gen_actions
    ~context
    ~expr:(fun el -> el.Actions.enabled_if)
    ~f:Template_actions.of_dec

let populate_example_commands ~context (dec : Dec_template.t) =
  fold_with_enabled_if
    dec.example_commands
    ~context
    ~expr:(fun el -> el.Example_command.enabled_if)
    ~f:(fun el -> { name = el.name; description = el.description })

let source_of_dec = function
  | Dec_common.Source.Git s ->
    Ok (Git s)
  | Dec_common.Source.Local_dir s ->
    Ok (Local_dir s)
  | Dec_common.Source.Official s ->
    (match Official_template.of_name s with
    | Some (module T) ->
      Ok (Official (module T))
    | None ->
      Error (Printf.sprintf "The official template does not exist: %s" s))

let source_of_string s =
  match Official_template.of_name s with
  | Some v ->
    Some (Official v)
  | None ->
    (match Dec_common.Git_repo.decode (Sexp.Atom s) with
    | Ok s ->
      Some (Git s)
    | Error _ ->
      if Caml.Sys.is_directory s then
        Some (Local_dir s)
      else
        None)

let rec of_dec
    ?(use_defaults = false)
    ?(files = Hashtbl.create (module String))
    ?(ignore_configs = false)
    ?(ignore_actions = false)
    ?(ignore_example_commands = false)
    ~context
    (dec : Dec_template.t)
  =
  let open Lwt_result.Syntax in
  let* base =
    match dec.base_template with
    | Some base ->
      let* source =
        source_of_dec base.source
        |> Result.map_error ~f:(fun reason ->
               Spin_error.invalid_template ~msg:reason dec.name)
        |> Lwt.return
      in
      read
        source
        ~use_defaults
        ~context
        ~ignore_configs:base.ignore_configs
        ~ignore_actions:base.ignore_actions
        ~ignore_example_commands:base.ignore_example_commands
    | None ->
      Lwt_result.return
        { name = ""
        ; description = ""
        ; context
        ; template_files = Hashtbl.create (module String)
        ; pre_gen_actions = []
        ; post_gen_actions = []
        ; example_commands = []
        }
  in
  let* () =
    if ignore_configs then
      Lwt_result.return ()
    else
      populate_context ~use_defaults ~context dec
  in
  let* pre_gen_actions =
    if ignore_actions then
      Lwt_result.return []
    else
      populate_pre_gen_actions ~context dec
  in
  let* post_gen_actions =
    if ignore_actions then
      Lwt_result.return []
    else
      populate_post_gen_actions ~context dec
  in
  let* example_commands =
    if ignore_example_commands then
      Lwt_result.return []
    else
      populate_example_commands ~context dec
  in
  let template_files = populate_template_files files in
  Hashtbl.merge_into
    ~src:base.template_files
    ~dst:template_files
    ~f:(fun ~key:_ src ->
    function Some dst -> Set_to dst | None -> Set_to src);
  let+ template_files = ignore_files template_files ~dec ~context in
  { name = dec.name
  ; description = dec.description
  ; context
  ; template_files
  ; pre_gen_actions = base.pre_gen_actions @ pre_gen_actions
  ; post_gen_actions = base.post_gen_actions @ post_gen_actions
  ; example_commands = base.example_commands @ example_commands
  }

and read
    ?(use_defaults = false)
    ?(ignore_configs = false)
    ?(ignore_actions = false)
    ?(ignore_example_commands = false)
    ?context
    source
  =
  let open Lwt_result.Syntax in
  let context =
    Option.value context ~default:(Hashtbl.create (module String))
  in
  match source with
  | Official (module T) ->
    let* spin_file =
      Official_template.read_spin_file (module T) |> Lwt.return
    in
    let files =
      Official_template.files_with_content (module T)
      |> Hashtbl.of_alist_exn (module String)
    in
    of_dec
      spin_file
      ~ignore_configs
      ~ignore_actions
      ~ignore_example_commands
      ~files
      ~context
      ~use_defaults
  | Local_dir dir ->
    let* spin_file = Local_template.read_spin_file dir in
    let* files = Local_template.files_with_content dir |> Lwt_result.ok in
    of_dec
      spin_file
      ~ignore_configs
      ~ignore_actions
      ~ignore_example_commands
      ~files:(Hashtbl.of_alist_exn (module String) files)
      ~context
      ~use_defaults
  | Git repo ->
    let* template_dir = Git_template.donwload_git_repo repo in
    let* spin_file = Local_template.read_spin_file template_dir in
    let* files =
      Local_template.files_with_content template_dir |> Lwt_result.ok
    in
    of_dec
      spin_file
      ~ignore_configs
      ~ignore_actions
      ~ignore_example_commands
      ~files:(Hashtbl.of_alist_exn (module String) files)
      ~context
      ~use_defaults

let generate ~path:generation_root template =
  let open Lwt_result.Syntax in
  let* () =
    (try
       match Caml.Sys.readdir generation_root with
       | [||] ->
         Ok ()
       | _ ->
         Error
           (Spin_error.failed_to_generate "The output directory is not empty.")
     with
    | Sys_error _ ->
      Spin_unix.mkdir_p generation_root;
      Ok ())
    |> Lwt.return
  in
  (* Run pre-gen commands *)
  let* () =
    Spin_lwt.result_fold_left
      template.pre_gen_actions
      ~f:(Template_actions.run ~path:generation_root)
  in
  (* Generate files *)
  let* () =
    Logs_lwt.app (fun m ->
        m
          "\n🏗️  Creating a new project from %a in %s"
          Pp.pp_blue
          template.name
          generation_root)
    |> Lwt_result.ok
  in
  let* () =
    template.template_files
    |> Hashtbl.to_alist
    |> Spin_lwt.fold_left ~f:(fun (path, content) ->
           let path = Filename.concat generation_root path in
           File_generator.generate path ~context:template.context ~content)
    |> Lwt_result.ok
  in
  let* () =
    Logs_lwt.app (fun m -> m "%a" Pp.pp_bright_green "Done!\n") |> Lwt_result.ok
  in
  (* Run post-gen commands *)
  let* () =
    Spin_lwt.result_fold_left
      template.post_gen_actions
      ~f:(Template_actions.run ~path:generation_root)
  in
  let* () =
    Logs_lwt.app (fun m ->
        m "🎉  Success! Your project is ready at %s" generation_root)
    |> Lwt_result.ok
  in
  (* Print example commands *)
  let open Lwt.Syntax in
  let* () =
    match template.example_commands with
    | [] ->
      Lwt.return ()
    | _ ->
      Logs_lwt.app (fun m ->
          m
            "\n\
             Here are some example commands that you can run inside this \
             directory:")
  in
  let* () =
    Spin_lwt.fold_left
      template.example_commands
      ~f:(fun (el : example_command) ->
        let* () = Logs_lwt.app (fun m -> m "") in
        let* () = Logs_lwt.app (fun m -> m "  %a" Pp.pp_blue el.name) in
        Logs_lwt.app (fun m -> m "    %s" el.description))
  in
  let* () = Logs_lwt.app (fun m -> m "\nHappy hacking!") in
  Lwt_result.return ()
