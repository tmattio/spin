open Dec_common

type t =
  { source : Source.t
  ; configs : (string * string) list
  }

module Config = struct
  module Errors = struct
    let unexpected_format =
      "Expected an s-expression of the for (<config-name> <config-value>)"
  end

  let decode sexp =
    match sexp with
    | Sexp.List [ Sexp.Atom config_name; Sexp.Atom config_value ] ->
      Ok (config_name, config_value)
    | _ ->
      Error (Decoder.Decoder_error (Errors.unexpected_format, Some sexp))

  let encode (config_name, config_value) =
    Sexp.List [ Sexp.Atom config_name; Sexp.Atom config_value ]
end

let decode =
  let open Decoder.Let_syntax in
  let+ source = Decoder.field "source" ~f:Source.decode
  and+ configs = Decoder.fields "config" ~f:Config.decode in
  { source; configs }

let encode t =
  Sexp.List
    ([ Sexp.List [ Sexp.Atom "source"; Source.encode t.source ] ]
    @ List.map t.configs ~f:(fun (config_name, config_value) ->
          Sexp.List
            [ Sexp.Atom "config"
            ; Sexp.Atom config_name
            ; Sexp.Atom config_value
            ]))
