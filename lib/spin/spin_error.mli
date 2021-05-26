type t =
  [ `Missing_env_var of string
  | `Failed_to_parse of string * string
  | `Invalid_template of string * string
  | `Failed_to_generate of string
  ]

val to_string : t -> string

val missing_env : string -> t

val failed_to_parse : msg:string -> string -> t

val failed_to_generate : string -> t

val invalid_template : msg:string -> string -> t

val of_decoder_error : file:string -> Decoder.error -> t

val pp : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]
