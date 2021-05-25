let read_spin_file path =
  let open Result.Syntax in
  let spin_file_path = Filename.concat path "spin" in
  let* file_exists = Result.ok @@ Sys.file_exists spin_file_path in
  let* content =
    if file_exists then
      Result.ok @@ Sys.read_file spin_file_path
    else
      Error
        (Spin_error.invalid_template
           path
           ~msg:"The directory does not contain a \"spin\" file.")
  in
  match Decoder.decode_sexps_string content Dec_template.decode with
  | Ok spin_file ->
    Ok spin_file
  | Error e ->
    let msg = Decoder.string_of_error e in
    Error (Spin_error.failed_to_parse "spin" ~msg)

let files_with_content root_path =
  let dir_files = Sys.ls_dir root_path in
  let root_path = Fpath.v root_path in
  List.fold_left
    (fun acc path ->
      let content = Sys.read_file path in
      let fpath = Fpath.v path in
      let fpath = Fpath.rem_prefix root_path fpath in
      let path = Fpath.to_string (Option.get fpath) in
      (path, content) :: acc)
    []
    dir_files
