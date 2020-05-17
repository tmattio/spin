type t =
  [ `Missing_env_var of string
  | `Failed_to_parse of string * string
  | `Invalid_template of string * string
  | `Failed_to_generate of string
  | `Generator_error of string * string
  ]

val to_string : t -> string

val missing_env : string -> t

val failed_to_parse : msg:string -> string -> t

val failed_to_generate : string -> t

val invalid_template : msg:string -> string -> t

val generator_error : msg:string -> string -> t

val of_decoder_error : file:string -> Decoder.error -> t
