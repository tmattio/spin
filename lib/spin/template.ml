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
  ; files : (string, string) Hashtbl.t
  ; context : (string, string) Hashtbl.t
  ; pre_gen_actions : Template_actions.t list
  ; post_gen_actions : Template_actions.t list
  ; example_commands : example_command list
  ; source : source
  ; generators :
      ( string
      , unit -> (Template_generator.t, Spin_error.t) Lwt_result.t )
      Hashtbl.t
  }

let ignore_files files ~context ~(dec : Dec_template.t) =
  let open Lwt_result.Syntax in
  let+ ignores =
    Template_expr.filter_map
      dec.ignore_file_rules
      ~context
      ~condition:(fun el -> el.Ignore_rule.enabled_if)
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

let populate_generator_files files ~gen =
  files
  |> Hashtbl.to_alist
  |> List.filter_map ~f:(fun (path, content) ->
         let fpath = Fpath.v path in
         let root = Fpath.(v "generators" / gen) in
         match Fpath.rem_prefix root fpath with
         | Some fpath ->
           let path = Fpath.to_string fpath in
           Some (path, content)
         | None ->
           None)
  |> Hashtbl.of_alist_exn (module String)

let populate_example_commands ~context (dec : Dec_template.t) =
  Template_expr.filter_map
    dec.example_commands
    ~context
    ~condition:(fun el -> el.Example_command.enabled_if)
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

let source_to_dec = function
  | Git s ->
    Dec_common.Source.Git s
  | Local_dir s ->
    Dec_common.Source.Local_dir s
  | Official (module T) ->
    Dec_common.Source.Official T.name

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

let relativize_source ~root = function
  | (Git _ | Official _) as source ->
    source
  | Local_dir path ->
    let fpath = Fpath.v path in
    let reparented =
      if Fpath.is_rel fpath then
        let froot = Fpath.v root in
        if Fpath.is_rel froot then
          let relativized = Fpath.relativize ~root:froot fpath in
          Option.value_exn relativized |> Fpath.to_string
        else
          let cwd = Caml.Sys.getcwd () in
          let rel_root =
            Option.value_exn (Fpath.relativize ~root:(Fpath.v cwd) froot)
          in
          Option.value_exn (Fpath.relativize ~root:rel_root fpath)
          |> Fpath.to_string
      else
        path
    in
    Local_dir reparented

let read_source_spin_file ?(download_git = false) source =
  let open Lwt_result.Syntax in
  match source with
  | Official (module T) ->
    Official_template.read_spin_file (module T) |> Lwt.return
  | Local_dir dir ->
    Local_template.read_spin_file dir
  | Git repo ->
    let* template_dir =
      if download_git then
        Git_template.donwload_git_repo repo
      else
        Git_template.cache_dir_of_repo repo |> Lwt.return
    in
    Local_template.read_spin_file template_dir

let read_source_template_files ?(download_git = false) source =
  let open Lwt_result.Syntax in
  match source with
  | Official (module T) ->
    Ok
      (Official_template.files_with_content (module T)
      |> Hashtbl.of_alist_exn (module String))
    |> Lwt.return
  | Local_dir dir ->
    let+ files = Local_template.files_with_content dir |> Lwt_result.ok in
    Hashtbl.of_alist_exn (module String) files
  | Git repo ->
    let* template_dir =
      if download_git then
        Git_template.donwload_git_repo repo
      else
        Git_template.cache_dir_of_repo repo |> Lwt.return
    in
    let+ files =
      Local_template.files_with_content template_dir |> Lwt_result.ok
    in
    Hashtbl.of_alist_exn (module String) files

let rec of_dec
    ?(use_defaults = false)
    ?(files = Hashtbl.create (module String))
    ?(ignore_configs = false)
    ?(ignore_actions = false)
    ?(ignore_example_commands = false)
    ?(ignore_generators = false)
    ~source
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
        ~ignore_generators:base.ignore_generators
    | None ->
      Lwt_result.return
        { name = ""
        ; description = ""
        ; context
        ; files = Hashtbl.create (module String)
        ; pre_gen_actions = []
        ; post_gen_actions = []
        ; example_commands = []
        ; source
          (* This is not the correct value, but we are not supposed to use this. *)
        ; generators = Hashtbl.create (module String)
        }
  in
  let* () =
    if ignore_configs then
      Lwt_result.return ()
    else
      Template_configuration.populate_context
        ~use_defaults
        ~context
        dec.configurations
  in
  let* pre_gen_actions =
    if ignore_actions then
      Lwt_result.return []
    else
      Template_actions.of_decs_with_condition ~context dec.pre_gen_actions
  in
  let* post_gen_actions =
    if ignore_actions then
      Lwt_result.return []
    else
      Template_actions.of_decs_with_condition ~context dec.post_gen_actions
  in
  let* example_commands =
    if ignore_example_commands then
      Lwt_result.return []
    else
      populate_example_commands ~context dec
  in
  let generators = Hashtbl.create (module String) in
  let _ =
    if ignore_generators then
      ()
    else
      List.iter dec.generators ~f:(fun g ->
          let files = populate_generator_files files ~gen:g.name in
          let _ =
            Hashtbl.add generators ~key:g.name ~data:(fun () ->
                Template_generator.of_dec ~context ~files g)
          in
          ())
  in
  let files = populate_template_files files in
  Hashtbl.merge_into ~src:base.files ~dst:files ~f:(fun ~key:_ src -> function
    | Some dst -> Set_to dst | None -> Set_to src);
  let+ files = ignore_files files ~dec ~context in
  Hashtbl.merge_into ~src:base.generators ~dst:generators ~f:(fun ~key:_ src ->
    function Some dst -> Set_to dst | None -> Set_to src);
  { name = dec.name
  ; description = dec.description
  ; context
  ; files
  ; pre_gen_actions = base.pre_gen_actions @ pre_gen_actions
  ; post_gen_actions = base.post_gen_actions @ post_gen_actions
  ; example_commands = base.example_commands @ example_commands
  ; source
  ; generators
  }

and read
    ?(use_defaults = false)
    ?(ignore_configs = false)
    ?(ignore_actions = false)
    ?(ignore_example_commands = false)
    ?(ignore_generators = false)
    ?context
    source
  =
  let open Lwt_result.Syntax in
  let context =
    Option.value context ~default:(Hashtbl.create (module String))
  in
  let* spin_file = read_source_spin_file source ~download_git:true in
  let* files = read_source_template_files source ~download_git:false in
  of_dec
    spin_file
    ~ignore_configs
    ~ignore_actions
    ~ignore_example_commands
    ~ignore_generators
    ~files
    ~context
    ~source
    ~use_defaults

let generate ~path:generation_root template =
  let open Lwt_result.Syntax in
  (* Run pre-gen commands *)
  let* _ =
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
  let* _ =
    template.files
    |> Hashtbl.to_alist
    |> Spin_lwt.result_fold_left ~f:(fun (path, content) ->
           let path = Filename.concat generation_root path in
           File_generator.generate path ~context:template.context ~content)
  in
  let* () =
    Logs_lwt.app (fun m -> m "%a" Pp.pp_bright_green "Done!\n") |> Lwt_result.ok
  in
  (* Run post-gen commands *)
  let* _ =
    Spin_lwt.result_fold_left
      template.post_gen_actions
      ~f:(Template_actions.run ~path:generation_root)
  in
  let () =
    let project_config =
      Dec_project.
        { source =
            source_to_dec
              (relativize_source ~root:generation_root template.source)
        ; configs = Hashtbl.to_alist template.context
        }
    in
    Encoder.encode_file
      project_config
      ~path:(Filename.concat generation_root ".spin")
      ~f:Dec_project.encode
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
  let* _ =
    Spin_lwt.fold_left
      template.example_commands
      ~f:(fun (el : example_command) ->
        let* () = Logs_lwt.app (fun m -> m "") in
        let* () = Logs_lwt.app (fun m -> m "  %a" Pp.pp_blue el.name) in
        Logs_lwt.app (fun m -> m "    %s" el.description))
  in
  let* () = Logs_lwt.app (fun m -> m "\nHappy hacking!") in
  Lwt_result.return ()
