type t =
  { username : string option
  ; email : string option
  ; github_username : string option
  ; npm_username : string option
  }

val of_dec : Dec_user_config.t -> t

val read : ?path:string -> unit -> (t option, Spin_error.t) Result.t

val save : ?path:string -> t -> (unit, Spin_error.t) Result.t

val prompt : ?default:t -> unit -> t Lwt.t

val to_context : t -> (string, string) Hashtbl.t
