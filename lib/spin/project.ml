type t =
  { dec : Dec_project.t
  ; project_root : string
  }

let project_root () =
  let rec aux dir =
    if Sys.file_exists (Filename.concat dir ".spin") then
      Some dir
    else
      let dirname = Filename.dirname dir in
      if String.equal dirname dir then
        None
      else
        aux dirname
  in
  let cwd = Sys.getcwd () in
  aux cwd

let read_project_config () =
  match project_root () with
  | None ->
    Ok None
  | Some project_root ->
    let open Result.Syntax in
    let project_conf_path = Filename.concat project_root ".spin" in
    let+ dec =
      Decoder.decode_sexps_file project_conf_path Dec_project.decode
      |> Result.map_error (Spin_error.of_decoder_error ~file:project_conf_path)
    in
    Some { dec; project_root }

let project_generators t =
  let open Result.Syntax in
  let* template_source =
    Template.source_of_dec t.Dec_project.source
    |> Result.map_error (fun reason ->
           (* TODO: The error message could be more helpful with the name of the
              template. *)
           Spin_error.generator_error ~msg:reason "")
  in
  let+ dec =
    Template.read_source_spin_file template_source ~download_git:false
  in
  List.map
    (fun generator ->
      let open Dec_template.Generator in
      generator.name, generator.description)
    dec.Dec_template.generators

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

let run_generator ?context:additionnal_context ~project:t generator
    : (unit, Spin_error.t) result
  =
  let open Result.Syntax in
  let context = Hashtbl.of_list t.dec.configs in
  let () =
    match additionnal_context with
    | Some additionnal_context ->
      Hashtbl.merge additionnal_context ~into:context
    | None ->
      ()
  in
  let* template_source =
    Template.source_of_dec t.dec.source
    |> Result.map_error (fun reason ->
           Spin_error.generator_error ~msg:reason generator)
  in
  let* dec =
    Template.read
      template_source
      ~context
      ~ignore_configs:true
      ~ignore_actions:true
      ~ignore_example_commands:true
  in
  match Hashtbl.find_opt dec.generators generator with
  | None ->
    Error
      (Spin_error.generator_error
         ~msg:
           (Printf.sprintf
              "The generator with the name %S does not exist"
              generator)
         generator)
  | Some gen ->
    let* generator = gen () in
    (* Run pre-gen commands *)
    let* _ = run_actions ~path:t.project_root generator.pre_gen_actions in
    (* Generate files *)
    Logs.app (fun m ->
        m "\n🏗️  Running the generator %a" Pp.pp_blue generator.name);
    let* _ =
      generator.files
      |> Hashtbl.to_list
      |> Result.List.iter_left (fun (path, content) ->
             let path = Filename.concat t.project_root path in
             (* let dirname = Filename.dirname path in *)
             (* Sys.mkdir_p dirname; *)
             File_generator.generate path ~context:generator.context ~content)
    in
    Logs.app (fun m -> m "%a" Pp.pp_bright_green "Done!\n");
    (* Run post-gen commands *)
    let+ _ = run_actions ~path:t.project_root generator.post_gen_actions in
    (* Print message *)
    Option.iter
      (fun msg -> Logs.app (fun m -> m "%a" Pp.pp_yellow msg))
      generator.message
