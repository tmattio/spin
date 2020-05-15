type t =
  { username : string option
  ; email : string option
  ; github_username : string option
  ; npm_username : string option
  }

let of_dec (dec : Dec_user_config.t) =
  { username = dec.username
  ; email = dec.email
  ; github_username = dec.github_username
  ; npm_username = dec.npm_username
  }

let path_of_opt value =
  value
  |> Option.map ~f:Result.return
  |> Option.value
       ~default:
         (Config.spin_config_dir
         |> Result.map ~f:(fun p -> Filename.concat p "default"))

let read ?path () =
  let decode_if_exists path =
    if Caml.Sys.file_exists path then
      Decoder.decode_sexps_file path ~f:Dec_user_config.decode
      |> Result.map ~f:of_dec
      |> Result.map ~f:Option.return
      |> Result.map_error ~f:(Spin_error.of_decoder_error ~file:path)
    else
      Ok None
  in
  path_of_opt path |> Result.bind ~f:decode_if_exists

let save ?path t =
  let open Result.Let_syntax in
  let+ path = path_of_opt path in
  let () = Spin_unix.mkdir_p (Filename.dirname path) in
  Encoder.encode_file
    { username = t.username
    ; email = t.email
    ; github_username = t.github_username
    ; npm_username = t.npm_username
    }
    ~path
    ~f:Dec_user_config.encode

let validate_strip s =
  match String.strip s with
  | "" ->
    Lwt.return (Error "Enter a value.")
  | s ->
    Lwt.return (Ok s)

let prompt ?default:d () =
  let open Lwt.Syntax in
  let* username =
    Inquire.input
      "Your name"
      ?default:(Option.bind d ~f:(fun d -> d.username))
      ~validate:validate_strip
  in
  let* email =
    Inquire.input
      "Your email"
      ?default:(Option.bind d ~f:(fun d -> d.email))
      ~validate:validate_strip
  in
  let* github_username =
    Inquire.input
      "Your Github username"
      ?default:(Option.bind d ~f:(fun d -> d.github_username))
      ~validate:validate_strip
  in
  let+ npm_username =
    Inquire.input
      "Your NPM username"
      ?default:(Option.bind d ~f:(fun d -> d.npm_username))
      ~validate:validate_strip
  in
  { username = Some username
  ; email = Some email
  ; github_username = Some github_username
  ; npm_username = Some npm_username
  }

let to_context t =
  let context = Hashtbl.create (module String) in
  Option.iter t.username ~f:(fun v ->
      Hashtbl.add context ~key:"username" ~data:v |> ignore);
  Option.iter t.email ~f:(fun v ->
      Hashtbl.add context ~key:"email" ~data:v |> ignore);
  Option.iter t.github_username ~f:(fun v ->
      Hashtbl.add context ~key:"github_username" ~data:v |> ignore);
  Option.iter t.npm_username ~f:(fun v ->
      Hashtbl.add context ~key:"npm_username" ~data:v |> ignore);
  context
