type t = Dec_project.t

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
    None
  | Some root ->
    let project_conf_path = Filename.concat root ".spin" in
    Some
      (Decoder.decode_sexps_file project_conf_path ~f:Dec_project.decode
      |> Result.map_error
           ~f:(Spin_error.of_decoder_error ~file:project_conf_path))

let project_generators t =
  let open Lwt_result.Syntax in
  let* template_source =
    Template.source_of_dec t.Dec_project.source
    |> Result.map_error ~f:(fun reason ->
           (* TODO: The error message could be more helpful with the name of the
              template. *)
           Spin_error.invalid_template ~msg:reason "")
    |> Lwt.return
  in
  let+ dec =
    Template.read_source_spin_file template_source ~download_git:false
  in
  List.map dec.Dec_template.generators ~f:(fun generator ->
      let open Dec_template.Generator in
      generator.name, generator.description)
