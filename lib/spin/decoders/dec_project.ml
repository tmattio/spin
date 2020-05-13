open Dec_common

type t =
  { source : Source.t
  ; configs : string list
  }

let decode =
  let open Decoder.Let_syntax in
  let+ source = Decoder.field "source" ~f:Source.decode in
  { source; configs = [] }
