type t =
  { username : string option
  ; email : string option
  ; github_username : string option
  ; npm_username : string option
  }

let decode =
  let open Decoder.Let_syntax in
  let+ username = Decoder.field_opt "username" ~f:Decoder.string
  and+ email = Decoder.field_opt "email" ~f:Decoder.string
  and+ github_username = Decoder.field_opt "github_username" ~f:Decoder.string
  and+ npm_username = Decoder.field_opt "npm_username" ~f:Decoder.string in
  { username; email; github_username; npm_username }

let encode t =
  let nullable_string = Encoder.nullable Encoder.string in
  Encoder.obj
    [ "username", nullable_string t.username
    ; "email", nullable_string t.email
    ; "github_username", nullable_string t.github_username
    ; "npm_username", nullable_string t.github_username
    ]
