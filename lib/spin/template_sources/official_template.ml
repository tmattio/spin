type doc =
  { name : string
  ; description : string
  }

let read_spin_file (module T : Template_intf.S) =
  match T.read "spin" with
  | Some content ->
    (match Decoder.decode_sexps_string content Dec_template.decode with
    | Ok spin_file ->
      Ok spin_file
    | Error e ->
      let msg = Decoder.string_of_error e in
      Error (Spin_error.failed_to_parse "spin" ~msg))
  | None ->
    Error (Spin_error.invalid_template T.name ~msg:"Missing \"spin\" file.")

let all_doc templates =
  let rec aux acc = function
    | [] ->
      Ok acc
    | (module T : Template_intf.S) :: rest ->
      (match read_spin_file (module T) with
      | Ok spin_file ->
        aux ({ name = T.name; description = spin_file.description } :: acc) rest
      | Error error ->
        Error error)
  in
  aux [] templates

let files_with_content (module T : Template_intf.S) =
  List.map
    (fun path ->
      let content = Option.get (T.read path) in
      path, content)
    T.file_list

let of_name ~templates s =
  List.find_opt
    (fun (module T : Template_intf.S) -> String.equal s T.name)
    templates
