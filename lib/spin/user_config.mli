type t =
  { author_name : string option
  ; email : string option
  ; github_username : string option
  ; create_switch : bool option
  }

val of_dec : Dec_user_config.t -> t

val read : ?path:string -> unit -> (t option, Spin_error.t) Result.t

val save : ?path:string -> t -> (unit, Spin_error.t) Result.t

val prompt : ?default:t -> unit -> t

val to_context : t -> (string, string) Hashtbl.t
