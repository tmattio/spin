open Dec_template

type source =
  | Git of string
  | Local_dir of string
  | Official of (module Template_intf.S)

type example_command =
  { name : string
  ; description : string
  }

type t =
  { name : string
  ; description : string
  ; raw_files : string list
  ; parse_binaries : bool
  ; files : (string, string) Hashtbl.t
  ; context : (string, string) Hashtbl.t
  ; pre_gen_actions : Template_actions.t list
  ; post_gen_actions : Template_actions.t list
  ; example_commands : example_command list
  ; source : source
  }

let ignore_files files ~context ~(dec : Dec_template.t) =
  let open Result.Syntax in
  let+ ignores =
    Template_expr.filter_map
      (fun x -> x)
      dec.ignore_file_rules
      ~context
      ~condition:(fun el -> el.Ignore_rule.enabled_if)
  in
  let ignores =
    List.map (fun (ignore : Ignore_rule.t) -> ignore.files) ignores
    |> List.concat
  in
  files
  |> Hashtbl.to_list
  |> List.filter_map (fun (path, content) ->
         if
           List.exists
             (fun glob ->
               let normalized_path =
                 Str.global_replace (Str.regexp "\\\\") "/" path
               in
               Glob.matches_glob normalized_path ~glob)
             ignores
         then
           None
         else
           Some (path, content))
  |> Hashtbl.of_list

let populate_template_files files =
  files
  |> Hashtbl.to_list
  |> List.filter_map (fun (path, content) ->
         let fpath = Fpath.v path in
         let root = Fpath.v "template" in
         match Fpath.rem_prefix root fpath with
         | Some fpath ->
           let path = Fpath.to_string fpath in
           Some (path, content)
         | None ->
           None)
  |> Hashtbl.of_list

let populate_example_commands ~context (dec : Dec_template.t) =
  Template_expr.filter_map
    (fun el -> { name = el.name; description = el.description })
    dec.example_commands
    ~context
    ~condition:(fun el -> el.Example_command.enabled_if)

let source_of_dec ~templates = function
  | Dec_common.Source.Git s ->
    Ok (Git s)
  | Dec_common.Source.Local_dir s ->
    Ok (Local_dir s)
  | Dec_common.Source.Official s ->
    (match Official_template.of_name s ~templates with
    | Some (module T) ->
      Ok (Official (module T))
    | None ->
      Error (Printf.sprintf "The official template does not exist: %s" s))

let source_to_dec = function
  | Git s ->
    Dec_common.Source.Git s
  | Local_dir s ->
    Dec_common.Source.Local_dir s
  | Official (module T) ->
    Dec_common.Source.Official T.name

let source_of_string ~templates s =
  match Official_template.of_name ~templates s with
  | Some v ->
    Some (Official v)
  | None ->
    (match Dec_common.Git_repo.decode (Sexplib.Sexp.Atom s) with
    | Ok s ->
      Some (Git s)
    | Error _ ->
      if Sys.is_directory s then
        Some (Local_dir s)
      else
        None)

let read_source_spin_file ?(download_git = false) source =
  let open Result.Syntax in
  match source with
  | Official (module T) ->
    Official_template.read_spin_file (module T)
  | Local_dir dir ->
    Local_template.read_spin_file dir
  | Git repo ->
    let* template_dir =
      if download_git then
        Git_template.donwload_git_repo repo
      else
        Git_template.cache_dir_of_repo repo
    in
    Local_template.read_spin_file template_dir

let read_source_template_files ?(download_git = false) source =
  let open Result.Syntax in
  match source with
  | Official (module T) ->
    Ok (Official_template.files_with_content (module T) |> Hashtbl.of_list)
  | Local_dir dir ->
    let files = Local_template.files_with_content dir in
    Ok (Hashtbl.of_list files)
  | Git repo ->
    let+ template_dir =
      if download_git then
        Git_template.donwload_git_repo repo
      else
        Git_template.cache_dir_of_repo repo
    in
    let files = Local_template.files_with_content template_dir in
    Hashtbl.of_list files

let rec of_dec
    ?(use_defaults = false)
    ?(files = Hashtbl.create 256)
    ?ignore_configs
    ?ignore_actions
    ?ignore_example_commands
    ~source
    ~context
    ~depth
    ~templates
    (dec : Dec_template.t)
  =
  let open Result.Syntax in
  let* base =
    match dec.base_template with
    | Some base ->
      let* source =
        source_of_dec base.source ~templates
        |> Result.map_error (fun reason ->
               Spin_error.invalid_template ~msg:reason dec.name)
      in
      let ignore_configs =
        Option.value ignore_configs ~default:base.ignore_configs
      in
      let ignore_actions =
        Option.value ignore_actions ~default:base.ignore_actions
      in
      let ignore_example_commands =
        Option.value
          ignore_example_commands
          ~default:base.ignore_example_commands
      in
      read_template
        source
        ~use_defaults
        ~context
        ~ignore_configs
        ~ignore_actions
        ~ignore_example_commands
        ~depth:(depth + 1)
        ~templates
    | None ->
      Result.ok
        { name = ""
        ; description = ""
        ; raw_files = []
        ; parse_binaries = false
        ; context
        ; files = Hashtbl.create 256
        ; pre_gen_actions = []
        ; post_gen_actions = []
        ; example_commands = []
        ; source
        }
  in
  let compute_ignore v f =
    match depth, v, dec.base_template with
    | 0, _, _ ->
      false
    | _, Some x, _ ->
      x
    | _, None, Some base_template ->
      f base_template
    | _, None, None ->
      false
  in
  let ignore_configs =
    compute_ignore ignore_configs (fun x ->
        x.Dec_template.Base_template.ignore_configs)
  in
  let ignore_actions =
    compute_ignore ignore_actions (fun x ->
        x.Dec_template.Base_template.ignore_actions)
  in
  let ignore_example_commands =
    compute_ignore ignore_example_commands (fun x ->
        x.Dec_template.Base_template.ignore_example_commands)
  in
  let* () =
    if ignore_configs then
      Result.ok ()
    else
      Template_configuration.populate_context
        ~use_defaults
        ~context
        dec.configurations
  in
  let* pre_gen_actions =
    if ignore_actions then
      Result.ok []
    else
      Template_actions.of_decs_with_condition ~context dec.pre_gen_actions
  in
  let* post_gen_actions =
    if ignore_actions then
      Result.ok []
    else
      Template_actions.of_decs_with_condition ~context dec.post_gen_actions
  in
  let* example_commands =
    if ignore_example_commands then
      Result.ok []
    else
      populate_example_commands ~context dec
  in
  let parse_binaries =
    match dec.parse_binaries with Some v -> v | None -> base.parse_binaries
  in
  let raw_files =
    match dec.raw_files with
    | Some v ->
      base.raw_files @ v
    | None ->
      base.raw_files
  in
  let files = populate_template_files files in
  let merged_files = Hashtbl.copy base.files in
  Hashtbl.merge files ~into:merged_files;
  let+ merged_files = ignore_files merged_files ~dec ~context in
  { name = dec.name
  ; description = dec.description
  ; parse_binaries
  ; raw_files
  ; context
  ; files = merged_files
  ; pre_gen_actions = base.pre_gen_actions @ pre_gen_actions
  ; post_gen_actions = base.post_gen_actions @ post_gen_actions
  ; example_commands = base.example_commands @ example_commands
  ; source
  }

and read_template
    ?(use_defaults = false)
    ?ignore_configs
    ?ignore_actions
    ?ignore_example_commands
    ?context
    ~depth
    ~templates
    source
  =
  let open Result.Syntax in
  let context = Option.value context ~default:(Hashtbl.create 256) in
  let* (spin_file : Dec_template.t) =
    read_source_spin_file source ~download_git:true
  in
  let* files = read_source_template_files source ~download_git:false in
  of_dec
    spin_file
    ?ignore_configs
    ?ignore_actions
    ?ignore_example_commands
    ~files
    ~context
    ~source
    ~use_defaults
    ~depth
    ~templates

let read ?(use_defaults = false) ?context ~templates source =
  read_template ~use_defaults ?context ~depth:0 ~templates source

let run_actions ~path actions =
  let open Result.Syntax in
  let+ _ =
    Result.List.fold_left
      (fun acc el ->
        let+ action = Template_actions.run ~path el in
        action :: acc)
      []
      actions
  in
  ()

let generate ~path:generation_root template =
  let open Result.Syntax in
  (* Run pre-gen commands *)
  let* _ = run_actions ~path:generation_root template.pre_gen_actions in
  (* Generate files *)
  Logs.app (fun m ->
      m
        "\n🏗️  Creating a new project from %a in %s"
        Pp.pp_blue
        (String.trim template.name)
        generation_root);
  let normalized_raw_files =
    template.raw_files |> List.map File_generator.normalize_path
  in
  let files_to_copy, files_to_generate =
    List.fold_left
      (fun (files_to_copy, files_to_generate) file ->
        let file_path, file_content = file in
        let normalized_file_path = File_generator.normalize_path file_path in
        let file = normalized_file_path, file_content in
        match
          ( template.parse_binaries
          , File_generator.is_binary_file file_path
          , Glob.matches_globs normalized_file_path ~globs:normalized_raw_files
          )
        with
        | _, _, true ->
          (* No matter if the file is a binary, if it's in raw files, we just
             want to copy it *)
          file :: files_to_copy, files_to_generate
        | false, true, _ ->
          (* If the template config says we don't want to parse binary files and
             the file is a binary *)
          file :: files_to_copy, files_to_generate
        | _, _, _ ->
          files_to_copy, file :: files_to_generate)
      ([], [])
      (Hashtbl.to_list template.files)
  in
  Sys.mkdir_p generation_root;
  let* _ =
    files_to_copy
    |> Result.List.iter_left (fun (path, content) ->
           let path = Filename.concat generation_root path in
           File_generator.copy ~context:template.context ~content path)
  in
  let* _ =
    files_to_generate
    |> Result.List.iter_left (fun (path, content) ->
           let path = Filename.concat generation_root path in
           File_generator.generate ~context:template.context ~content path)
  in
  Logs.app (fun m -> m "%a" Pp.pp_bright_green "Done!\n");
  (* Run post-gen commands *)
  let* _ = run_actions ~path:generation_root template.post_gen_actions in
  Logs.app (fun m ->
      m "🎉  Success! Your project is ready at %s" generation_root);
  (* Print example commands *)
  let () =
    match template.example_commands with
    | [] ->
      ()
    | l ->
      Logs.app (fun m ->
          m
            "\n\
             Here are some example commands that you can run inside this \
             directory:");
      List.iter
        (fun (el : example_command) ->
          Logs.app (fun m -> m "");
          Logs.app (fun m -> m "  %a" Pp.pp_blue el.name);
          Logs.app (fun m -> m "    %s" el.description))
        l
  in
  Logs.app (fun m -> m "\nHappy hacking!");
  Result.ok ()
