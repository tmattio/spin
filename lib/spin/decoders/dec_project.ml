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
    | Sexplib.Sexp.List
        [ Sexplib.Sexp.Atom config_name; Sexplib.Sexp.Atom config_value ] ->
      Ok (config_name, config_value)
    | _ ->
      Error (Decoder.Decoder_error (Errors.unexpected_format, Some sexp))

  let encode (config_name, config_value) =
    Sexplib.Sexp.List
      [ Sexplib.Sexp.Atom config_name; Sexplib.Sexp.Atom config_value ]
end

let decode =
  let open Decoder.Syntax in
  let+ source = Decoder.field "source" Source.decode
  and+ configs = Decoder.fields "config" Config.decode in
  { source; configs }

let encode t =
  Sexplib.Sexp.List
    ([ Sexplib.Sexp.List [ Sexplib.Sexp.Atom "source"; Source.encode t.source ]
     ]
    @ List.map
        (fun (config_name, config_value) ->
          Sexplib.Sexp.List
            [ Sexplib.Sexp.Atom "config"
            ; Sexplib.Sexp.Atom config_name
            ; Sexplib.Sexp.Atom config_value
            ])
        t.configs)
