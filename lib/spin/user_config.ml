type t =
  { author_name : string option
  ; email : string option
  ; github_username : string option
  ; create_switch : bool option
  }

let of_dec (dec : Dec_user_config.t) =
  { author_name = dec.author_name
  ; email = dec.email
  ; github_username = dec.github_username
  ; create_switch = dec.create_switch
  }

let path_of_opt value =
  value
  |> Option.map Result.ok
  |> Option.value
       ~default:
         (Config.spin_config_dir
         |> Result.map (fun p -> Filename.concat p "default"))

let read ?path () =
  let decode_if_exists path =
    if Sys.file_exists path then
      Decoder.decode_sexps_file path Dec_user_config.decode
      |> Result.map of_dec
      |> Result.map Option.some
      |> Result.map_error (Spin_error.of_decoder_error ~file:path)
    else
      Ok None
  in
  Result.bind (path_of_opt path) decode_if_exists

let save ?path (t : t) =
  let open Result.Syntax in
  let+ path = path_of_opt path in
  let () = Sys.mkdir_p (Filename.dirname path) in
  Encoder.encode_file
    path
    Dec_user_config.
      { author_name = t.author_name
      ; email = t.email
      ; github_username = t.github_username
      ; create_switch = t.create_switch
      }
    Dec_user_config.encode

let validate_strip s =
  match String.trim s with "" -> Error "Enter a value." | s -> Ok s

let prompt ?default:d () =
  let author_name =
    Inquire.input
      "Your name"
      ?default:(Option.bind d (fun d -> d.author_name))
      ~validate:validate_strip
  in
  let email =
    Inquire.input
      "Your email"
      ?default:(Option.bind d (fun d -> d.email))
      ~validate:validate_strip
  in
  let github_username =
    Inquire.input
      "Your GitHub username"
      ?default:(Option.bind d (fun d -> d.github_username))
      ~validate:validate_strip
  in
  let create_switch =
    Inquire.confirm
      "Create switches when generating projects"
      ?default:(Option.bind d (fun d -> d.create_switch))
  in
  { author_name = Some author_name
  ; email = Some email
  ; github_username = Some github_username
  ; create_switch = Some create_switch
  }

let to_context t =
  let context = Hashtbl.create 256 in
  Option.iter
    (fun v -> Hashtbl.add context "author_name" v |> ignore)
    t.author_name;
  Option.iter (fun v -> Hashtbl.add context "email" v |> ignore) t.email;
  Option.iter
    (fun v -> Hashtbl.add context "github_username" v |> ignore)
    t.github_username;
  context
