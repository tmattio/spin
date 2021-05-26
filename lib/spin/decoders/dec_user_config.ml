type t =
  { author_name : string option
  ; email : string option
  ; github_username : string option
  ; create_switch : bool option
  }

let decode =
  let open Decoder.Syntax in
  let+ author_name = Decoder.field_opt "author_name" Decoder.string
  and+ email = Decoder.field_opt "email" Decoder.string
  and+ github_username = Decoder.field_opt "github_username" Decoder.string
  and+ create_switch = Decoder.field_opt "create_switch" Decoder.bool in
  { author_name; email; github_username; create_switch }

let encode t =
  let nullable_string = Encoder.nullable Encoder.string in
  let nullable_bool = Encoder.nullable Encoder.bool in
  Encoder.obj
    [ "author_name", nullable_string t.author_name
    ; "email", nullable_string t.email
    ; "github_username", nullable_string t.github_username
    ; "create_switch", nullable_bool t.create_switch
    ]
