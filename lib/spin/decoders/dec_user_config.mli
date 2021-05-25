type t =
  { author_name : string option
  ; email : string option
  ; github_username : string option
  ; create_switch : bool option
  }

val decode : t Decoder.t

val encode : t Encoder.t
