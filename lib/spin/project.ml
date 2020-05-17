type t =
  { dec : Dec_project.t
  ; project_root : string
  }

let project_root () =
  let rec aux dir =
    if Caml.Sys.file_exists (Filename.concat dir ".spin") then
      Some dir
    else
      let dirname = Filename.dirname dir in
      if String.equal dirname dir then
        None
      else
        aux dirname
  in
  let cwd = Caml.Sys.getcwd () in
  aux cwd

let read_project_config () =
  match project_root () with
  | None ->
    Ok None
  | Some project_root ->
    let open Result.Let_syntax in
    let project_conf_path = Filename.concat project_root ".spin" in
    let+ dec =
      Decoder.decode_sexps_file project_conf_path ~f:Dec_project.decode
      |> Result.map_error
           ~f:(Spin_error.of_decoder_error ~file:project_conf_path)
    in
    Some { dec; project_root }

let project_generators t =
  let open Lwt_result.Syntax in
  let* template_source =
    Template.source_of_dec t.Dec_project.source
    |> Result.map_error ~f:(fun reason ->
           (* TODO: The error message could be more helpful with the name of the
              template. *)
           Spin_error.generator_error ~msg:reason "")
    |> Lwt.return
  in
  let+ dec =
    Template.read_source_spin_file template_source ~download_git:false
  in
  List.map dec.Dec_template.generators ~f:(fun generator ->
      let open Dec_template.Generator in
      generator.name, generator.description)

let run_generator ?context:additionnal_context ~project:t generator =
  let open Lwt_result.Syntax in
  let context = Hashtbl.of_alist_exn (module String) t.dec.configs in
  let () =
    match additionnal_context with
    | Some additionnal_context ->
      Hashtbl.merge_into
        ~src:additionnal_context
        ~dst:context
        ~f:(fun ~key:_ src ->
        function Some dst -> Set_to dst | None -> Set_to src)
    | None ->
      ()
  in
  let* template_source =
    Template.source_of_dec t.dec.source
    |> Result.map_error ~f:(fun reason ->
           Spin_error.generator_error ~msg:reason generator)
    |> Lwt.return
  in
  let* dec =
    Template.read
      template_source
      ~context
      ~ignore_configs:true
      ~ignore_actions:true
      ~ignore_example_commands:true
  in
  match Hashtbl.find dec.generators generator with
  | None ->
    Lwt.return
      (Error
         (Spin_error.generator_error
            ~msg:
              (Printf.sprintf
                 "The generator with the name %S does not exist"
                 generator)
            generator))
  | Some gen ->
    let* generator = gen () in
    (* Run pre-gen commands *)
    let* _ =
      Spin_lwt.result_fold_left
        generator.pre_gen_actions
        ~f:(Template_actions.run ~path:t.project_root)
    in
    (* Generate files *)
    let* () =
      Logs_lwt.app (fun m ->
          m "\n🏗️  Running the generator %a" Pp.pp_blue generator.name)
      |> Lwt_result.ok
    in
    let* _ =
      generator.files
      |> Hashtbl.to_alist
      |> Spin_lwt.result_fold_left ~f:(fun (path, content) ->
             let path = Filename.concat t.project_root path in
             File_generator.generate path ~context:generator.context ~content)
    in
    let* () =
      Logs_lwt.app (fun m -> m "%a" Pp.pp_bright_green "Done!\n")
      |> Lwt_result.ok
    in
    (* Run post-gen commands *)
    let* _ =
      Spin_lwt.result_fold_left
        generator.post_gen_actions
        ~f:(Template_actions.run ~path:t.project_root)
    in
    (* Print message *)
    let+ () =
      match generator.message with
      | None ->
        Lwt.return () |> Lwt_result.ok
      | Some message ->
        Logs_lwt.app (fun m -> m "%a" Pp.pp_yellow message) |> Lwt_result.ok
    in
    ()
