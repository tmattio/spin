type t = [ `Missing_env_var of string ]

val to_string : t -> string

val missing_env : string -> t
