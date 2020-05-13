let read_file path =
  Lwt_io.with_file ~mode:Input path (fun ic -> Lwt_io.read ic)

let read_spin_file path =
  let open Lwt_result.Syntax in
  let spin_file_path = Filename.concat path "spin" in
  let* file_exists = Lwt_result.ok @@ Lwt_unix.file_exists spin_file_path in
  let* content =
    if file_exists then
      Lwt_result.ok @@ read_file spin_file_path
    else
      Lwt.return
        (Error
           (Spin_error.invalid_template
              path
              ~msg:"The directory does not contain a \"spin\" file."))
  in
  match Decoder.decode_sexps_string content ~f:Dec_template.decode with
  | Ok spin_file ->
    Lwt.return (Ok spin_file)
  | Error e ->
    let msg = Decoder.string_of_error e in
    Error (Spin_error.failed_to_parse "spin" ~msg) |> Lwt.return

let files_with_content root_path =
  let open Lwt.Syntax in
  let dir_files = Spin_sys.ls_dir root_path in
  let root_path = Fpath.v root_path in
  List.fold_left dir_files ~init:(Lwt.return []) ~f:(fun acc path ->
      let* acc = acc in
      let+ content = read_file path in
      let fpath = Fpath.v path in
      let fpath = Fpath.rem_prefix root_path fpath in
      let path = Fpath.to_string (Option.value_exn fpath) in
      (path, content) :: acc)
