let all = Spin_template.all

type doc =
  { name : string
  ; description : string
  }

let read_spin_file (module T : Spin_template.Template) =
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

let all_doc () =
  let rec aux acc = function
    | [] ->
      Ok acc
    | (module T : Spin_template.Template) :: rest ->
      (match read_spin_file (module T) with
      | Ok spin_file ->
        aux ({ name = T.name; description = spin_file.description } :: acc) rest
      | Error error ->
        Error error)
  in
  aux [] all

let files_with_content (module T : Spin_template.Template) =
  List.map
    (fun path ->
      let content = Option.get (T.read path) in
      path, content)
    T.file_list

let of_name s =
  List.find_opt
    (fun (module T : Spin_template.Template) -> String.equal s T.name)
    all
